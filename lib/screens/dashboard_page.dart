import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_meeting_summary_page.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('meetings')
              .where('createdBy', isEqualTo: user?.email)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            final totalMeetings = snapshot.data!.docs.length;
            return Padding(
              padding: EdgeInsets.all(25),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 25),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Total Meetings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$totalMeetings',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
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
}
