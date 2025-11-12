import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/task_service.dart';
import '../models/task.dart';
import '../widgets/task_card.dart';
import '../widgets/task_editor.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final _service = TaskService();

  void _openEditor([Task? initial]) {
    showDialog(
      context: context,
      builder: (_) => TaskEditor(initial: initial),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('Please sign in to view tasks'));
    }

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Tasks'),
      //   actions: [
      //     IconButton(
      //       onPressed: () => _openEditor(),
      //       icon: const Icon(Icons.add),
      //     ),
      //   ],
      // ),
      body: StreamBuilder<List<Task>>(
        stream: _service.streamTasksCreatedBy(user.email ?? ''),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final tasks = snap.data ?? [];
          if (tasks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No tasks yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 18),
                  ),
                  // const SizedBox(height: 10),
                  // Text(
                  //   'Start creating',
                  //   style: TextStyle(color: Colors.grey.shade600),
                  // ),
                  // ElevatedButton(
                  //   onPressed: () => _openEditor(),
                  //   child: const Text('Create a task'),
                  // ),
                ],
              ),
            );
          }

          // Sort by deadline
          tasks.sort((a, b) {
            final deadlineA = (a.deadline)?.toDate() ?? DateTime(9999);
            final deadlineB = (b.deadline)?.toDate() ?? DateTime(9999);
            return deadlineA.compareTo(deadlineB);
          });

          return Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, top: 30),
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, i) {
                final t = tasks[i];
                return TaskCard(
                  task: t,
                  // onToggleComplete: (v) async =>
                  //     await _service.toggleComplete(t.id, v ?? false),
                  onEdit: () => _openEditor(t),
                  onDelete: () async => await _service.deleteTask(t.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
