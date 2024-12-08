// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TodoApp(),
    );
  }
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  final baseUrl = 'http://localhost:1999/todos';
  late Future<List<Map<String, dynamic>>> futureTodo;

  final todoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureTodo = fetchTodo();
  }

  @override
  void dispose() {
    todoController.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> fetchTodo() async {
    try {
      final jsonResponse = await http.get(Uri.parse(baseUrl));

      if (jsonResponse.statusCode == 200) {
        final List<dynamic> result = jsonDecode(jsonResponse.body);
        return result.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load todo');
      }
    } catch (e) {
      print('catch: $e');
      rethrow;
    }
  }

  Future<void> postTodo({required String todo}) async {
    final jsonResponse = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'todo': todo}),
    );

    Navigator.pop(context);
    if (jsonResponse.statusCode == 200) {
      // final response = jsonDecode(jsonResponse.body);
      setState(() {
        futureTodo = fetchTodo();
      });
      ScaffoldMessenger.of(context).showSnackBar(// message
          const SnackBar(content: Text('Todo added successfully')));
      todoController.clear();
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Something went wrong')));
      throw Exception('Failed to add todo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar(),
      body: body(),
      floatingActionButton: floatingActionButton(context),
    );
  }

  FloatingActionButton floatingActionButton(BuildContext context) {
    return FloatingActionButton(
      child: const Icon(Icons.add),
      onPressed: () {
        showTodoDialog(context);
      },
    );
  }

  AppBar appBar() {
    return AppBar(
      title: const Text('Todo App'),
    );
  }

  FutureBuilder<List<Map<String, dynamic>>> body() {
    return FutureBuilder(
      future: futureTodo,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final todo = snapshot.data as List<Map<String, dynamic>>;
          if (todo.isEmpty) {
            return const Center(child: Text('No todo found'));
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView.separated(
                itemCount: todo.length,
                separatorBuilder: (context, index) => Container(
                  height: 0.5,
                  color: Colors.grey,
                  margin: const EdgeInsets.only(bottom: 10),
                ),
                itemBuilder: (context, index) => ListTile(
                  tileColor: Colors.grey[200],
                  title: Text(
                    todo[index]['todo'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => deleteTodo(id: todo[index]['todo_id']),
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  }

  void showTodoDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: todoController,
                    decoration: const InputDecoration(
                      labelText: 'Todo',
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.redAccent[200],
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 20.0),
                      TextButton(
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.greenAccent[200],
                        ),
                        onPressed: () => postTodo(todo: todoController.text),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> deleteTodo({required int id}) async {
    print('deleteTodo: $id');
    final jsonresponse = await http.delete(Uri.parse('$baseUrl/$id'));

    Map<String, dynamic> response = jsonDecode(jsonresponse.body);
    if (jsonresponse.statusCode == 200) {
      setState(() {
        futureTodo = fetchTodo();
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Todo deleted successfully')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] as String)),
      );
      throw Exception('Failed to delete todo');
    }
  }
}
