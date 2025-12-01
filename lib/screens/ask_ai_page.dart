import 'package:flutter/material.dart';

class AskAIPage extends StatelessWidget {
  const AskAIPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ask AI")),
      body: const Center(
        child: Text(
          "AI Memory Assistant Coming Soon...",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
