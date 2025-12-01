import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NoteDetailPage extends StatefulWidget {
  final Map note;
  const NoteDetailPage({super.key, required this.note});

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();
}

class _NoteDetailPageState extends State<NoteDetailPage> {
  final supabase = Supabase.instance.client;
  late TextEditingController titleController;
  late TextEditingController contentController;
  bool isSaving = false;
  final FocusNode _contentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.note['title'] ?? 'Untitled');
    contentController = TextEditingController(text: widget.note['content'] ?? '');
  }

  Future<void> _updateNote() async {
    if (contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Note cannot be empty'),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      await supabase.from('notes').update({
        'title': titleController.text.trim().isEmpty 
            ? _generateTitleFromContent() 
            : titleController.text.trim(),
        'content': contentController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.note['id']);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error updating note: $e"),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
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

  Future<void> _deleteNote() async {
    try {
      await supabase
          .from('notes')
          .delete()
          .eq('id', widget.note['id']);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error deleting note: $e"),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Delete Note',
          style: TextStyle(
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this note? This action cannot be undone.',
          style: TextStyle(
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
            ),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNote();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
    final date = widget.note['created_at'] != null 
        ? DateTime.parse(widget.note['created_at']).toLocal()
        : DateTime.now();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: Colors.grey.shade800,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Note',
          style: TextStyle(
            color: Colors.grey.shade900,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_outline_rounded,
              color: Colors.grey.shade700,
            ),
            onPressed: _showDeleteConfirmation,
            tooltip: 'Delete note',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with date
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Text(
                _formatDate(date),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Title field
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: titleController,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                  height: 1.3,
                ),
                decoration: InputDecoration(
                  hintText: 'Note Title',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: 1,
              ),
            ),

            // Content field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
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
                      height: 1.6,
                      color: Colors.grey.shade900,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Write your thoughts here...\n\nStart typing to capture your ideas, thoughts, or anything important.',
                      hintStyle: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Colors.grey.shade500,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom action bar
            Container(
              margin: const EdgeInsets.only(top: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Character count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.text_fields_rounded,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${contentController.text.length} chars',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Cancel button
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),

                  const SizedBox(width: 12),

                  // Save button
                  ElevatedButton(
                    onPressed: isSaving ? null : _updateNote,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
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
                          Icon(
                            Icons.save_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 8),
                        Text(isSaving ? 'Saving...' : 'Save'),
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

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today • ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday • ${_formatTime(date)}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago • ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} • ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}