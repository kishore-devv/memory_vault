import 'package:flutter/material.dart';
import 'package:memory_vault/services/memory_service.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = []; // {role: user/ai, text: ...}
  bool _isTyping = false;

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _messages.add({'role': 'ai', 'text': ''}); // Placeholder for AI response
      _isTyping = true;
      _inputController.clear();
    });
    _scrollToBottom();

    // Stream the response
    String fullResponse = "";

    MemoryService()
        .askQuestion(text)
        .listen(
          (chunk) {
            // If the stream yields specific status messages ("Searching...", "Thinking...")
            // we could display them differently, but for MVP we just append or replace.
            // Actually, my service yields them as simple strings.

            // Let's filter out "Searching..." / "Thinking..." from the final text accumulator
            // to keep the chat clean, or just show them as transient states?
            // For simplicity, let's just append everything for now, or check for specific status strings.

            if (chunk == "Searching memories..." || chunk == "Thinking...") {
              // Maybe show a status indicator? For now, we just ignore or replace.
              // Let's replace the last message content to show status updates nicely
              setState(() {
                _messages.last['text'] = chunk;
              });
              fullResponse = ""; // Reset accumulator when status changes
            } else {
              // Real content
              fullResponse += chunk;
              setState(() {
                _messages.last['text'] = fullResponse;
              });
            }
            _scrollToBottom();
          },
          onDone: () {
            setState(() => _isTyping = false);
          },
          onError: (e) {
            setState(() {
              _messages.last['text'] = "Error: $e";
              _isTyping = false;
            });
            print(e);
          },
        );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ask Memory Vault')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          isUser
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: const InputDecoration(
                      hintText: 'Ask a question...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isTyping ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
