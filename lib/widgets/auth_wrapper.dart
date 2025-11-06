import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/role_selection_page.dart';
import 'notification_listener.dart';
import '../screens/auth/sign_in_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return snapshot.hasData
            ? NotificationListenerWrapper(child: const RoleSelectionPage())
            : const SignInPage();
      },
    );
  }
}
