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
  late TextEditingController _inputSearchController;
  List<Map<String, dynamic>> _notes = [];
  List<Map<String, dynamic>> _allNotes = [];
  Set<int> _selectedIndexes = {};

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
      _allNotes = decoded.cast<Map<String, dynamic>>().map((e) {
        return {
          'title': e['title'] as String,
          'content': e['content'] as String,
          'labels': e['labels'] != null ? e['labels'] as String : '',
          'pinned': e['pinned'] != null ? e['pinned'].toString() : 'false',
        };
      }).toList();

      // Sort notes with pinned first
      _allNotes.sort((a, b) => (b['pinned'] == 'true' ? 1 : 0)
          .compareTo(a['pinned'] == 'true' ? 1 : 0));

      _notes = List.from(_allNotes);
      setState(() {});
    }
  }

  void reloadNotes() {
    _loadNotes();
  }

  Future<void> _saveNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_allNotes);
    await prefs.setString('notes', jsonString);
  }

  Future<void> _saveLabelsToPrefs(Set<String> labels) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('all_labels', labels.toList());
  }

  Future<void> _moveToTrash(List<Map<String, dynamic>> notesToTrash) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('trash_notes') ?? '[]';
    List<Map<String, dynamic>> trashNotes =
    (json.decode(jsonString) as List).cast<Map<String, dynamic>>().toList();

    trashNotes.addAll(notesToTrash.map((note) => {
      'title': note['title'],
      'content': note['content'],
      'labels': note['labels'],
      'pinned': 'false',
      'deleted_at': DateTime.now().toIso8601String(),
    }));

    await prefs.setString('trash_notes', json.encode(trashNotes));
  }

  Future<void> _moveToArchive(List<Map<String, dynamic>> notesToArchive) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('archive_notes') ?? '[]';
    List<Map<String, dynamic>> archiveNotes =
    (json.decode(jsonString) as List).cast<Map<String, dynamic>>().toList();

    archiveNotes.addAll(notesToArchive.map((note) => {
      'title': note['title'],
      'content': note['content'],
      'labels': note['labels'],
      'pinned': 'false',
      'archived_at': DateTime.now().toIso8601String(),
    }));

    await prefs.setString('archive_notes', json.encode(archiveNotes));

    // Remove from main notes
    setState(() {
      _allNotes.removeWhere((note) => notesToArchive.contains(note));
      _notes = List.from(_allNotes);
      _selectedIndexes.clear();
    });

    await _saveNotes();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${notesToArchive.length} catatan diarsipkan'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (context) => AddNoteDialog(
        onSave: (title, content) {
          setState(() {
            final newNote = {
              'title': title,
              'content': content,
              'labels': '',
              'pinned': 'false',
            };
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
            final realIndex = _allNotes.indexOf(note);
            _allNotes[realIndex] = {
              'title': updatedTitle,
              'content': updatedContent,
              'labels': _allNotes[realIndex]['labels'] ?? '',
              'pinned': _allNotes[realIndex]['pinned'] ?? 'false',
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
        final titleMatch =
            note['title']?.toLowerCase().contains(lowerQuery) ?? false;
        final contentMatch =
            note['content']?.toLowerCase().contains(lowerQuery) ?? false;
        return titleMatch || contentMatch;
      }).toList();
    }
    setState(() {});
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

  void _handleDeleteSelected() async {
    if (_selectedIndexes.isEmpty) return;

    final selectedNotes = _selectedIndexes.map((i) => _notes[i]).toList();

    setState(() {
      _allNotes.removeWhere((note) => selectedNotes.contains(note));
      _applySearch(_inputSearchController.text);
      _selectedIndexes.clear();
    });

    await _moveToTrash(selectedNotes);
    await _saveNotes();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedNotes.length} catatan dipindahkan ke trash'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handlePinSelected() {
    if (_selectedIndexes.isEmpty) return;

    setState(() {
      for (var index in _selectedIndexes) {
        final note = _notes[index];
        final realIndex = _allNotes.indexOf(note);
        _allNotes[realIndex]['pinned'] =
        (_allNotes[realIndex]['pinned'] == 'true') ? 'false' : 'true';
      }
      // Re-sort after changing pin status
      _allNotes.sort((a, b) => (b['pinned'] == 'true' ? 1 : 0)
          .compareTo(a['pinned'] == 'true' ? 1 : 0));
      _applySearch(_inputSearchController.text);
      _clearSelection();
    });
    _saveNotes();
  }

  void _handleArchiveSelected() async {
    if (_selectedIndexes.isEmpty) return;
    await _moveToArchive(_selectedIndexes.map((i) => _notes[i]).toList());
  }

  void _handleLabelSelected() {
    if (_selectedIndexes.isEmpty) return;
    _showLabelDialog();
  }

  void _showLabelDialog() async {
    final allLabels = <String>{};

    for (var note in _allNotes) {
      if (note['labels'] != null && note['labels']!.isNotEmpty) {
        final labelsList = (json.decode(note['labels']!) as List<dynamic>)
            .map((e) => e.toString())
            .toList();
        allLabels.addAll(labelsList);
      }
    }

    final selectedLabels = <String>{};
    for (var index in _selectedIndexes) {
      final note = _notes[index];
      final noteLabels = (note['labels'] != null && note['labels']!.isNotEmpty)
          ? (json.decode(note['labels']!) as List<dynamic>)
          .map((e) => e.toString())
          .toList()
          : <String>[];
      selectedLabels.addAll(noteLabels);
    }

    final TextEditingController labelController = TextEditingController();

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
                    TextField(
                      controller: labelController,
                      decoration: const InputDecoration(
                        labelText: 'Label baru',
                      ),
                    ),
                    const SizedBox(height: 10),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                TextButton(
                  onPressed: () async {
                    final newLabel = labelController.text.trim();
                    if (newLabel.isNotEmpty) {
                      selectedLabels.add(newLabel);
                      allLabels.add(newLabel);
                    }

                    for (var index in _selectedIndexes) {
                      final note = _notes[index];
                      final realIndex = _allNotes.indexOf(note);
                      _allNotes[realIndex]['labels'] =
                          json.encode(selectedLabels.toList());
                    }

                    await _saveLabelsToPrefs(allLabels);
                    await _saveNotes();
                    _clearSelection();
                    if (mounted) Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSelectionAppBar() {
    return AppBar(
      backgroundColor: Colors.blueGrey,
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: _clearSelection,
      ),
      title: Text('${_selectedIndexes.length} dipilih'),
      actions: [
        IconButton(
          icon: const Icon(Icons.label),
          onPressed: _handleLabelSelected,
        ),
        IconButton(
          icon: const Icon(Icons.push_pin),
          onPressed: _handlePinSelected,
        ),
        IconButton(
          icon: const Icon(Icons.archive),
          onPressed: _handleArchiveSelected,
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: _handleDeleteSelected,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[600],
      appBar: _selectedIndexes.isNotEmpty
          ? PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: _buildSelectionAppBar(),
      )
          : null,
      body: Column(
        children: [
          if (_selectedIndexes.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: SearchInput(
                controller: _inputSearchController,
                hint: 'Cari Note...',
                onChanged: _applySearch,
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
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3 / 2,
              ),
              itemBuilder: (context, index) {
                final note = _notes[index];
                final isSelected = _selectedIndexes.contains(index);
                final isPinned = note['pinned'] == 'true';

                return GestureDetector(
                  onTap: () => _selectedIndexes.isNotEmpty
                      ? _toggleSelection(index)
                      : _showEditNoteDialog(index),
                  onLongPress: () => _toggleSelection(index),
                  child: Card(
                    color: isSelected ? Colors.blue[200] : null,
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (isPinned)
                                const Icon(Icons.push_pin, size: 16),
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