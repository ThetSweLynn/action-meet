import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'widgets/auth_wrapper.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

// Disable certificate verification (only in debug mode)
void _configureCertificateVerification() {
  if (kDebugMode) {
    HttpOverrides.global = _DevHttpOverrides();
  }
}

class _DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

Future<void> main() async {
  _configureCertificateVerification(); // Add this line
  WidgetsFlutterBinding.ensureInitialized();
  // Load local environment variables from .env. In debug builds we want this
  // to be required so failures surface immediately rather than later when
  // attempting to send mail.
  debugPrint('Attempting to load .env file...');
  try {
    // Try multiple potential locations for the .env file
    for (final location in ['.env', 'assets/.env']) {
      try {
        await dotenv.load(fileName: location);
        debugPrint('Successfully loaded .env file from $location');
        if (kDebugMode) {
          // Print all environment variables in debug mode
          debugPrint('Environment variables loaded:');
          dotenv.env.forEach((key, value) {
            debugPrint(
              '$key: ${value.replaceAll(RegExp(r'.'), '*')}',
            ); // Mask values for security
          });
          break;
        }
      } catch (e) {
        debugPrint('Failed to load from $location: $e');
        continue;
      }
    }

    // Verify that critical variables are present
    final requiredVars = ['SMTP_USERNAME', 'SMTP_PASSWORD'];
    final missingVars = requiredVars
        .where((v) => !dotenv.env.containsKey(v))
        .toList();

    if (missingVars.isNotEmpty) {
      throw Exception(
        'Missing required environment variables: ${missingVars.join(', ')}',
      );
    }
  } catch (e) {
    debugPrint('Failed to load environment: $e');
    // During development fail fast so you notice missing/incorrect .env.
    if (kDebugMode) rethrow;
    // In release, continue without env (SMTP will throw a clear error if used).
  }
  // Debug: confirm whether dotenv loaded and whether SMTP_USERNAME key exists.
  debugPrint(
    'dotenv loaded: has SMTP_USERNAME=${dotenv.env.containsKey('SMTP_USERNAME')}',
  );

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Action Meet',
      initialRoute: '/',
      routes: {'/': (context) => const AuthWrapper()},
      theme: ThemeData(
        fontFamily: 'Poppins',
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.white,
          background: Colors.white,
        ),
      ),
    );
  }
}
