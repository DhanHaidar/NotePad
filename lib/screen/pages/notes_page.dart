import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/search_input.dart';
import 'add_note_dialog.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({Key? key}) : super(key: key);

  @override
  State<NotesPage> createState() => NotesPageState();
}

class NotesPageState extends State<NotesPage> {
  late TextEditingController _inputSearchController; // Controller untuk input pencarian
  List<Map<String, dynamic>> _notes = []; // Daftar catatan yang ditampilkan (setelah filter pencarian)
  List<Map<String, dynamic>> _allNotes = []; // Daftar lengkap semua catatan
  Set<int> _selectedIndexes = {}; // Indeks catatan yang dipilih untuk operasi batch

  @override
  void initState() {
    super.initState();
    _inputSearchController = TextEditingController(); // Inisialisasi controller pencarian
    _loadNotes(); // Memuat catatan dari penyimpanan saat widget diinisialisasi
  }

  /// Memuat catatan dari SharedPreferences
  Future<void> _loadNotes() async {
    final prefs = await SharedPreferences.getInstance(); // Mendapatkan instance SharedPreferences
    final jsonString = prefs.getString('notes'); // Mendapatkan data catatan dalam format JSON

    if (jsonString != null) {
      final List decoded = json.decode(jsonString); // Decode JSON ke List

      // Konversi data ke format yang konsisten
      _allNotes = decoded.cast<Map<String, dynamic>>().map((e) {
        return {
          'title': e['title'] as String, // Judul catatan
          'content': e['content'] as String, // Isi catatan
          'labels': e['labels'] != null ? e['labels'] as String : '', // Label catatan
          'pinned': e['pinned'] != null ? e['pinned'].toString() : 'false', // Status pin (true/false)
        };
      }).toList();

      // Urutkan catatan dengan yang dipin di atas
      _allNotes.sort((a, b) => (b['pinned'] == 'true' ? 1 : 0)
          .compareTo(a['pinned'] == 'true' ? 1 : 0));

      _notes = List.from(_allNotes); // Salin ke daftar catatan yang ditampilkan
      setState(() {}); // Perbarui UI
    }
  }

  /// Memuat ulang catatan dari penyimpanan
  void reloadNotes() {
    _loadNotes();
  }

