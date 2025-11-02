import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Open the user's mail client with prefilled subject and body, with fallbacks.
/// recipients - list of email addresses (will be placed in bcc to protect privacy).
/// Will try mailto: first, then alternative email clients if available.
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

  try {
    // Try mailto: first
    if (await launchUrl(uriObj)) {
      return; // Successfully launched
    }

    // If mailto: fails, try alternative email URLs/schemes
    if (Platform.isAndroid) {
      // Try Gmail app-specific URL on Android
      final gmailUri = Uri.parse(
        'https://mail.google.com/mail/?view=cm'
        '&to=&bcc=$bcc&su=$encodedSubject&body=$encodedBody',
      );
      if (await launchUrl(gmailUri, mode: LaunchMode.externalApplication)) {
        return; // Successfully launched Gmail in browser
      }
    } else if (Platform.isIOS) {
      // Try native iOS Mail app scheme
      final iosMailUri = Uri.parse(
        'message://compose?bcc=$bcc&subject=$encodedSubject&body=$encodedBody',
      );
      if (await launchUrl(iosMailUri)) {
        return; // Successfully launched iOS Mail app
      }

      // Try Gmail app scheme on iOS
      final iosGmailUri = Uri.parse(
        'googlegmail:///co?bcc=$bcc&subject=$encodedSubject&body=$encodedBody',
      );
      if (await launchUrl(iosGmailUri)) {
        return; // Successfully launched iOS Gmail app
      }
    }

    // All attempts failed - throw with more helpful message
    throw Exception(
      'Could not launch mail client. Please ensure you have an email app installed '
      'and configured on your device.',
    );
  } catch (e) {
    debugPrint('Mail client error: $e');
    rethrow; // Let caller handle the error
  }
}
