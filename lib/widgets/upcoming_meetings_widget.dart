import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class UpcomingMeetingsWidget extends StatelessWidget {
  final String userEmail;

  const UpcomingMeetingsWidget({super.key, required this.userEmail});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.event, color: Colors.blue.shade700, size: 24),
                const SizedBox(width: 10),
                const Text(
                  'Upcoming Meetings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // Meetings List
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('meetings')
                .where('members', arrayContains: userEmail)
                .where('date', isGreaterThan: Timestamp.fromDate(now))
                .orderBy('date', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildError(snapshot.error.toString());
              }

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final meetings = snapshot.data!.docs;

              if (meetings.isEmpty) {
                return _buildEmpty();
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(15),
                itemCount: meetings.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final data = meetings[index].data() as Map<String, dynamic>;
                  final title = data['title'] as String? ?? 'Untitled Meeting';
                  final type = data['type'] as String? ?? 'onsite';
                  final place = data['place'] as String? ?? '';
                  final link = data['link'] as String? ?? '';
                  final meetingDate = data['date'];
                  DateTime? dateTime;

                  if (meetingDate is Timestamp) {
                    dateTime = meetingDate.toDate();
                  } else if (meetingDate is String) {
                    dateTime = DateTime.tryParse(meetingDate);
                  }

                  return _buildMeetingCard(
                    title: title,
                    dateTime: dateTime,
                    type: type,
                    place: place,
                    link: link,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard({
    required String title,
    required DateTime? dateTime,
    required String type,
    required String place,
    required String link,
  }) {
    final icon = type == 'online'
        ? Icons.videocam
        : Icons.meeting_room; // right-side icon

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Left: Text info
          Expanded(
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
                if (dateTime != null)
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('EEE, MMM d yyyy • h:mm a').format(dateTime),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 6),

                // Type-specific display
                if (type == 'onsite' && place.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          place,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else if (type == 'online' && link.isNotEmpty)
                  GestureDetector(
                    onTap: () async {
                      final uri = Uri.tryParse(link);
                      if (uri != null && await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Icon(Icons.link, size: 14, color: Colors.blue.shade600),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            link,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              //decoration: TextDecoration.underline,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Right: Icon for meeting type
          Icon(
            icon,
            color: type == 'online'
                ? Colors.blue.shade600
                : Colors.blueGrey.shade600,
            size: 22,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) => Padding(
    padding: const EdgeInsets.all(40),
    child: Center(
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
          const SizedBox(height: 12),
          Text(
            'Error loading meetings',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Widget _buildEmpty() => Padding(
    padding: const EdgeInsets.all(40),
    child: Center(
      child: Column(
        children: [
          Icon(Icons.event_available, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No upcoming meetings',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    ),
  );
}
