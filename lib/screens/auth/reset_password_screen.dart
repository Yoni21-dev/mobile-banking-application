import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  final String userEmailOrPhone;

  const ResetPasswordScreen({super.key, required this.userEmailOrPhone});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  String? passwordError;
  String? confirmError;
  bool loading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SHA-256 hash helper
  String hashString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<void> resetPassword() async {
    setState(() {
      passwordError = null;
      confirmError = null;
    });

    String password = passwordController.text.trim();
    String confirm = confirmController.text.trim();

    if (password.isEmpty || password.length < 6) {
      setState(() => passwordError = "Password must be at least 6 characters");
      return;
    }

    if (password != confirm) {
      setState(() => confirmError = "Passwords do not match");
      return;
    }

    setState(() => loading = true);

    try {
      // Find user document by email or phone
      final querySnapshot = await _firestore
          .collection('users')
          .where(widget.userEmailOrPhone.contains('@') ? 'email' : 'phone',
              isEqualTo: widget.userEmailOrPhone)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found")),
        );
        setState(() => loading = false);
        return;
      }

      final userDoc = querySnapshot.docs.first;

      // Hash the password before saving
      String hashedPassword = hashString(password);

      // Update password and clear OTP
      await _firestore.collection('users').doc(userDoc.id).update({
        'password': hashedPassword,
        'otp': FieldValue.delete(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset successfully")),
      );

      // Go back to login screen
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error resetting password")),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        title: const Text(
          "Reset Password",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Gradient Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(
                  colors: [Color(0xff667eea), Color(0xff764ba2)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.shade200,
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Column(
                children: [
                  Icon(Icons.lock_open, size: 55, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    "Set your new secure password",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            TextFormField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "New Password",
                prefixIcon: const Icon(Icons.lock),
                errorText: passwordError,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            TextFormField(
              controller: confirmController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Confirm Password",
                prefixIcon: const Icon(Icons.lock_outline),
                errorText: confirmError,
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 35),

            SizedBox(
              width: double.infinity,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 5,
                      ),
                      child: const Text(
                        "Reset Password",
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}