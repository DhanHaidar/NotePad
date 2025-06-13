import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/search_input.dart';

/// Kelas model untuk item To-Do
class TodoItem {
  final String id; // ID unik untuk setiap item
  String text; // Teks/task yang harus dilakukan
  bool isDone; // Status apakah task sudah selesai

  TodoItem({
    required this.id,
    required this.text,
    this.isDone = false, // Default status adalah belum selesai
  });

  /// Konversi ke format JSON untuk penyimpanan
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isDone': isDone,
  };

  /// Membuat TodoItem dari JSON
  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      text: json['text'],
      isDone: json['isDone'],
    );
  }
}

/// Halaman utama untuk manajemen To-Do List
class TodosPage extends StatefulWidget {
  const TodosPage({Key? key}) : super(key: key);

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  late TextEditingController _inputSearchController; // Controller untuk pencarian
  late TextEditingController _todoInputController; // Controller untuk input To-Do baru
  List<TodoItem> _todos = []; // Daftar lengkap semua To-Do
  List<TodoItem> _filteredTodos = []; // Daftar To-Do setelah difilter

  @override
  void initState() {
    super.initState();
    _inputSearchController = TextEditingController();
    _todoInputController = TextEditingController();
    _loadTodosFromStorage(); // Memuat data saat widget diinisialisasi
  }

  /// Menambahkan To-Do baru
  void _addTodo() {
    final text = _todoInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        final newTodo = TodoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // ID unik berdasarkan timestamp
          text: text,
        );
        _todos.add(newTodo);
        _filteredTodos = _todos; // Reset filter setelah menambah item baru
        _todoInputController.clear(); // Bersihkan input field
      });
      _saveTodosToStorage(); // Simpan perubahan
    }
  }

  /// Memfilter To-Do berdasarkan teks pencarian
  void _filterTodos(String query) {
    setState(() {
      _filteredTodos = _todos
          .where((todo) =>
          todo.text.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  /// Mengubah status selesai/belum selesai
  void _toggleDone(int index) {
    setState(() {
      _filteredTodos[index].isDone = !_filteredTodos[index].isDone;

      // Update item yang sesuai di _todos
      final toggledTodo = _filteredTodos[index];
      final todoIndex = _todos.indexWhere((todo) => todo.id == toggledTodo.id);
      if (todoIndex != -1) {
        _todos[todoIndex].isDone = toggledTodo.isDone;
      }
    });
    _saveTodosToStorage(); // Simpan perubahan
  }

  /// Menghapus To-Do
  void _deleteTodo(int index) {
    final idToDelete = _filteredTodos[index].id;
    setState(() {
      _todos.removeWhere((todo) => todo.id == idToDelete);
      _filteredTodos.removeWhere((todo) => todo.id == idToDelete);
    });
    _saveTodosToStorage(); // Simpan perubahan
  }

  /// Menyimpan To-Do ke SharedPreferences
  Future<void> _saveTodosToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final todoJsonList =
    _todos.map((todo) => json.encode(todo.toJson())).toList();
    await prefs.setStringList('todos', todoJsonList);
  }

  /// Memuat To-Do dari SharedPreferences
  Future<void> _loadTodosFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTodos = prefs.getStringList('todos');
    if (storedTodos != null) {
      setState(() {
        _todos = storedTodos
            .map((jsonStr) => TodoItem.fromJson(json.decode(jsonStr)))
            .toList();
        _filteredTodos = _todos; // Setel filter ke semua item saat pertama kali dimuat
      });
    }
  }

  @override
  void dispose() {
    _inputSearchController.dispose();
    _todoInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[600],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Widget pencarian
              SearchInput(
                controller: _inputSearchController,
                hint: 'Search Todos',
                onChanged: _filterTodos,
              ),
              const SizedBox(height: 16),

              // Input untuk menambah To-Do baru
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _todoInputController,
                  decoration: InputDecoration(
                    hintText: 'Add new To-Do',
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 14),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _addTodo,
                    ),
                  ),
                  onSubmitted: (_) => _addTodo(), // Tambahkan saat tombol enter ditekan
                ),
              ),
              const SizedBox(height: 24),

              // Daftar To-Do
              if (_filteredTodos.isEmpty)
                const Text('No To-Dos yet.') // Pesan jika tidak ada To-Do
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(), // Untuk menggabungkan dengan SingleChildScrollView
                  itemCount: _filteredTodos.length,
                  itemBuilder: (context, index) {
                    final todo = _filteredTodos[index];
                    return Card(
                      color: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        leading: Checkbox(
                          value: todo.isDone,
                          onChanged: (_) => _toggleDone(index), // Toggle status selesai
                        ),
                        title: Text(
                          todo.text,
                          style: TextStyle(
                            decoration: todo.isDone
                                ? TextDecoration.lineThrough // Coret teks jika selesai
                                : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: SvgPicture.asset(
                            'assets/icons/delete.svg', // Icon hapus dalam format SVG
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              Colors.grey[800]!,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () => _deleteTodo(index), // Hapus item
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}