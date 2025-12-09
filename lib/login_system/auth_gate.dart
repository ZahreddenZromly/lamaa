import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';
import '../profile_edit_page.dart'; // ✅ use the correct profile page
import '../home_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Still checking auth state
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Not logged in → show login
        if (!authSnapshot.hasData) {
          return const LoginPage();
        }

        final user = authSnapshot.data!;

        // Logged in → listen to this user's Firestore document
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text(
                    'Firestore error:\n${userSnapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              );
            }

            final doc = userSnapshot.data;
            final exists = doc?.exists ?? false;

            Map<String, dynamic>? data;
            if (exists) {
              data = doc!.data() as Map<String, dynamic>?;
            }

            // consider profile incomplete if "name" is empty
            final hasName =
                (data?['name'] ?? '').toString().trim().isNotEmpty;

            // No profile / incomplete → show profile edit (first-time setup)
            if (!exists || !hasName) {
              return const ProfileEditPage();
            }

            // Profile exists → go to home
            return const HomePage();
          },
        );
      },
    );
  }
}
