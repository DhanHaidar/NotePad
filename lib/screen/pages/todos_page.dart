import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/search_input.dart';

class TodoItem {
  final String id;
  String text;
  bool isDone;

  TodoItem({
    required this.id,
    required this.text,
    this.isDone = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'isDone': isDone,
  };

  factory TodoItem.fromJson(Map<String, dynamic> json) {
    return TodoItem(
      id: json['id'],
      text: json['text'],
      isDone: json['isDone'],
    );
  }
}

class TodosPage extends StatefulWidget {
  const TodosPage({Key? key}) : super(key: key);

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  late TextEditingController _inputSearchController;
  late TextEditingController _todoInputController;
  List<TodoItem> _todos = [];
  List<TodoItem> _filteredTodos = [];

  @override
  void initState() {
    super.initState();
    _inputSearchController = TextEditingController();
    _todoInputController = TextEditingController();
    _loadTodosFromStorage();
  }

  void _addTodo() {
    final text = _todoInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        final newTodo = TodoItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: text,
        );
        _todos.add(newTodo);
        _filteredTodos = _todos;
        _todoInputController.clear();
      });
      _saveTodosToStorage();
    }
  }

  void _filterTodos(String query) {
    setState(() {
      _filteredTodos = _todos
          .where((todo) =>
          todo.text.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _toggleDone(int index) {
    setState(() {
      _filteredTodos[index].isDone = !_filteredTodos[index].isDone;
    });
    _saveTodosToStorage();
  }

  void _deleteTodo(int index) {
    final idToDelete = _filteredTodos[index].id;
    setState(() {
      _todos.removeWhere((todo) => todo.id == idToDelete);
      _filteredTodos.removeWhere((todo) => todo.id == idToDelete);
    });
    _saveTodosToStorage();
  }

  Future<void> _saveTodosToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final todoJsonList =
    _todos.map((todo) => json.encode(todo.toJson())).toList();
    await prefs.setStringList('todos', todoJsonList);
  }

  Future<void> _loadTodosFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final storedTodos = prefs.getStringList('todos');
    if (storedTodos != null) {
      setState(() {
        _todos = storedTodos
            .map((jsonStr) => TodoItem.fromJson(json.decode(jsonStr)))
            .toList();
        _filteredTodos = _todos;
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
              SearchInput(
                controller: _inputSearchController,
                hint: 'Search Todos',
                onChanged: _filterTodos,
              ),
              const SizedBox(height: 16),
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
                  onSubmitted: (_) => _addTodo(),
                ),
              ),
              const SizedBox(height: 24),
              if (_filteredTodos.isEmpty)
                const Text('No To-Dos yet.')
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
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
                          onChanged: (_) => _toggleDone(index),
                        ),
                        title: Text(
                          todo.text,
                          style: TextStyle(
                            decoration: todo.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: SvgPicture.asset(
                            'assets/icons/delete.svg',
                            width: 24,
                            height: 24,
                            colorFilter: ColorFilter.mode(
                              Colors.grey[800]!,
                              BlendMode.srcIn,
                            ),
                          ),
                          onPressed: () => _deleteTodo(index),
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
