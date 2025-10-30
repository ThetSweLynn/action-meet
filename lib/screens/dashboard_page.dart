import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_meeting_summary_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('meetings')
              .where('createdBy', isEqualTo: user?.email)
              .snapshots(),
          builder: (context, meetingsSnapshot) {
            if (!meetingsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final totalMeetings = meetingsSnapshot.data!.docs.length;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tasks')
                  .where('createdBy', isEqualTo: user?.email)
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
                        const SizedBox(height: 20,),
                        // ==== Total Meetings Card ====
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 25,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Meetings',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$totalMeetings',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Text(
                              'Task Overview',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        

                        // ==== Task Count Cards ====
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildTaskCard(
                                title: 'Pending Tasks',
                                count: pendingTasks,
                              ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: _buildTaskCard(
                                title: 'Complete Tasks',
                                count: completeTasks,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 15,
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
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // ==== Donut Chart ====
                            Container(
                              width: 200,
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: 140,
                                    child: PieChart(
                                      PieChartData(
                                        sectionsSpace: 2,
                                        centerSpaceRadius: 30,
                                        sections: [
                                          if (pendingTasks > 0)
                                            PieChartSectionData(
                                              value: pendingTasks.toDouble(),
                                              title: totalTasks == 0
                                                  ? '0%'
                                                  : '${((pendingTasks / totalTasks) * 100).toStringAsFixed(0)}%',
                                              color: Colors.orangeAccent,
                                              radius: 60,
                                              titleStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          if (completeTasks > 0)
                                            PieChartSectionData(
                                              value: completeTasks.toDouble(),
                                              title: totalTasks == 0
                                                  ? '0%'
                                                  : '${((completeTasks / totalTasks) * 100).toStringAsFixed(0)}%',
                                              color: Colors.green,
                                              radius: 60,
                                              titleStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                          if (missedDeadlineTasks > 0)
                                            PieChartSectionData(
                                              value: missedDeadlineTasks.toDouble(),
                                              title: totalTasks == 0
                                                  ? '0%'
                                                  : '${((missedDeadlineTasks / totalTasks) * 100).toStringAsFixed(0)}%',
                                              color: Colors.redAccent,
                                              radius: 60,
                                              titleStyle: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
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
                            const SizedBox(width: 25),
                            // Legends
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLegend(Colors.orangeAccent, 'Pending'),
                                const SizedBox(height: 15),
                                _buildLegend(Colors.green, 'Complete'),
                                const SizedBox(height: 15),
                                _buildLegend(Colors.redAccent, 'Missed'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0), Color(0xFF00B4DB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AIMeetingSummaryPage(),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          label: const Text(
            'AI Meeting Summary',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          icon: const Icon(Icons.auto_awesome, color: Colors.white),
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
