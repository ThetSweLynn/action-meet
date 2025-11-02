import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/todo_card.dart';

class ToDoPage extends StatefulWidget {
  const ToDoPage({super.key});

  @override
  State<ToDoPage> createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                'My Tasks',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: Colors.black87,
                unselectedLabelColor: Colors.grey.shade600,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Pending'),
                  Tab(text: 'Completed'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildPendingTasksTab(user?.email),
                  _buildCompletedTasksTab(user?.email),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingTasksTab(String? userEmail) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('assignee', isEqualTo: userEmail)
          .where('status', isEqualTo: 'pending')
          .orderBy('deadline', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No pending tasks',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All caught up!',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final tasks = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                '${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'}',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final taskDoc = tasks[index];
                    final taskData = taskDoc.data() as Map<String, dynamic>;

                    final title =
                        taskData['title'] as String? ?? 'Untitled Task';
                    final detail = taskData['detail'] as String? ?? '';
                    final status = taskData['status'] as String? ?? 'pending';
                    final deadline = taskData['deadline'];

                    DateTime? deadlineDate;
                    if (deadline != null) {
                      if (deadline is Timestamp) {
                        deadlineDate = deadline.toDate();
                      } else if (deadline is String) {
                        deadlineDate = DateTime.tryParse(deadline);
                      }
                    }

                    return TodoCard(
                      taskId: taskDoc.id,
                      title: title,
                      detail: detail,
                      deadline: deadlineDate,
                      status: status,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedTasksTab(String? userEmail) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('tasks')
          .where('assignee', isEqualTo: userEmail)
          .where('status', isEqualTo: 'complete')
          .orderBy('deadline', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'No completed tasks yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start completing your tasks!',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        }

        final tasks = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                '${tasks.length} ${tasks.length == 1 ? 'task' : 'tasks'} completed',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final taskDoc = tasks[index];
                    final taskData = taskDoc.data() as Map<String, dynamic>;

                    final title =
                        taskData['title'] as String? ?? 'Untitled Task';
                    final detail = taskData['detail'] as String? ?? '';
                    final status = taskData['status'] as String? ?? 'complete';
                    final deadline = taskData['deadline'];

                    DateTime? deadlineDate;
                    if (deadline != null) {
                      if (deadline is Timestamp) {
                        deadlineDate = deadline.toDate();
                      } else if (deadline is String) {
                        deadlineDate = DateTime.tryParse(deadline);
                      }
                    }

                    return TodoCard(
                      taskId: taskDoc.id,
                      title: title,
                      detail: detail,
                      deadline: deadlineDate,
                      status: status,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
