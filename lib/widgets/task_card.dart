import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskCard({super.key, required this.task, this.onEdit, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final deadlineText = task.deadline != null
        ? DateFormat.yMMMd().format(task.deadline!.toDate())
        : null;
    final assignee = task.assignee;
    final completed = task.status == 'complete';
    final isPast =
        task.deadline != null &&
        task.deadline!.toDate().isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPast ? Colors.red.shade300 : Colors.grey.shade500,
        ),
        color: isPast ? Colors.red.shade50 : Colors.white,
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Checkbox(value: completed, onChanged: onToggleComplete),
              // const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2D2D2D),
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (task.description != null &&
                        task.description!.isNotEmpty)
                      Text(
                        task.description!,
                        style: TextStyle(color: const Color(0xFF666666)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 13),
                    Row(
                      children: [
                        if (deadlineText != null)
                          Text(
                            'Due: $deadlineText',
                            style: TextStyle(color: const Color(0xFF666666)),
                          ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (assignee != null)
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            color: const Color(0xFF666666),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            assignee,
                            style: TextStyle(color: const Color(0xFF666666)),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