  /// Menyimpan catatan ke SharedPreferences
  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_allNotes); // Encode daftar catatan ke JSON
    await prefs.setString('notes', jsonString); // Simpan ke penyimpanan
  }

  /// Menyimpan daftar label ke SharedPreferences
  Future<void> _saveLabelsToPrefs(Set<String> labels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('all_labels', labels.toList()); // Simpan daftar label
  }

  /// Memindahkan catatan ke tempat sampah
  Future<void> _moveToTrash(List<Map<String, dynamic>> notesToTrash) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('trash_notes') ?? '[]'; // Ambil data trash yang ada

    // Decode data trash
    List<Map<String, dynamic>> trashNotes =
    (json.decode(jsonString) as List).cast<Map<String, dynamic>>().toList();

    // Tambahkan catatan baru ke trash
    trashNotes.addAll(notesToTrash.map((note) => {
      'title': note['title'],
      'content': note['content'],
      'labels': note['labels'],
      'pinned': 'false', // Pastikan catatan trash tidak dipin
      'deleted_at': DateTime.now().toIso8601String(), // Tambahkan timestamp penghapusan
    }));

    await prefs.setString('trash_notes', json.encode(trashNotes)); // Simpan trash baru
  }

  /// Memindahkan catatan ke arsip
  Future<void> _moveToArchive(List<Map<String, dynamic>> notesToArchive) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('archive_notes') ?? '[]'; // Ambil data arsip yang ada

    // Decode data arsip
    List<Map<String, dynamic>> archiveNotes =
    (json.decode(jsonString) as List).cast<Map<String, dynamic>>().toList();

    // Tambahkan catatan baru ke arsip
    archiveNotes.addAll(notesToArchive.map((note) => {
      'title': note['title'],
      'content': note['content'],
      'labels': note['labels'],
      'pinned': 'false', // Pastikan catatan arsip tidak dipin
      'archived_at': DateTime.now().toIso8601String(), // Tambahkan timestamp pengarsipan
    }));

    await prefs.setString('archive_notes', json.encode(archiveNotes)); // Simpan arsip baru

    // Hapus dari daftar catatan utama
    setState(() {
      _allNotes.removeWhere((note) => notesToArchive.contains(note));
      _notes = List.from(_allNotes);
      _selectedIndexes.clear(); // Bersihkan seleksi
    });

    await _saveNotes(); // Simpan perubahan

    // Tampilkan notifikasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${notesToArchive.length} catatan diarsipkan'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Menampilkan dialog untuk menambah catatan baru
  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AddNoteDialog(
        onSave: (title, content) {
          setState(() {
            // Buat catatan baru
            final newNote = {
              'title': title,
              'content': content,
              'labels': '',
              'pinned': 'false',
            };
            _allNotes.add(newNote); // Tambahkan ke daftar
            _applySearch(_inputSearchController.text); // Terapkan pencarian ulang
          });
          _saveNotes(); // Simpan perubahan
        },
      ),
    );
  }

  /// Menampilkan dialog untuk mengedit catatan
  void _showEditNoteDialog(int index) {
    final note = _notes[index]; // Catatan yang akan diedit
    showDialog(
      context: context,
      builder: (context) => AddNoteDialog(
        initialTitle: note['title'], // Judul awal
        initialContent: note['content'], // Konten awal
        onSave: (updatedTitle, updatedContent) {
          setState(() {
            final realIndex = _allNotes.indexOf(note); // Temukan indeks asli
            // Perbarui catatan
            _allNotes[realIndex] = {
              'title': updatedTitle,
              'content': updatedContent,
              'labels': _allNotes[realIndex]['labels'] ?? '',
              'pinned': _allNotes[realIndex]['pinned'] ?? 'false',
            };
            _applySearch(_inputSearchController.text); // Terapkan pencarian ulang
          });
          _saveNotes(); // Simpan perubahan
        },
      ),
    );
  }

  /// Menerapkan pencarian pada daftar catatan
  void _applySearch(String query) {
    if (query.isEmpty) {
      // Jika query kosong, tampilkan semua catatan
      _notes = List.from(_allNotes);
    } else {
      // Filter catatan berdasarkan query
      _notes = _allNotes.where((note) {
        final lowerQuery = query.toLowerCase();
        final titleMatch =
            note['title']?.toLowerCase().contains(lowerQuery) ?? false;
        final contentMatch =
            note['content']?.toLowerCase().contains(lowerQuery) ?? false;
        return titleMatch || contentMatch; // Cocokkan judul atau konten
      }).toList();
    }
    setState(() {}); // Perbarui UI
  }

  /// Toggle seleksi catatan
  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index); // Hapus dari seleksi
      } else {
        _selectedIndexes.add(index); // Tambahkan ke seleksi
      }
    });
  }

  /// Membersihkan semua seleksi
  void _clearSelection() {
    setState(() {
      _selectedIndexes.clear();
    });
  }

  /// Menangani penghapusan catatan yang dipilih
  void _handleDeleteSelected() async {
    if (_selectedIndexes.isEmpty) return; // Jika tidak ada yang dipilih, keluar

    final selectedNotes = _selectedIndexes.map((i) => _notes[i]).toList(); // Dapatkan catatan yang dipilih

    setState(() {
      _allNotes.removeWhere((note) => selectedNotes.contains(note)); // Hapus dari daftar utama
      _applySearch(_inputSearchController.text); // Terapkan pencarian ulang
      _selectedIndexes.clear(); // Bersihkan seleksi
    });

    await _moveToTrash(selectedNotes); // Pindahkan ke trash
    await _saveNotes(); // Simpan perubahan

    // Tampilkan notifikasi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedNotes.length} catatan dipindahkan ke trash'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Menangani pin/unpin catatan yang dipilih
  void _handlePinSelected() {
    if (_selectedIndexes.isEmpty) return; // Jika tidak ada yang dipilih, keluar

    setState(() {
      for (var index in _selectedIndexes) {
        final note = _notes[index];
        final realIndex = _allNotes.indexOf(note);
        // Toggle status pin
        _allNotes[realIndex]['pinned'] =
        (_allNotes[realIndex]['pinned'] == 'true') ? 'false' : 'true';
      }
      // Urutkan ulang setelah mengubah status pin
      _allNotes.sort((a, b) => (b['pinned'] == 'true' ? 1 : 0)
          .compareTo(a['pinned'] == 'true' ? 1 : 0));
      _applySearch(_inputSearchController.text); // Terapkan pencarian ulang
      _clearSelection(); // Bersihkan seleksi
    });
    _saveNotes(); // Simpan perubahan
  }

  /// Menangani pengarsipan catatan yang dipilih
  void _handleArchiveSelected() async {
    if (_selectedIndexes.isEmpty) return;
    await _moveToArchive(_selectedIndexes.map((i) => _notes[i]).toList());
  }

  /// Menangani pemberian label pada catatan yang dipilih
  void _handleLabelSelected() {
    if (_selectedIndexes.isEmpty) return;
    _showLabelDialog(); // Tampilkan dialog label
  }

  /// Menampilkan dialog untuk menambah/memilih label
  void _showLabelDialog() async {
    final allLabels = <String>{}; // Semua label yang ada

    // Kumpulkan semua label dari semua catatan
    for (var note in _allNotes) {
      if (note['labels'] != null && note['labels']!.isNotEmpty) {
        final labelsList = (json.decode(note['labels']!) as List<dynamic>)
            .map((e) => e.toString())
            .toList();
        allLabels.addAll(labelsList);
      }
    }

    final selectedLabels = <String>{}; // Label yang dipilih
    // Kumpulkan label dari catatan yang dipilih
    for (var index in _selectedIndexes) {
      final note = _notes[index];
      final noteLabels = (note['labels'] != null && note['labels']!.isNotEmpty)
          ? (json.decode(note['labels']!) as List<dynamic>)
          .map((e) => e.toString())
          .toList()
          : <String>[];
      selectedLabels.addAll(noteLabels);
    }

    final TextEditingController labelController = TextEditingController(); // Controller untuk input label baru

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Tambah/Pilih Label'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Input untuk label baru
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label baru',
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Daftar label yang ada sebagai FilterChip
                    Expanded(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          children: allLabels.map((label) {
                            final isSelected = selectedLabels.contains(label);
                            return FilterChip(
                              label: Text(label),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    selectedLabels.add(label);
                                  } else {
                                    selectedLabels.remove(label);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context), // Tombol batal
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () async {
                    final newLabel = labelController.text.trim();
                    if (newLabel.isNotEmpty) {
                      selectedLabels.add(newLabel); // Tambahkan label baru
                      allLabels.add(newLabel); // Tambahkan ke daftar semua label
                    }

                    // Terapkan label ke semua catatan yang dipilih
                    for (var index in _selectedIndexes) {
                      final note = _notes[index];
                      final realIndex = _allNotes.indexOf(note);
                      _allNotes[realIndex]['labels'] =
                          json.encode(selectedLabels.toList());
                    }

                    await _saveLabelsToPrefs(allLabels); // Simpan label
                    await _saveNotes(); // Simpan catatan
                    _clearSelection(); // Bersihkan seleksi
                    if (mounted) Navigator.pop(context); // Tutup dialog jika widget masih mounted
                    setState(() {}); // Perbarui UI
                  },
                  child: const Text('Simpan'), // Tombol simpan
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Membuat AppBar khusus untuk mode seleksi
  Widget _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: Colors.blueGrey,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection, // Tombol untuk membersihkan seleksi
      ),
      title: Text('${_selectedIndexes.length} dipilih'), // Jumlah catatan yang dipilih
      actions: [
        IconButton(
          icon: const Icon(Icons.label),
          onPressed: _handleLabelSelected, // Tombol untuk menambah label
        ),
        IconButton(
          icon: const Icon(Icons.push_pin),
          onPressed: _handlePinSelected, // Tombol untuk pin/unpin
        ),
        IconButton(
          icon: const Icon(Icons.archive),
          onPressed: _handleArchiveSelected, // Tombol untuk arsip
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _handleDeleteSelected, // Tombol untuk hapus
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[600],
      // Tampilkan AppBar khusus jika ada catatan yang dipilih
      appBar: _selectedIndexes.isNotEmpty
          ? PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _buildSelectionAppBar(),
      )
          : null,
      body: Column(
        children: [
          // Tampilkan input pencarian jika tidak ada yang dipilih
          if (_selectedIndexes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SearchInput(
                controller: _inputSearchController,
                hint: 'Cari Note...',
                onChanged: _applySearch, // Fungsi yang dipanggil saat pencarian berubah
              ),
            ),
          Expanded(
            child: _notes.isEmpty
                ? const Center(
              child: Text(
                'Tidak ada catatan',
                style: TextStyle(color: Colors.white),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _notes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 kolom
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3 / 2, // Rasio aspek item
              ),
              itemBuilder: (context, index) {
                final note = _notes[index];
                final isSelected = _selectedIndexes.contains(index);
                final isPinned = note['pinned'] == 'true';

                return GestureDetector(
                  onTap: () => _selectedIndexes.isNotEmpty
                      ? _toggleSelection(index) // Jika dalam mode seleksi, toggle seleksi
                      : _showEditNoteDialog(index), // Jika tidak, buka editor
                  onLongPress: () => _toggleSelection(index), // Long press untuk memilih
                  child: Card(
                    color: isSelected ? Colors.blue[200] : null, // Warna berbeda jika dipilih
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isPinned)
                                const Icon(Icons.push_pin, size: 16), // Icon pin jika dipin
                              Expanded(
                                child: Text(
                                  note['title'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              note['content'] ?? '',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 4, // Batasi jumlah baris konten
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
      // Tampilkan FAB untuk menambah catatan jika tidak ada yang dipilih
      floatingActionButton: _selectedIndexes.isEmpty
          ? FloatingActionButton(
        onPressed: _showAddNoteDialog,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: Colors.yellow,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}