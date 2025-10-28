import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/meeting_detail_page.dart';

class MeetingCard extends StatelessWidget {
  final String documentId;

  const MeetingCard({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('meetings')
          .doc(documentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox(
            height: 80,
            child: Center(child: Text('Error loading meeting')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox(
            height: 80,
            child: Center(child: Text('Meeting not found')),
          );
        }

        final meeting = snapshot.data!.data() as Map<String, dynamic>;
        final date = (meeting['date'] as Timestamp?)?.toDate();

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade500),
            color: Colors.white,
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      MeetingDetailPage(documentId: documentId),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meeting['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D2D2D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (date != null)
                    Text(
                      date.toLocal().toString().split(' ')[0],
                      style: const TextStyle(color: Color(0xFF666666)),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        meeting['type'] == 'online'
                            ? Icons.video_call
                            : Icons.location_on,
                        color: const Color(0xFF666666),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        meeting['type'] == 'online'
                            ? meeting['link'] ?? 'No link'
                            : meeting['place'] ?? 'No place',
                        style: const TextStyle(color: Color(0xFF666666)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
