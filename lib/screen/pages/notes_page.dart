import 'dart:developer';
import 'package:flutter/material.dart';
import '../../widgets/search_input.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  late TextEditingController _inputSearchController;

  // Dummy list of notes
  final List<String> _notes = List.generate(15, (index) => 'Note ${index + 1}');

  @override
  void initState() {
    super.initState();
    _inputSearchController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SearchInput(
            controller: _inputSearchController,
            hint: 'Search notes',
            onChanged: (query) {
              log('search: $query');
            },
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Jumlah kolom (ubah sesuai kebutuhan)
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 3 / 2, // Ukuran proporsi item
            ),
            itemCount: _notes.length,
            itemBuilder: (context, index) {
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                    child: Text(
                      _notes[index],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
