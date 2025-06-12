import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'label_notes_page.dart'; // kita akan buat file ini

class LabelPage extends StatefulWidget {
  const LabelPage({Key? key}) : super(key: key);

  @override
  State<LabelPage> createState() => _LabelPageState();
}

class _LabelPageState extends State<LabelPage> {
  List<String> labels = [];

  @override
  void initState() {
    super.initState();
    _loadLabels();
  }

  Future<void> _loadLabels() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('notes');
    if (jsonString != null) {
      final List decoded = json.decode(jsonString);
      final List<Map<String, dynamic>> allNotes =
      decoded.cast<Map<String, dynamic>>();

      final Set<String> allLabels = {};
      for (var note in allNotes) {
        if (note['labels'] != null && note['labels'].isNotEmpty) {
          final List<dynamic> noteLabels = json.decode(note['labels']);
          allLabels.addAll(noteLabels.map((e) => e.toString()));
        }
      }

      setState(() {
        labels = allLabels.toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Label'),
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: labels.length,
        itemBuilder: (context, index) {
          final label = labels[index];
          return ListTile(
            title: Text(label),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LabelNotesPage(label: label),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
