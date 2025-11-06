import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// SMTP mail service that reads credentials from environment variables.
///
/// Required environment variables (recommended to store in a local `.env` file):
/// - SMTP_USERNAME (your Gmail address)
/// - SMTP_PASSWORD (your Gmail app password)
///
/// Note: For Gmail, you need to:
/// 1. Enable 2-Step Verification in your Google Account
/// 2. Generate an App Password for this application
/// 3. Use that App Password in the SMTP_PASSWORD environment variable
class SmtpMailService {
  // Helper to read env vars safely and provide actionable errors when dotenv
  // hasn't been loaded.
  static String _env(String key) {
    try {
      final val = dotenv.env[key];
      if (val == null || val.isEmpty) {
        throw StateError(
          'Missing required environment variable: $key. Please check your .env file.',
        );
      }
      return val;
    } catch (e) {
      // Likely dotenv not initialized. Surface a clearer message.
      throw StateError(
        'Environment not initialized. Please call `dotenv.load()` in `main()` before using SMTP. Original error: $e',
      );
    }
  }

  static String get _username => _env('SMTP_USERNAME');
  static String get _password => _env('SMTP_PASSWORD');

  static SmtpServer get _server => SmtpServer(
    'smtp.gmail.com',
    port: 465,
    username: _username,
    password: _password,
    ssl: true,
    ignoreBadCertificate: true,
  );

  /// Send meeting invitation emails to the provided recipients
  static Future<void> sendMeetingInvitation({
    required List<String> recipients,
    required String subject,
    required String body,
  }) async {
    if (_username.isEmpty || _password.isEmpty) {
      throw StateError(
        'SMTP credentials are not set. Please configure SMTP_USERNAME and SMTP_PASSWORD in your environment.',
      );
    }

    try {
      debugPrint('Attempting to send email from: $_username');
      debugPrint('To recipients: $recipients');

      final message = Message()
        ..from = Address(_username, 'Action Meet')
        ..recipients.addAll(recipients)
        ..subject = subject
        ..text = body;

      debugPrint('Connecting to SMTP server...');
      await send(message, _server).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('SMTP connection timed out after 30 seconds');
        },
      );
      debugPrint('Email sent successfully!');
    } catch (e, stackTrace) {
      // Keep errors visible for debugging; callers can decide how to show them to users.
      debugPrint('Error sending email: $e');
      debugPrint('Stack trace: $stackTrace');
      if (e is SocketException) {
        debugPrint('Network error details: ${e.message}');
      }
      rethrow;
    }
  }
}
