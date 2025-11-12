import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/new_meeting_form.dart';
import '../widgets/meeting_card.dart';

class MeetingsPage extends StatelessWidget {
  const MeetingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Meetings'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: const Color(0xFF2D2D2D),
        ),
        body: const Center(child: Text('Please log in to view your meetings.')),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('meetings')
              .where('createdBy', isEqualTo: user.email)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data?.docs ?? [];

            if (docs.isEmpty) {
              return const Center(
                child: Text(
                  'No meetings yet',
                  style: TextStyle(color: Color(0xFF666666), fontSize: 16),
                ),
              );
            }

            // Sort by date in Dart
            docs.sort((a, b) {
              final dateA =
                  (a['date'] as Timestamp?)?.toDate() ?? DateTime.now();
              final dateB =
                  (b['date'] as Timestamp?)?.toDate() ?? DateTime.now();
              return dateA.compareTo(dateB);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return MeetingCard(documentId: docs[index].id);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const NewMeetingForm(),
          );
        },
        backgroundColor: const Color(0xFF2D2D2D),
        child: const Icon(Icons.add),
      ),
    );
  }
}
