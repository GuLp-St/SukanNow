import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import 'userpage.dart';
import 'admin_page.dart'; 

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        // User is signed in, store their email in the database
        final databaseRef = FirebaseDatabase.instance.ref();
        databaseRef.child('users/${user.uid}/email').set(user.email);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          // User is not signed in, show the sign-in screen
          return SignInScreen(
            providers: [
              EmailAuthProvider(),
            ],
            headerBuilder: (context, constraints, shrinkOffset) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.asset('assets/logo.png'),
                ),
              );
            },
            subtitleBuilder: (context, action) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: action == AuthAction.signIn
                    ? const Text('Welcome to SukanNow, please sign in!')
                    : const Text('Welcome to SukanNow, please sign up!'),
              );
            },
            footerBuilder: (context, action) {
              return const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Text(
                  'By signing in, you agree to our terms and conditions.',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            },
          );
        } else {
          // User is signed in, navigate to the home screen
          return FutureBuilder<DatabaseEvent>( // Changed to DatabaseEvent
            future: FirebaseDatabase.instance
                .ref()
                .child('admin_users/admin_key')
                .once(), // Use once() instead of get()
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (adminSnapshot.hasError) {
                return Center(
                    child: Text('Error: ${adminSnapshot.error.toString()}'));
              } else if (adminSnapshot.hasData &&
                  adminSnapshot.data!.snapshot.value != null) {
                final adminData = adminSnapshot.data!.snapshot.value
                as Map<dynamic, dynamic>;

                if (adminData['uid'] == snapshot.data!.uid) {
                  return const AdminPage();
                } else {
                  return const HomeScreen();
                }
              } else {
                return const HomeScreen();
                // Or show an error message
              }
            },
          );
        }
      },
    );
  }
}