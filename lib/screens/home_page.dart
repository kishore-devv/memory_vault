import 'package:flutter/material.dart';
import 'notes_page.dart';
import 'add_note_page.dart';
import 'ask_ai_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final screens = const [
    NotesPage(),
    AddNotePage(),
    AskAIPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: _buildFloatingOvalNavigationBar(),
    );
  }

Widget _buildFloatingOvalNavigationBar() {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    height: 68,
    decoration: BoxDecoration(
      color: Colors.black,
      borderRadius: BorderRadius.circular(50),

    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildInsetNavItem(
          index: 0,
          icon: Icons.edit_note_rounded,
          // label: "Notes",
        ),
        _buildInsetNavItem(
          index: 1,
          icon: Icons.add_circle_outline_rounded,
          // label: "",
        ),
        _buildInsetNavItem(
          index: 2,
          icon: Icons.auto_awesome_outlined,
          // label: "Ask AI",
        ),
      ],
    ),
  );
}

Widget _buildInsetNavItem({
  required int index,
  required IconData icon,
  // required String label,
}) {
  final isSelected = _currentIndex == index;
  
  return GestureDetector(
    onTap: () => setState(() => _currentIndex = index),
    child: Container(
      width: 80,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: isSelected
          ? BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            )
          : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? icon : icon,
            size: 24,
            color: isSelected ? Colors.black : Colors.white,
          ),
          // const SizedBox(height: 4),
          // Text(
          //   label,
          //   style: TextStyle(
          //     fontSize: 11,
          //     fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          //     color: isSelected ? Colors.black : Colors.white,
          //   ),
          // ),
        ],
      ),
    ),
  );
}
}