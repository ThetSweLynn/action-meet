import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/new_meeting_form.dart';

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
                const SizedBox(height: 32),
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
