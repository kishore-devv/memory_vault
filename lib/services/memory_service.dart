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
  MemoryService._internal();

  String? _cachedModelName;

  /// Dynamically fetch the first available Gemini model from the API
  Future<String> _fetchWorkingModel(String apiKey) async {
    if (_cachedModelName != null) return _cachedModelName!;

    debugPrint("🔍 Finding available Gemini models...");
    try {
      final client = HttpClient();
      final request = await client.getUrl(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey',
        ),
      );
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody);
        final models = json['models'] as List;

        // Find first model that supports generateContent
        for (var m in models) {
          final name = m['name'].toString(); // e.g. "models/gemini-1.5-flash"
          final supportedMethods = m['supportedGenerationMethods'] as List;

          if (name.contains('gemini') &&
              supportedMethods.contains('generateContent')) {
            // Strip "models/" prefix if present, although SDK might handle it.
            // But let's be safe and try to respect what SDK usually expects.
            // Actually SDK usually takes "gemini-1.5-flash".
            // But if we pass "models/gemini-1.5-flash", it might work too.
            // Safest: Use the exact name returned by API but strip "models/" if SDK behaves oddly.
            // Let's rely on the fact that standard named constructors use short names,
            // but generic constructor takes model name.

            // If name is "models/gemini-...", let's keep it as is,
            // because our previous hardcoded "gemini-..." failed.
            // Maybe it failed because it expects "models/"?
            // Or maybe it failed because "1.5-flash" wasn't there.

            debugPrint("✅ Found working model: $name");
            _cachedModelName =
                name.startsWith('models/') ? name.substring(7) : name;
            return _cachedModelName!;
          }
        }
      } else {
        debugPrint("❌ Failed to list models: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Error listing models: $e");
    }

    // Fallback if list fails
    return 'gemini-1.5-flash';
  }

  /// Helper to get API Key with fallback priority
  String _getApiKey() {
    // Priority: Config -> .env
    String apiKey = Config.googleApiKey;
    debugPrint("DEBUG: Config.googleApiKey = '$apiKey'");

    if (apiKey.isEmpty || apiKey.contains('PASTE_YOUR')) {
      final envKey = dotenv.env['GEMINI_API_KEY'];
      debugPrint(
        "DEBUG: dotenv.env['GEMINI_API_KEY'] = '${envKey?.substring(0, 5)}...'",
      ); // Masked for security
      apiKey = envKey ?? '';
    }

    if (apiKey.isEmpty ||
        apiKey.contains('YOUR_') ||
        apiKey.contains('PASTE_YOUR')) {
      debugPrint("DEBUG: Final API Key check failed. apiKey='$apiKey'");
      throw Exception("API Key missing in .env and Config!");
    }
    return apiKey;
  }

  /// Generates an embedding for the given text using Gemini API
  Future<List<double>> _generateEmbedding(String text) async {
    final apiKey = _getApiKey();

    try {
      // Use 'text-embedding-004' for embeddings
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
    String apiKey;
    try {
      apiKey = _getApiKey();
    } catch (e) {
      yield "Error: No Valid API Key found. Please check .env or Config.";
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
    // 3. Call Gemini for Answer with Retry Logic
    int attempt = 0;
    const maxRetries = 3;

    while (attempt < maxRetries) {
      try {
        attempt++;
        // Find a working model dynamically
        final modelName = await _fetchWorkingModel(apiKey);
        if (attempt == 1) debugPrint("🤖 Using Gemini Model: $modelName");

        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final content = [Content.text(prompt)];
        final response = model.generateContentStream(content);

        await for (final chunk in response) {
          if (chunk.text != null) yield chunk.text!;
        }
        return; // Success!
      } catch (e) {
        debugPrint("AI Generation failed (Attempt $attempt/$maxRetries): $e");

        // If overloaded, wait and retry. otherwise fail.
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('overloaded') || errorStr.contains('503')) {
          yield "API Overloaded. Retrying... (Attempt $attempt/$maxRetries)";
          await Future.delayed(Duration(seconds: 2 * attempt)); // 2s, 4s, 6s
        } else {
          yield "Error: AI Service Unavailable. ($e)";
          return;
        }
      }
    }
    yield "Error: Service overloaded after $maxRetries attempts. Please try again later.";
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
