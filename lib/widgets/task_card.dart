import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final ValueChanged<bool?>? onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onToggleComplete,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final deadlineText = task.deadline != null
        ? DateFormat.yMMMd().format(task.deadline!.toDate())
        : null;

    final completed = task.status == 'complete';
    final isPast =
        task.deadline != null &&
        task.deadline!.toDate().isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPast ? Colors.grey.shade300 : Colors.grey.shade500,
        ),
        color: isPast ? Colors.grey.shade50 : Colors.white,
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Checkbox(value: completed, onChanged: onToggleComplete),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isPast
                            ? const Color(0xFF888888)
                            : const Color(0xFF2D2D2D),
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
                        style: TextStyle(
                          color: isPast
                              ? const Color(0xFF999999)
                              : const Color(0xFF666666),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (deadlineText != null)
                          Text(
                            'Due: $deadlineText',
                            style: TextStyle(
                              color: isPast
                                  ? const Color(0xFF999999)
                                  : const Color(0xFF666666),
                            ),
                          ),
                        const SizedBox(width: 8),
                        if (task.meetingId != null)
                          Row(
                            children: [
                              Icon(
                                Icons.meeting_room,
                                color: isPast
                                    ? const Color(0xFF999999)
                                    : const Color(0xFF666666),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Meeting',
                                style: TextStyle(
                                  color: isPast
                                      ? const Color(0xFF999999)
                                      : const Color(0xFF666666),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Opacity(
                opacity: isPast ? 0.6 : 1.0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: onEdit),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
