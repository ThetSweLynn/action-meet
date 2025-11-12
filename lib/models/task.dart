import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String id;
  final String title;
  final String? description;
  final String createdBy; // email
  final Timestamp createdAt;
  final String? assignedTo; // email (optional)
  final Timestamp? deadline; // firestore timestamp
  final String status; // 'pending' or 'complete'
  final int priority; // 0 low, 1 medium, 2 high
  final String? meetingId;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.createdBy,
    required this.createdAt,
    this.assignedTo,
    this.deadline,
    this.status = 'pending',
    this.priority = 1,
    this.meetingId,
  });

  factory Task.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return Task(
      id: doc.id,
      title: (d['title'] ?? '') as String,
      description: d['description'] as String?,
      createdBy: (d['createdBy'] ?? '') as String,
      createdAt: d['createdAt'] as Timestamp? ?? Timestamp.now(),
      assignedTo: d['assignedTo'] as String?,
      deadline: d['deadline'] as Timestamp?,
      status: (d['status'] ?? 'pending') as String,
      priority: (d['priority'] ?? 1) as int,
      meetingId: d['meetingId'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'description': description,
    'createdBy': createdBy,
    'createdAt': createdAt,
    'assignedTo': assignedTo,
    'deadline': deadline,
    'status': status,
    'priority': priority,
    'meetingId': meetingId,
  };
}
