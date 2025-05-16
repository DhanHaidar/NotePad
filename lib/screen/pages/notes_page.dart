import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/search_input.dart';
import 'add_note_dialog.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late TextEditingController _inputSearchController;
  List<Map<String, String>> _notes = [];
  List<Map<String, String>> _allNotes = [];

  @override
  void initState() {
    super.initState();
    _inputSearchController = TextEditingController();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('notes');
    if (jsonString != null) {
      final List decoded = json.decode(jsonString);
      _allNotes = decoded.cast<Map<String, dynamic>>().map((e) => {
        'title': e['title'] as String,
        'content': e['content'] as String,
      }).toList();
      _notes = List.from(_allNotes);
      setState(() {});
    }
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_allNotes);
    await prefs.setString('notes', jsonString);
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AddNoteDialog(
        onSave: (title, content) {
          setState(() {
            final newNote = {'title': title, 'content': content};
            _allNotes.add(newNote);
            _applySearch(_inputSearchController.text);
          });
          _saveNotes();
        },
      ),
    );
  }
  void _showEditNoteDialog(int index) {
    final note = _notes[index];
    showDialog(
      context: context,
      builder: (context) => AddNoteDialog(
        initialTitle: note['title'],
        initialContent: note['content'],
        onSave: (updatedTitle, updatedContent) {
          setState(() {
            // Cari index asli di _allNotes
            final realIndex = _allNotes.indexOf(note);
            _allNotes[realIndex] = {
              'title': updatedTitle,
              'content': updatedContent,
            };
            _applySearch(_inputSearchController.text);
          });
          _saveNotes();
        },
      ),
    );
  }


  void _applySearch(String query) {
    if (query.isEmpty) {
      _notes = List.from(_allNotes);
    } else {
      _notes = _allNotes.where((note) {
        final lowerQuery = query.toLowerCase();
        final titleMatch = note['title']?.toLowerCase().contains(lowerQuery) ?? false;
        final contentMatch = note['content']?.toLowerCase().contains(lowerQuery) ?? false;
        return titleMatch || contentMatch;
      }).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[600],
      // AppBar telah dihapus sesuai permintaan
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchInput(
              controller: _inputSearchController,
              hint: 'Cari Note...',
              onChanged: (query) {
                _applySearch(query);
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _notes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3 / 2,
              ),
              itemBuilder: (context, index) {
                final note = _notes[index];
                return GestureDetector(
                  onTap: () {
                    _showEditNoteDialog(index);
                  },
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note['title'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              note['content'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },

            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 56,
        height: 56,
        child: FloatingActionButton(
          onPressed: _showAddNoteDialog,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.yellow,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
