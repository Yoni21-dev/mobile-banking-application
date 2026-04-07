import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reset_password_screen.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class VerificationCodeScreen extends StatefulWidget {
  final String userEmailOrPhone;

  const VerificationCodeScreen({super.key, required this.userEmailOrPhone});

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final codeController = TextEditingController();
  String? codeError;

  int timerSeconds = 60;
  Timer? countdownTimer;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // SHA-256 hash helper
  String hashString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    codeController.dispose();
    super.dispose();
  }

  void startTimer() {
    timerSeconds = 60;
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (timerSeconds > 0) {
          timerSeconds--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> verifyCode() async {
    setState(() => codeError = null);
    String inputCode = codeController.text.trim();

    if (inputCode.isEmpty) {
      setState(() => codeError = "Enter the verification code");
      return;
    }

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where(widget.userEmailOrPhone.contains('@') ? 'email' : 'phone',
              isEqualTo: widget.userEmailOrPhone)
          .get();

      if (querySnapshot.docs.isEmpty) {
        setState(() => codeError = "User not found");
        return;
      }

      final userDoc = querySnapshot.docs.first;
      final storedOtp = userDoc['otp'] ?? '';

      if (inputCode != storedOtp) {
        setState(() => codeError = "Invalid code");
        return;
      }

      // OTP verified → Navigate to Reset Password screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ResetPasswordScreen(userEmailOrPhone: widget.userEmailOrPhone),
        ),
      );
    } catch (e) {
      setState(() => codeError = "Error verifying code");
    }
  }

  Future<void> resendCode() async {
    try {
      // Generate new 6-digit OTP securely
      String otp = (100000 + DateTime.now().millisecondsSinceEpoch % 900000)
          .toString()
          .padLeft(6, '0');

      final querySnapshot = await _firestore
          .collection('users')
          .where(widget.userEmailOrPhone.contains('@') ? 'email' : 'phone',
              isEqualTo: widget.userEmailOrPhone)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final userDoc = querySnapshot.docs.first;
      await _firestore.collection('users').doc(userDoc.id).update({'otp': otp});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("New OTP sent: $otp (demo only)")),
      );

      startTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error sending OTP")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        title: const Text(
          "Verification Code",
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
            /// Gradient Card
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
                  Icon(Icons.verified, size: 55, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    "Enter the 6-digit code sent to your account",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            TextFormField(
              controller: codeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Verification Code",
                prefixIcon: const Icon(Icons.pin),
                errorText: codeError,
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Resend Code in $timerSeconds s",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                TextButton(
                  onPressed: timerSeconds == 0 ? resendCode : null,
                  child: Text(
                    "Resend",
                    style: TextStyle(
                      color: timerSeconds == 0 ? Colors.deepPurple : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 5,
                ),
                child:
                    const Text("Verify", style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}