import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TodoCard extends StatelessWidget {
  final String taskId;
  final String title;
  final String detail;
  final DateTime? deadline;
  final String status;

  const TodoCard({
    super.key,
    required this.taskId,
    required this.title,
    required this.detail,
    this.deadline,
    required this.status,
  });

  Future<void> _toggleTaskStatus() async {
    try {
      final newStatus = status == 'complete' ? 'pending' : 'complete';
      await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
        'status': newStatus,
      });
    } catch (e) {
      debugPrint('Error updating task status: $e');
    }
  }

  bool _isOverdue() {
    if (deadline == null || status == 'complete') return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDay = DateTime(
      deadline!.year,
      deadline!.month,
      deadline!.day,
    );
    return deadlineDay.isBefore(today);
  }

  // === Modal BottomSheet ===
  void _showTaskDetails(BuildContext context) {
    final isComplete = status == 'complete';
    final isOverdue = _isOverdue();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? Colors.red.shade100
                                : (isComplete
                                      ? Colors.green.shade100
                                      : Colors.orange.shade100),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOverdue
                                    ? Icons.warning_amber_rounded
                                    : (isComplete
                                          ? Icons.check_circle
                                          : Icons.pending),
                                size: 16,
                                color: isOverdue
                                    ? Colors.red.shade700
                                    : (isComplete
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOverdue
                                    ? 'Overdue'
                                    : (isComplete ? 'Completed' : 'Pending'),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isOverdue
                                      ? Colors.red.shade700
                                      : (isComplete
                                            ? Colors.green.shade700
                                            : Colors.orange.shade700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Title
                    const Text(
                      'Task Title',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isComplete
                            ? Colors.grey.shade600
                            : Colors.black87,
                        decoration: isComplete
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Deadline
                    if (deadline != null) ...[
                      const Text(
                        'Deadline',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isOverdue
                              ? Colors.red.shade50
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isOverdue
                                ? Colors.red.shade200
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: isOverdue
                                  ? Colors.red.shade700
                                  : Colors.grey.shade700,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              DateFormat(
                                'EEEE, MMMM dd, yyyy',
                              ).format(deadline!),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isOverdue
                                    ? Colors.red.shade700
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Details
                    const Text(
                      'Details',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        detail.isEmpty ? 'No details provided' : detail,
                        style: TextStyle(
                          fontSize: 15,
                          color: detail.isEmpty
                              ? Colors.grey.shade500
                              : (isComplete
                                    ? Colors.grey.shade600
                                    : Colors.black87),
                          height: 1.5,
                          decoration: isComplete
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          _toggleTaskStatus();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isComplete
                              ? Colors.orange.shade600
                              : Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isComplete ? Icons.refresh : Icons.check_circle,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isComplete
                                  ? 'Mark as Pending'
                                  : 'Mark as Complete',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = status == 'complete';
    final isOverdue = _isOverdue();

    return GestureDetector(
      onTap: () => _showTaskDetails(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isOverdue
              ? Colors.red.shade50
              : (isComplete ? Colors.grey.shade50 : Colors.white),
          border: Border.all(
            color: isOverdue
                ? Colors.red.shade300
                : (isComplete ? Colors.grey.shade300 : Colors.grey.shade400),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isComplete ? Colors.grey.shade600 : Colors.black87,
                      decoration: isComplete
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 14,
                        color: isComplete
                            ? Colors.grey.shade500
                            : Colors.grey.shade700,
                        decoration: isComplete
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (deadline != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: isOverdue
                              ? Colors.red.shade700
                              : (isComplete
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade600),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('MMM dd, yyyy').format(deadline!),
                          style: TextStyle(
                            fontSize: 13,
                            color: isOverdue
                                ? Colors.red.shade700
                                : (isComplete
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade600),
                            fontWeight: isOverdue
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        if (isOverdue) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'OVERDUE',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                _toggleTaskStatus();
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isComplete ? Colors.green : Colors.grey.shade400,
                    width: 2,
                  ),
                  color: isComplete ? Colors.green : Colors.transparent,
                ),
                child: isComplete
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
