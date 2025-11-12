import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task.dart';

class TaskService {
  final _col = FirebaseFirestore.instance.collection('tasks');

  /// Stream tasks created by the given user email (most recent first).
  Stream<List<Task>> streamTasksCreatedBy(String userEmail) {
    return _col
        .where('createdBy', isEqualTo: userEmail)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => Task.fromDoc(d)).toList());
  }

  Future<DocumentReference> addTask({
    required String title,
    String? description,
    String? assignedToEmail,
    Timestamp? deadline,
    String? meetingId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    // Prefer email for human-readable creator, but fall back to uid when
    // email is null (e.g., phone-auth users). This keeps dashboard queries
    // working for both cases.
    final createdBy = (user?.email != null && user!.email!.isNotEmpty)
        ? user.email!
        : (user?.uid ?? 'unknown');

    // Normalize the assigned email (trim + lowercase) and store it
    // both as legacy single-value fields and as an 'assignees' array so
    // member queries can use arrayContains reliably.
    final normalizedAssigned = assignedToEmail?.trim().toLowerCase();

    final data = <String, dynamic>{
      'title': title,
      // Support both 'description' (used by TasksPage) and 'detail'
      // (used by Member ToDoPage) to ensure compatibility across screens.
      'description': description,
      'detail': description,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      // Store normalized assignee(s)
      'assignees': normalizedAssigned == null ? null : [normalizedAssigned],
      'assignedTo': normalizedAssigned,
      'assignee': normalizedAssigned,
      'deadline': deadline,
      'status': 'pending',
      'priority': 1,
      'meetingId': meetingId,
    };

    return _col.add(data);
  }

  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    await _col.doc(taskId).update(updates);
  }

  Future<void> deleteTask(String taskId) async {
    await _col.doc(taskId).delete();
  }

  Future<void> toggleComplete(String taskId, bool complete) async {
    await updateTask(taskId, {'status': complete ? 'complete' : 'pending'});
  }
}
