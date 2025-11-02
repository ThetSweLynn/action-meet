import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MemberMeetingDetailPage extends StatelessWidget {
  final String documentId;

  const MemberMeetingDetailPage({super.key, required this.documentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('meetings')
          .doc(documentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(body: const Center(child: Text('Meeting not found')));
        }

        final meeting = snapshot.data!.data() as Map<String, dynamic>;
        final date = (meeting['date'] as Timestamp?)?.toDate();

        return Scaffold(
          appBar: AppBar(
            title: const Text('Meeting Details'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: const Color(0xFF2D2D2D),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meeting['title'] ?? 'No Title',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D2D2D),
                  ),
                ),
                const SizedBox(height: 24),
                _DetailItem(
                  icon: Icons.calendar_today,
                  title: 'Date',
                  value: date?.toLocal().toString().split(' ')[0] ?? 'No date',
                ),
                const SizedBox(height: 16),
                _DetailItem(
                  icon: meeting['type'] == 'online'
                      ? Icons.video_call
                      : Icons.location_on,
                  title: meeting['type'] == 'online'
                      ? 'Meeting Link'
                      : 'Location',
                  value: meeting['type'] == 'online'
                      ? meeting['link'] ?? 'No link'
                      : meeting['place'] ?? 'No place',
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.people, color: Color(0xFF666666)),
                          const SizedBox(width: 16),
                          const Text(
                            'Members',
                            style: TextStyle(
                              color: Color(0xFF666666),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if ((meeting['members'] as List<dynamic>?)?.isEmpty ??
                          true)
                        const Text(
                          'No members added',
                          style: TextStyle(
                            color: Color(0xFF666666),
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        Column(
                          children: (meeting['members'] as List<dynamic>)
                              .map(
                                (email) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.person_outline,
                                        size: 20,
                                        color: Color(0xFF666666),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        email.toString(),
                                        style: const TextStyle(
                                          color: Color(0xFF2D2D2D),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF666666)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF2D2D2D),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
