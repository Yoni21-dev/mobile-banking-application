import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';
import '../home/dashboard_screen.dart';
import 'register_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailOrPhone = TextEditingController();
  final password = TextEditingController();

  bool obscurePassword = true;
  bool loading = false;

  Future<void> login() async {
    if (emailOrPhone.text.isEmpty || password.text.isEmpty) {
      showMsg("All fields are required");
      return;
    }

    setState(() {
      loading = true;
    });

    String result = await ApiService.login(
      emailOrPhone.text.trim(),
      password.text.trim(),
    );

    if (!mounted) return;

    setState(() {
      loading = false;
    });

    showMsg(result);

    if (result == "Login successful") {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('loggedUser', emailOrPhone.text.trim());

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void forgotPassword() {
    final inputController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Forgot Password'),
        content: TextField(
          controller: inputController,
          decoration: const InputDecoration(labelText: 'Enter Email or Phone'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              String input = inputController.text.trim();

              if (input.isEmpty) {
                showMsg('Please enter email or phone');
                return;
              }

              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              String? targetEmail;

              if (emailRegex.hasMatch(input)) {
                targetEmail = input;
              } else {
                final query = await FirebaseFirestore.instance
                    .collection('users')
                    .where('phone', isEqualTo: input)
                    .limit(1)
                    .get();

                if (query.docs.isEmpty) {
                  showMsg('User not found');
                  return;
                }

                final data = query.docs.first.data();
                if (data['email'] != null &&
                    data['email'].toString().isNotEmpty) {
                  targetEmail = data['email'];
                } else {
                  showMsg(
                    'Password reset is only available for accounts registered with email.',
                  );
                  return;
                }
              }

              if (targetEmail == null || targetEmail.isEmpty) {
                showMsg('Password reset is not available for this user');
                return;
              }

              try {
                await FirebaseAuth.instance.sendPasswordResetEmail(
                  email: targetEmail,
                );
                showMsg('Password reset email sent');
                Navigator.pop(context);
              } catch (e) {
                showMsg('Error: ${e.toString()}');
              }
            },
            child: const Text('Send Reset Email'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailOrPhone.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.green,
                  child: Icon(
                    Icons.account_balance,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Mobile Banking",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: emailOrPhone,
                  decoration: InputDecoration(
                    labelText: "Email or Phone",
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: password,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: "Password",
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                loading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          minimumSize: const Size(double.infinity, 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: login,
                        child: const Text(
                          "LOGIN",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: forgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Register",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
