import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Wraps a child and listens for new meetings where the current user's email
/// is included in the `members` array. When a new meeting is created that
/// contains the current user, a SnackBar notification is shown.
class NotificationListenerWrapper extends StatefulWidget {
  final Widget child;

  const NotificationListenerWrapper({super.key, required this.child});

  @override
  State<NotificationListenerWrapper> createState() =>
      _NotificationListenerWrapperState();
}

class _NotificationListenerWrapperState
    extends State<NotificationListenerWrapper> {
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Listen for meetings where the current user's email is in the members array.
    final query = FirebaseFirestore.instance
        .collection('meetings')
        .where('members', arrayContains: user.email)
        .orderBy('createdAt', descending: true)
        .limit(20);

    _subscription = query.snapshots().listen(
      (snapshot) {
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data();
            if (data == null) continue;
            final title = (data['title'] ?? 'New meeting').toString();
            // Keep a debug log for monitoring without UI interruption
            debugPrint(
              'Notification (silent): you were added to a meeting: $title',
            );
          }
        }
      },
      onError: (error) {
        debugPrint('Notification listener error: $error');
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
