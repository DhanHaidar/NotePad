import 'dart:developer';

import 'package:flutter/material.dart';

import '../../constants/color_scheme.dart';
import '../../widgets/search_input.dart';

class TodosPage extends StatefulWidget {
  const TodosPage({Key? key}) : super(key: key);

  @override
  State<TodosPage> createState() => _TodosPageState();
}

class _TodosPageState extends State<TodosPage> {
  late TextEditingController _inputSearchController;
  @override
  void initState() {
    super.initState();
    _inputSearchController = TextEditingController();
  }
  @override
  Widget build(BuildContext context)
  {
    return Column(
      children: [
        SearchInput(
          controller: _inputSearchController,
          hint: 'Search Todos',
          onChanged: (query){
            log('search: $query');
          },
        ),
      ],
    );
  }
}