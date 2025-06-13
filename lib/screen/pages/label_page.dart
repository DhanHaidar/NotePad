import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'label_notes_page.dart';

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
        titleTextStyle: TextStyle(
          color: Colors.white, // Ubah warna teks di sini
          fontSize: 20, // Opsional: ubah ukuran font
          fontWeight: FontWeight.bold, // Opsional: ubah ketebalan font
        ),
      ),
      body: labels.isEmpty
          ? const Center(
        child: Text(
          'Tidak ada label yang tersimpan',
          style: TextStyle(fontSize: 16),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: labels.length,
          itemBuilder: (context, index) {
            final label = labels[index];
            return Card(
              margin: const EdgeInsets.symmetric(
                  vertical: 4.0, horizontal: 8.0),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8.0),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LabelNotesPage(label: label),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const Icon(Icons.label, color: Colors.deepPurple),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right,
                          color: Colors.grey),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}