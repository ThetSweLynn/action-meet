import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/new_meeting_form.dart';
import '../services/smtp_mail_service.dart';

class MeetingDetailPage extends StatelessWidget {
  final String documentId;

  const MeetingDetailPage({super.key, required this.documentId});

  void _deleteMeeting(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('meetings')
          .doc(documentId)
          .delete();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting meeting: $e')));
    }
  }

  void _updateMeeting(BuildContext context, Map<String, dynamic> meeting) {
    showDialog(
      context: context,
      builder: (context) =>
          NewMeetingForm(existingMeeting: meeting, documentId: documentId),
    );
  }

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
                  title: 'Date & Time',
                  value: date != null
                      ? '${date.toLocal().toString().split(' ')[0]} • ${meeting['time'] ?? 'No time'}'
                      : 'No date',
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
                                      Expanded(
                                        child: Text(
                                          email.toString(),
                                          style: const TextStyle(
                                            color: Color(0xFF2D2D2D),
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
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
                const SizedBox(height: 32),
                if ((meeting['members'] as List<dynamic>?)?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final members = List<String>.from(meeting['members']);
                          final title = meeting['title'] ?? 'Meeting';
                          final date =
                              (meeting['date'] as Timestamp?)
                                  ?.toDate()
                                  .toString()
                                  .split(' ')[0] ??
                              'No date';
                          final time = meeting['time'] ?? 'Time not specified';
                          final body =
                              'You were invited to "$title".\n\nDate: $date\nTime: $time\n${meeting['type'] == 'online' ? 'Link: ${meeting['link'] ?? ''}\n' : 'Place: ${meeting['place'] ?? ''}\n'}';
                          try {
                            // Attempt to send via SMTP only. If it fails, show error to user.
                            await SmtpMailService.sendMeetingInvitation(
                              recipients: members,
                              subject: 'You were invited: $title',
                              body: body,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invites sent successfully'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to send invites via SMTP: $e',
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        child: const Text(
                          'Send Invites',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _updateMeeting(context, meeting),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D2D2D),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Update',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _deleteMeeting(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
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
