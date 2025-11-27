import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddNotePage extends StatefulWidget {
  const AddNotePage({super.key});

  @override
  State<AddNotePage> createState() => _AddNotePageState();
}

class _AddNotePageState extends State<AddNotePage> {
  final supabase = Supabase.instance.client;
  final titleController = TextEditingController();
  final contentController = TextEditingController();
  bool isSaving = false;
  final FocusNode _contentFocusNode = FocusNode();

  // Professional color scheme
  final Color primaryColor = const Color(0xFF6366F1);
  final Color backgroundColor = const Color(0xFFF8FAFC);
  final Color surfaceColor = Colors.white;
  final Color textColor = const Color(0xFF1E293B);
  final Color subtitleColor = const Color(0xFF64748B);
  final Color borderColor = const Color(0xFFE2E8F0);

  Future<void> _saveNote() async {
    if (contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter some content for your note'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final userId = supabase.auth.currentUser!.id;

      await supabase.from('notes').insert({
        'user_id': userId,
        'title': titleController.text.trim().isEmpty 
            ? _generateTitleFromContent() 
            : titleController.text.trim(),
        'content': contentController.text.trim(),
      });

      if (!mounted) return;

      Navigator.pop(context);
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error saving note: $e"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _saveNote,
          ),
        ),
      );
    }

    if (mounted) {
      setState(() => isSaving = false);
    }
  }

  String _generateTitleFromContent() {
    final content = contentController.text.trim();
    if (content.length <= 30) {
      return content;
    }
    return '${content.substring(0, 30)}...';
  }

  void _showSaveConfirmation() {
    if (contentController.text.trim().isNotEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text('You have unsaved changes. Do you want to save before leaving?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close page without saving
              },
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                _saveNote(); // Save and then close
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          _showSaveConfirmation();
        }
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'New Note',
            style: TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: surfaceColor,
          elevation: 0,
          foregroundColor: textColor,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: isSaving
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(primaryColor),
                      ),
                    )
                  : IconButton(
                      onPressed: _saveNote,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.save_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      tooltip: 'Save Note',
                    ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Title Field
            Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: TextField(
                  controller: titleController,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Note Title (Optional)',
                    hintStyle: TextStyle(
                      color: subtitleColor,
                      fontWeight: FontWeight.normal,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  maxLines: 1,
                ),
              ),
            ),
            
            // Content Field with Header
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Content Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: borderColor),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.auto_awesome_rounded,
                              color: primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI Assistant Ready',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textColor,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Tooltip(
                              message: 'Your AI assistant can help analyze this note later',
                              child: Icon(
                                Icons.info_outline_rounded,
                                color: subtitleColor,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Content Field
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: contentController,
                            focusNode: _contentFocusNode,
                            maxLines: null,
                            expands: true,
                            textAlignVertical: TextAlignVertical.top,
                            style: TextStyle(
                              fontSize: 16,
                              height: 1.5,
                              color: textColor,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Start writing your thoughts, ideas, or anything you want to remember...\n\n💡 Your AI assistant will be able to help you analyze and organize this content later.',
                              hintStyle: TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: subtitleColor,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Character Count & Save Button - FIXED CONTAINER
            Container(
              width: double.infinity, // Added fixed width
              padding: const EdgeInsets.all(20), // Consistent padding
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  top: BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                children: [
                  // Character Count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.text_fields_rounded,
                          size: 16,
                          color: subtitleColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${contentController.text.length} chars',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Cancel Button
                  OutlinedButton(
                    onPressed: () => _showSaveConfirmation(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: subtitleColor,
                      side: BorderSide(color: borderColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Save Button
                  ElevatedButton(
                    onPressed: isSaving ? null : _saveNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSaving)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        else
                          // const Icon(Icons.save_rounded, size: 18),
                        // const SizedBox(width: 8),
                        Text(isSaving ? 'Saving...' : 'Save Note'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}