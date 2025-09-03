import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money_stacker/screens/UserCredentials/signupSuccessPage.dart';
import 'package:money_stacker/services/flutter_auth_service.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  final FirebaseAuthService _authService = FirebaseAuthService();

  void _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? error = await _authService.registerWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Registration successful")),
        );
        Get.to(() => SignupSuccessPage());
        // Navigate to login or home
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
              children: [
                const Text(
                  "MoneyStacker",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: "Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter your name";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),

                // Email
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

                // Password
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
                const SizedBox(height: 15),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: "Confirm Password",
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please confirm your password";
                    }
                    if (value != _passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                GestureDetector(
                  onTap: () {
                    Navigator.pop(context); // back to login
                  },
                  child: const Text(
                    "Already have an account?",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 20),

                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _signUp,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 50),
                        ),
                        child: const Text("Sign Up"),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
