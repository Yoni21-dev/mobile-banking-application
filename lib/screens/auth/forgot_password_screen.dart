import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/api_service.dart';
import 'verification_code_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailOrPhoneController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void sendVerificationCode() async {
    String input = emailOrPhoneController.text.trim();

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter email or phone")),
      );
      return;
    }

    final ethiopianPhoneRegex = RegExp(r'^(09|011)\d{8}$');
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    if (!ethiopianPhoneRegex.hasMatch(input) && !emailRegex.hasMatch(input)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid email or phone")),
      );
      return;
    }

    try {
      // Determine if input is email or phone
      String field = emailRegex.hasMatch(input) ? 'email' : 'phone';

      // Query Firestore for user by email or phone
      QuerySnapshot userQuery = await _firestore
          .collection('users')
          .where(field, isEqualTo: input)
          .get();

      if (userQuery.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found")),
        );
        return;
      }

      // Generate 6-digit OTP (demo only)
      String otp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
      ApiService.currentOtp = otp;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP sent: $otp (demo only)")),
      );

      // Navigate to verification screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationCodeScreen(
            userEmailOrPhone: input,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  void dispose() {
    emailOrPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        title: const Text(
          "Forgot Password",
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
            /// Top Gradient Card
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
                  Icon(
                    Icons.lock_reset,
                    size: 55,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Recover your account securely",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            /// Input Field
            TextFormField(
              controller: emailOrPhoneController,
              decoration: InputDecoration(
                labelText: "Registered Email or Phone",
                prefixIcon: const Icon(Icons.person_outline),
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

            /// Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 5,
                ),
                onPressed: sendVerificationCode,
                child: const Text(
                  "Send Verification Code",
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