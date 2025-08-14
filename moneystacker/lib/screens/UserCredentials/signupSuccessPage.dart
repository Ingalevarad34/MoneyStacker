import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SignupSuccessPage extends StatefulWidget {
  @override
  _SignupSuccessPageState createState() => _SignupSuccessPageState();
}

class _SignupSuccessPageState extends State<SignupSuccessPage>
    with SingleTickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Lottie Animation
            Lottie.asset(
              'assets/success.json',
              repeat: false,
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            Text(
              "Signup Successful!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Welcome to the app 🎉",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.pop(context); // Go back or navigate to home
              },
              child: const Text(
                "Continue",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}
