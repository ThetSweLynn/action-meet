import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final String createdBy; // email
  final Timestamp createdAt;
  final String? assignee; // email (optional)
  final Timestamp? deadline; // firestore timestamp
  final String status; // 'pending' or 'complete'

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.assignee,
    this.deadline,
    this.status = 'pending',
  });

  factory Task.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return Task(
      id: doc.id,
      title: (d['title'] ?? '') as String,
      description: d['description'] as String?,
      createdBy: (d['createdBy'] ?? '') as String,
      createdAt: d['createdAt'] as Timestamp? ?? Timestamp.now(),
      assignee: (d['assignee'] ?? '') as String,
      deadline: (d['deadline'] as Timestamp?) ?? Timestamp.now(),
      status: (d['status'] ?? 'pending') as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'assignee': assignee,
    'deadline': deadline,
    'status': status,
  };
}
