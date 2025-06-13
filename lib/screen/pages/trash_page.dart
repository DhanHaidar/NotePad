import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TrashPage extends StatefulWidget {
  final VoidCallback onNotesRestored;

  const TrashPage({super.key, required this.onNotesRestored});

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  List<Map<String, String>> _trashNotes = [];
  Set<int> _selectedIndexes = {};

  @override
  void initState() {
    super.initState();
    _loadTrashNotes();
  }

  Future<void> _loadTrashNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('trash_notes');
    if (jsonString != null) {
      final List decoded = json.decode(jsonString);
      _trashNotes = decoded.cast<Map<String, dynamic>>().map((e) {
        return {
          'title': e['title'] as String,
          'content': e['content'] as String,
          'labels': e['labels'] != null ? e['labels'] as String : '',
        };
      }).toList();
      setState(() {});
    }
  }

  Future<void> _saveTrashNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_trashNotes);
    await prefs.setString('trash_notes', jsonString);
  }

  Future<void> _restoreSelectedNotes() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load current notes
    final notesJsonString = prefs.getString('notes');
    List<Map<String, String>> currentNotes = [];

    if (notesJsonString != null) {
      final List decoded = json.decode(notesJsonString);
      currentNotes = decoded.cast<Map<String, dynamic>>().map((e) {
        return {
          'title': e['title'] as String,
          'content': e['content'] as String,
          'labels': e['labels'] != null ? e['labels'] as String : '',
        };
      }).toList();
    }

    // 2. Get selected notes from trash
    final selectedNotes = _selectedIndexes.map((i) => _trashNotes[i]).toList();

    // 3. Add selected notes back to current notes
    currentNotes.addAll(selectedNotes);

    // 4. Save the updated notes
    await prefs.setString('notes', json.encode(currentNotes));

    // 5. Remove restored notes from trash
    setState(() {
      _trashNotes.removeWhere((note) => selectedNotes.contains(note));
      _selectedIndexes.clear();
    });

    // 6. Save updated trash notes
    await _saveTrashNotes();

    // 7. Trigger callback to notify parent to refresh
    widget.onNotesRestored();
  }

  Future<void> _deletePermanently() async {
    setState(() {
      final selectedNotes = _selectedIndexes.map((i) => _trashNotes[i]).toList();
      _trashNotes.removeWhere((note) => selectedNotes.contains(note));
      _selectedIndexes.clear();
    });
    await _saveTrashNotes();
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIndexes.clear();
    });
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: Colors.grey[850],
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      title: Text('${_selectedIndexes.length} dipilih'),
      actions: [
        IconButton(
          icon: const Icon(Icons.restore),
          tooltip: 'Pulihkan',
          onPressed: _restoreSelectedNotes,
        ),
        IconButton(
          icon: const Icon(Icons.delete_forever),
          tooltip: 'Hapus Permanen',
          onPressed: _deletePermanently,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndexes.isNotEmpty
          ? _buildSelectionAppBar()
          : AppBar(
        title: const Text('Sampah'),
        backgroundColor: Colors.black,
        titleTextStyle: TextStyle(
          color: Colors.white, // Ubah warna teks di sini
          fontSize: 20, // Opsional: ubah ukuran font
          fontWeight: FontWeight.bold, // Opsional: ubah ketebalan font
        ),
      ),
      body: _trashNotes.isEmpty
          ? const Center(child: Text('Tidak ada catatan di sampah.'))
          : GridView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _trashNotes.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 3 / 2,
        ),
        itemBuilder: (context, index) {
          final note = _trashNotes[index];
          final isSelected = _selectedIndexes.contains(index);

          return GestureDetector(
            onTap: () {
              if (_selectedIndexes.isNotEmpty) {
                _toggleSelection(index);
              }
            },
            onLongPress: () => _toggleSelection(index),
            child: Card(
              color: isSelected ? Colors.red[200] : Colors.grey[300],
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
    );
  }
}