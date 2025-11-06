import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/upcoming_meetings_widget.dart';

class MemberDashboardPage extends StatefulWidget {
  const MemberDashboardPage({super.key});

  @override
  State<MemberDashboardPage> createState() => _MemberDashboardPageState();
}

class _MemberDashboardPageState extends State<MemberDashboardPage> {
  bool _isChartExpanded = true;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = userSnapshot.data;
            if (user == null) {
              return const Center(
                child: Text('Please sign in to view dashboard'),
              );
            }

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('assignee', isEqualTo: user.email)
                  .snapshots(),
              builder: (context, tasksSnapshot) {
                if (!tasksSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                int pendingTasks = 0;
                int completeTasks = 0;
                int missedDeadlineTasks = 0;

                for (var doc in tasksSnapshot.data!.docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] as String?;
                  final deadline = data['deadline'];

                  DateTime? deadlineDate;
                  if (deadline != null) {
                    if (deadline is Timestamp) {
                      deadlineDate = deadline.toDate();
                    } else if (deadline is String) {
                      deadlineDate = DateTime.tryParse(deadline);
                    }
                  }

                  if (deadlineDate != null) {
                    final deadlineDay = DateTime(
                      deadlineDate.year,
                      deadlineDate.month,
                      deadlineDate.day,
                    );

                    if (deadlineDay.isBefore(today) && status == 'pending') {
                      missedDeadlineTasks++;
                    } else {
                      if (status == 'pending') {
                        pendingTasks++;
                      } else if (status == 'complete') {
                        completeTasks++;
                      }
                    }
                  } else {
                    if (status == 'pending') {
                      pendingTasks++;
                    } else if (status == 'complete') {
                      completeTasks++;
                    }
                  }
                }

                final totalTasks =
                    pendingTasks + completeTasks + missedDeadlineTasks;

                return Padding(
                  padding: const EdgeInsets.all(25),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        //const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              'My Task Overview',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ==== Task Count Cards ====
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildTaskCard(
                                title: 'Pending\nTasks',
                                count: pendingTasks,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildTaskCard(
                                title: 'Complete\nTasks',
                                count: completeTasks,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 25,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.red.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.red.shade50,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.red.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Missed Deadline',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '$missedDeadlineTasks',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ==== Collapsible Chart Section ====
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _isChartExpanded = !_isChartExpanded;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 15,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Task Overview Chart',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Icon(
                                        _isChartExpanded
                                            ? Icons.keyboard_arrow_up
                                            : Icons.keyboard_arrow_down,
                                        color: Colors.black87,
                                        size: 35,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              AnimatedCrossFade(
                                duration: const Duration(milliseconds: 300),
                                crossFadeState: _isChartExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                firstChild: const SizedBox.shrink(),
                                secondChild: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Container(
                                          constraints: const BoxConstraints(
                                            maxWidth: 180,
                                          ),
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                            children: [
                                              SizedBox(
                                                height: 140,
                                                child: totalTasks == 0
                                                    ? Stack(
                                                        alignment:
                                                            Alignment.center,
                                                        children: [
                                                          Container(
                                                            width: 140,
                                                            height: 140,
                                                            decoration: BoxDecoration(
                                                              shape: BoxShape
                                                                  .circle,
                                                              border: Border.all(
                                                                color: Colors
                                                                    .grey
                                                                    .shade300,
                                                                width: 5,
                                                              ),
                                                            ),
                                                          ),
                                                          Text(
                                                            'No Tasks',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .grey
                                                                  .shade600,
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : PieChart(
                                                        PieChartData(
                                                          sectionsSpace: 2,
                                                          centerSpaceRadius: 30,
                                                          sections: [
                                                            if (pendingTasks >
                                                                0)
                                                              PieChartSectionData(
                                                                value: pendingTasks
                                                                    .toDouble(),
                                                                title:
                                                                    '${((pendingTasks / totalTasks) * 100).toStringAsFixed(0)}%',
                                                                color: Colors
                                                                    .orangeAccent,
                                                                radius: 60,
                                                                titleStyle: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            if (completeTasks >
                                                                0)
                                                              PieChartSectionData(
                                                                value: completeTasks
                                                                    .toDouble(),
                                                                title:
                                                                    '${((completeTasks / totalTasks) * 100).toStringAsFixed(0)}%',
                                                                color: Colors
                                                                    .green,
                                                                radius: 60,
                                                                titleStyle: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            if (missedDeadlineTasks >
                                                                0)
                                                              PieChartSectionData(
                                                                value: missedDeadlineTasks
                                                                    .toDouble(),
                                                                title:
                                                                    '${((missedDeadlineTasks / totalTasks) * 100).toStringAsFixed(0)}%',
                                                                color: Colors
                                                                    .redAccent,
                                                                radius: 60,
                                                                titleStyle: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color: Colors
                                                                      .white,
                                                                  fontSize: 14,
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
                                      const SizedBox(width: 25),
                                      // Legends
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            _buildLegend(
                                              Colors.orangeAccent,
                                              'Pending',
                                            ),
                                            const SizedBox(height: 15),
                                            _buildLegend(
                                              Colors.green,
                                              'Complete',
                                            ),
                                            const SizedBox(height: 15),
                                            _buildLegend(
                                              Colors.redAccent,
                                              'Missed',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Upcoming Meetings Session
                        UpcomingMeetingsWidget(userEmail: user.email!),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 14, height: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }

  Widget _buildTaskCard({required String title, required int count}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
