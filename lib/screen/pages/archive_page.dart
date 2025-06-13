import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'add_note_dialog.dart';

class ArchivePage extends StatefulWidget {
  final VoidCallback onUnarchive; // Callback saat catatan di-unarchive
  const ArchivePage({super.key, required this.onUnarchive});

  @override
  State<ArchivePage> createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  List<Map<String, String>> _archivedNotes = []; // Daftar catatan terarsip
  Set<int> _selectedIndexes = {}; // Indeks catatan yang dipilih
  bool get _isSelectionMode => _selectedIndexes.isNotEmpty; // Mode seleksi aktif?

  @override
  void initState() {
    super.initState();
    _loadArchivedNotes(); // Muat catatan saat inisialisasi
  }

  // Memuat catatan dari SharedPreferences
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

  // Membuka dialog edit catatan
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
          // Simpan perubahan ke SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('archive_notes', json.encode(_archivedNotes));
        },
      ),
    );
  }

  // Handle long press untuk mode seleksi
  void _onNoteLongPress(int index) {
    setState(() {
      _selectedIndexes.add(index);
    });
  }

  // Handle tap pada catatan
  void _onNoteTap(int index) {
    if (_isSelectionMode) {
      // Toggle seleksi jika dalam mode seleksi
      setState(() {
        if (_selectedIndexes.contains(index)) {
          _selectedIndexes.remove(index);
        } else {
          _selectedIndexes.add(index);
        }
      });
    } else {
      // Buka edit dialog jika tidak dalam mode seleksi
      final note = _archivedNotes[index];
      _openEditDialog(note['title'] ?? '', note['content'] ?? '', index);
    }
  }

  // Unarchive catatan yang dipilih
  Future<void> _unarchiveSelectedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final unarchivedNotes = _selectedIndexes
        .map((index) => _archivedNotes[index])
        .toList();

    setState(() {
      _archivedNotes.removeWhere((note) => unarchivedNotes.contains(note));
      _selectedIndexes.clear();
    });

    // Update data di SharedPreferences
    await prefs.setString('archive_notes', json.encode(_archivedNotes));

    // Pindahkan catatan ke daftar utama
    final notesJson = prefs.getString('notes');
    List<Map<String, dynamic>> notes = [];
    if (notesJson != null) {
      notes = json.decode(notesJson).cast<Map<String, dynamic>>().toList();
    }
    notes.addAll(unarchivedNotes);
    await prefs.setString('notes', json.encode(notes));

    widget.onUnarchive(); // Panggil callback untuk refresh halaman utama
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar( // AppBar mode seleksi
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
          : AppBar( // AppBar normal
        title: const Text('Arsip'),
        backgroundColor: Colors.black,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _archivedNotes.isEmpty
          ? const Center( // Tampilan jika arsip kosong
        child: Text('Tidak ada catatan di arsip'),
      )
          : GridView.builder( // Tampilan grid catatan
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // 2 card per baris
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.8, // Rasio tinggi/lebar card
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
                  ? Colors.deepPurple[100] // Warna saat dipilih
                  : const Color(0xFFF5EFFC), // Warna default
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul catatan
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
                    // Isi catatan
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
                    // Label (jika ada)
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