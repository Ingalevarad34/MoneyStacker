import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:money_stacker/screens/UserCredentials/login_screen.dart';
import 'package:money_stacker/screens/homePage.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return const Center(
              child: Text("Something went wrong"),
            );
          } else {
            if (snapshot.data == null) {
              return LoginScreen();
            } else {
              return  HomePage();
            }
          }
        },
      ),
    );
  }
}