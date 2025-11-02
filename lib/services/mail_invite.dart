import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Open the user's mail client with prefilled subject and body.
/// recipients - list of email addresses (will be placed in bcc to protect privacy)
Future<void> openMailClient({
  required List<String> recipients,
  required String subject,
  required String body,
}) async {
  // Use bcc so recipients don't see each other
  final bcc = Uri.encodeComponent(recipients.join(','));
  final encodedSubject = Uri.encodeComponent(subject);
  final encodedBody = Uri.encodeComponent(body);

  // mailto: supports to, cc, bcc and body
  final uri = 'mailto:?bcc=$bcc&subject=$encodedSubject&body=$encodedBody';

  final uriObj = Uri.parse(uri);
  // Try to open the mail client
  if (!await launchUrl(uriObj)) {
    throw Exception('Could not launch mail client');
  }
}
