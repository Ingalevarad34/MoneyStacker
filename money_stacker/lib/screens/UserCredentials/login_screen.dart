import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:money_stacker/screens/UserCredentials/signup_screen.dart';
import 'package:money_stacker/screens/homePage.dart';
import 'package:money_stacker/services/flutter_auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final FirebaseAuthService _authService = FirebaseAuthService();

  void _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error = await _authService.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful")),
        );
        Get.to(() => HomePage());
        // Navigate to home/dashboard
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "MoneyStacker",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your email";
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your password";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    // Navigate to sign up page
                    Get.to(() => SignUpScreen());
                  },
                  child: const Text(
                    "Create an account?",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 20),

                // Login Button
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 50),
                        ),
                        child: const Text("Login In"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
