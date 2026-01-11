import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:convert';
import 'package:memory_vault/config.dart';

class MemoryService {
  final supabase = Supabase.instance.client;

  // Singleton pattern
  static final MemoryService _instance = MemoryService._internal();
  factory MemoryService() => _instance;
  MemoryService._internal() {
    // Print available models on init to debug "Not Found" errors
    _diagnoseApiKey();
  }

  Future<void> _diagnoseApiKey() async {
    String apiKey = Config.googleApiKey;
    if (apiKey.contains('PASTE_YOUR'))
      apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (apiKey.isEmpty ||
        apiKey.contains('YOUR_') ||
        apiKey.contains('PASTE_YOUR')) {
      debugPrint("❌ DIAGNOSTIC: No API Key found.");
      return;
    }

    debugPrint("🔍 DIAGNOSTIC: Testing API Key permissions...");
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
        ),
      );
      final response = await request.close();

      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        debugPrint("✅ DIAGNOSTIC: API Key is VALID. Models available.");
        debugPrint("📋 MODEL LIST: $responseBody");
      } else {
        debugPrint("❌ DIAGNOSTIC: API Error ${response.statusCode}");
        debugPrint("❌ RESPONSE: $responseBody");
        // This log puts the EXACT Google error in the console for the user to see
      }
    } catch (e) {
      debugPrint("❌ DIAGNOSTIC: Network Error: $e");
    }
  }

  /// Generates an embedding for the given text using Gemini API
  Future<List<double>> _generateEmbedding(String text) async {
    // Priority: Config -> .env
    String apiKey = Config.googleApiKey;
    if (apiKey.contains('PASTE_YOUR')) {
      apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    }

    if (apiKey.isEmpty ||
        apiKey.contains('YOUR_') ||
        apiKey.contains('PASTE_YOUR')) {
      throw Exception("API Key missing in .env and Config!");
    }

    try {
      // Use 'text-embedding-004' to avoid "Quota exceeded" on the older model
      final model = GenerativeModel(
        model: 'text-embedding-004',
        apiKey: apiKey,
      );
      final content = Content.text(text);
      final result = await model.embedContent(content);

      final embedding = result.embedding.values;
      return embedding;
    } catch (e) {
      debugPrint('Embedding Error: $e');
      throw Exception('Failed to generate embedding: $e');
    }
  }

  /// Saves a new memory to Supabase with its vector embedding
  Future<void> saveMemory(String content) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // 1. Generate Embedding
    final embedding = await _generateEmbedding(content);

    // 2. Save to Supabase
    await supabase.from('memories').insert({
      'user_id': user.id,
      'content': content,
      'embedding': embedding,
    });
  }

  /// Search for similar memories using Supabase RPC (Vector Search)
  Future<List<String>> _searchMemories(String query) async {
    final embedding = await _generateEmbedding(query);

    // Call the 'match_memories' Postgres function
    final List<dynamic> response = await supabase.rpc(
      'match_memories',
      params: {
        'query_embedding': embedding,
        'match_threshold': 0.60, // Lowered slightly to ensure matches
        'match_count': 5,
      },
    );

    return response.map((e) => e['content'] as String).toList();
  }

  /// Ask a question to the user's Memory Vault
  Stream<String> askQuestion(String question) async* {
    // Priority: Config -> .env
    String apiKey = Config.googleApiKey;
    if (apiKey.contains('PASTE_YOUR')) {
      apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
    }

    if (apiKey.isEmpty ||
        apiKey.contains('YOUR_') ||
        apiKey.contains('PASTE_YOUR')) {
      yield "Error: No Valid API Key found (Checked .env and Config).";
      return;
    }

    // 1. Retrieve Context
    yield "Searching memories...";
    final contextMemories = await _searchMemories(question);

    if (contextMemories.isEmpty) {
      yield "I couldn't find any relevant memories to answer that.";
      return;
    }

    // 2. Construct Prompt
    yield "Thinking...";
    final contextString = contextMemories.join("\n- ");
    final prompt = """
You are a personal memory assistant. Answer the user's question based ONLY on the following context memories. 
If the answer is not in the context, say "I don't have a memory of that."

Context Memories:
- $contextString

User Question: $question
""";

    // 3. Call Gemini for Answer
    try {
      // Attempt 1: "gemini-flash-latest" (Safe alias for the current stable Flash)
      final model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: apiKey,
      );
      final content = [Content.text(prompt)];
      final response = model.generateContentStream(content);

      await for (final chunk in response) {
        if (chunk.text != null) yield chunk.text!;
      }
    } catch (e) {
      // Attempt 2: "gemini-2.0-flash-exp" (Experimental often has free quota)
      debugPrint("Flash Latest failed, switching to Exp: $e");
      try {
        final model = GenerativeModel(
          model: 'gemini-2.0-flash-exp',
          apiKey: apiKey,
        );
        final content = [Content.text(prompt)];
        final response = model.generateContentStream(content);

        await for (final chunk in response) {
          if (chunk.text != null) yield chunk.text!;
        }
      } catch (e2) {
        yield "Error: AI Service Unavailable. ($e2)";
        debugPrint("Exp failed too: $e2");
      }
    }
  }

  /// Initial Fetch of recent memories (no vector search yet, just list)
  Stream<List<Map<String, dynamic>>> getMyMemories() {
    final user = supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return supabase
        .from('memories')
        .stream(primaryKey: ['id'])
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
  }
}
