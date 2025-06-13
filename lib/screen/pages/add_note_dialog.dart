import 'package:flutter/material.dart';

class AddNoteDialog extends StatefulWidget {
  final Function(String title, String content) onSave; // Callback ketika catatan disimpan
  final String? initialTitle; // Judul awal (untuk mode edit)
  final String? initialContent; // Konten awal (untuk mode edit)

  const AddNoteDialog({
    Key? key,
    required this.onSave,
    this.initialTitle,
    this.initialContent,
  }) : super(key: key);

  @override
  State<AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<AddNoteDialog> {
  late TextEditingController _titleController; // Controller untuk input judul
  late TextEditingController _contentController; // Controller untuk input konten

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan nilai awal (jika ada)
    _titleController = TextEditingController(text: widget.initialTitle ?? '');
    _contentController = TextEditingController(text: widget.initialContent ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero, // Menghilangkan padding default Dialog
      child: Scaffold(
        backgroundColor: const Color(0xFFBCBABA), // Warna latar belakang abu-abu
        appBar: AppBar(
          title: Text(
            widget.initialTitle == null ? 'Tambah Catatan' : 'Edit Catatan',
          ),
          actions: [
            // Tombol Batal
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal', style: TextStyle(color: Colors.black)),
            ),
            // Tombol Simpan
            TextButton(
              onPressed: () {
                // Validasi input tidak boleh kosong
                if (_titleController.text.isNotEmpty &&
                    _contentController.text.isNotEmpty) {
                  widget.onSave(
                    _titleController.text,
                    _contentController.text,
                  );
                  Navigator.pop(context); // Tutup dialog setelah simpan
                }
              },
              child: const Text('Simpan', style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Input Judul Catatan
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16), // Spacer
              // Input Isi Catatan (bisa multi-line)
              Expanded(
                child: TextField(
                  controller: _contentController,
                  expands: true, // Mengisi sisa ruang yang tersedia
                  maxLines: null, // Bisa menampung banyak baris
                  textAlign: TextAlign.start,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: const InputDecoration(
                    labelText: 'Isi Catatan',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  keyboardType: TextInputType.multiline, // Keyboard multi-line
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose(); // Bersihkan controller
    _contentController.dispose();
    super.dispose();
  }
}