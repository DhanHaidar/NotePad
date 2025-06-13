import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_note_dialog.dart';

class LabelNotesPage extends StatefulWidget {
  final String label;

  const LabelNotesPage({super.key, required this.label});

  @override
  _LabelNotesPageState createState() => _LabelNotesPageState();
}

class _LabelNotesPageState extends State<LabelNotesPage> {
  List<Map<String, dynamic>> filteredNotes = [];

  @override
  void initState() {
    super.initState();
    loadNotesWithLabel();
  }

  Future<void> loadNotesWithLabel() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('notes');

    if (jsonString == null) {
      setState(() {
        filteredNotes = [];
      });
      return;
    }

    final List<dynamic> decodedList = json.decode(jsonString);
    final List<Map<String, dynamic>> allNotes = decodedList.cast<Map<String, dynamic>>();

    final List<Map<String, dynamic>> notesWithLabel = [];

    for (var note in allNotes) {
      final labelsString = note['labels'] ?? '';
      List<String> labelList = [];

      if (labelsString.isNotEmpty) {
        try {
          labelList = List<String>.from(json.decode(labelsString));
        } catch (e) {
          labelList = [labelsString];
        }
      }

      if (labelList.contains(widget.label)) {
        notesWithLabel.add({
          'title': note['title'] ?? '',
          'content': note['content'] ?? '',
          'labels': labelList,
        });
      }
    }

    setState(() {
      filteredNotes = notesWithLabel;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catatan dengan label "${widget.label}"'),
        backgroundColor: Colors.black87,
      ),
      body: filteredNotes.isEmpty
          ? const Center(
        child: Text(
          "Tidak ada catatan dengan label ini.",
          style: TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: filteredNotes.length,
        itemBuilder: (context, index) {
          final note = filteredNotes[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AddNoteDialog(
                      initialTitle: note['title'],
                      initialContent: note['content'],
                      onSave: (updatedTitle, updatedContent) {
                        // Add save logic here if needed
                        print('Catatan diperbarui: $updatedTitle | $updatedContent');
                      },
                    );
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      note['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note['content'],
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((note['labels'] as List<String>).isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: (note['labels'] as List<String>)
                              .map((label) => Chip(
                            label: Text(
                              label,
                              style: const TextStyle(fontSize: 12),
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