import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_note_dialog.dart'; // Pastikan path-nya sesuai dengan file kamu

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
        itemCount: filteredNotes.length,
        itemBuilder: (context, index) {
          final note = filteredNotes[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              title: Text(note['title']),
              subtitle: Text(note['content']),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AddNoteDialog(
                      initialTitle: note['title'],
                      initialContent: note['content'],
                      onSave: (updatedTitle, updatedContent) {
                        // Tambahkan logika penyimpanan jika ingin update disimpan
                        print('Catatan diperbarui: $updatedTitle | $updatedContent');
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
