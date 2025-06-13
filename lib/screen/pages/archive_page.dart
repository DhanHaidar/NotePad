import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_note_dialog.dart';

class ArchivePage extends StatefulWidget {
  final VoidCallback onUnarchive;
  const ArchivePage({super.key, required this.onUnarchive});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  List<Map<String, String>> _archivedNotes = [];
  Set<int> _selectedIndexes = {};
  bool get _isSelectionMode => _selectedIndexes.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _loadArchivedNotes();
  }

  Future<void> _loadArchivedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('archive_notes');
    if (jsonString != null) {
      final List decoded = json.decode(jsonString);
      _archivedNotes = decoded.cast<Map<String, dynamic>>().map((e) {
        return {
          'title': e['title'] as String,
          'content': e['content'] as String,
          'labels': e['labels'] != null ? e['labels'] as String : '',
        };
      }).toList();
      setState(() {});
    }
  }

  void _openEditDialog(String title, String content, int index) {
    showDialog(
      context: context,
      builder: (context) => AddNoteDialog(
        initialTitle: title,
        initialContent: content,
        onSave: (updatedTitle, updatedContent) async {
          setState(() {
            _archivedNotes[index] = {
              'title': updatedTitle,
              'content': updatedContent,
              'labels': _archivedNotes[index]['labels'] ?? '',
            };
          });

          final prefs = await SharedPreferences.getInstance();
          final jsonString = json.encode(_archivedNotes);
          await prefs.setString('archive_notes', jsonString);
        },
      ),
    );
  }

  void _onNoteLongPress(int index) {
    setState(() {
      _selectedIndexes.add(index);
    });
  }

  void _onNoteTap(int index) {
    if (_isSelectionMode) {
      setState(() {
        if (_selectedIndexes.contains(index)) {
          _selectedIndexes.remove(index);
        } else {
          _selectedIndexes.add(index);
        }
      });
    } else {
      final note = _archivedNotes[index];
      _openEditDialog(
        note['title'] ?? '',
        note['content'] ?? '',
        index,
      );
    }
  }

  Future<void> _unarchiveSelectedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final unarchivedNotes = _selectedIndexes.map((index) => _archivedNotes[index]).toList();

    setState(() {
      _archivedNotes.removeWhere((note) => unarchivedNotes.contains(note));
      _selectedIndexes.clear();
    });

    await prefs.setString('archive_notes', json.encode(_archivedNotes));

    final notesJson = prefs.getString('notes');
    List<Map<String, dynamic>> notes = [];

    if (notesJson != null) {
      final decoded = json.decode(notesJson);
      notes = decoded.cast<Map<String, dynamic>>().toList();
    }

    notes.addAll(unarchivedNotes);
    await prefs.setString('notes', json.encode(notes));

    widget.onUnarchive();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
        backgroundColor: Colors.black,
        title: Text('${_selectedIndexes.length} selected'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _selectedIndexes.clear()),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.unarchive, color: Colors.white),
            onPressed: _unarchiveSelectedNotes,
          ),
        ],
      )
          : AppBar(
        title: const Text('Arsip'),
        backgroundColor: Colors.black,
        titleTextStyle: TextStyle(
          color: Colors.white, // Ubah warna teks di sini
          fontSize: 20, // Opsional: ubah ukuran font
          fontWeight: FontWeight.bold, // Opsional: ubah ketebalan font
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _archivedNotes.isEmpty
          ? const Center(
        child: Text('Tidak ada catatan di arsip'),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 cards per row
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8, // Adjust card aspect ratio
        ),
        itemCount: _archivedNotes.length,
        itemBuilder: (context, index) {
          final note = _archivedNotes[index];
          final isSelected = _selectedIndexes.contains(index);
          return GestureDetector(
            onLongPress: () => _onNoteLongPress(index),
            onTap: () => _onNoteTap(index),
            child: Card(
              color: isSelected
                  ? Colors.deepPurple[100]
                  : const Color(0xFFF5EFFC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['title'] ?? 'No Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        note['content'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        maxLines: 5,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (note['labels']?.isNotEmpty ?? false)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 4,
                          children: note['labels']!
                              .split(',')
                              .where((label) => label.trim().isNotEmpty)
                              .map((label) => Chip(
                            label: Text(
                              label.trim(),
                              style: const TextStyle(fontSize: 10),
                            ),
                            backgroundColor: Colors.deepPurple[50],
                            materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                          ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}