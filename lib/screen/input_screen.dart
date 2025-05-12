import 'package:flutter/material.dart';

class InputScreen extends StatefulWidget {
 const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  @override
  Widget build(BuildContext context)
  {
    return const Scaffold(
      body : Center(
        child: Text('Ini Input Screen'),
      ),
    );
  }
}