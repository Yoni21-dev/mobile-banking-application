import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PinDialog extends StatefulWidget {
  final VoidCallback onVerified;

  const PinDialog({super.key, required this.onVerified});

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final TextEditingController pinController = TextEditingController();
  String? error;
  bool verifying = false;

  Future<void> verify() async {
    if (verifying) return; // prevent multiple taps

    setState(() {
      verifying = true;
      error = null;
    });

    // Check if account already blocked
    if (ApiService.currentUser?.blocked == true) {
      setState(() {
        error = "Account is blocked!";
        verifying = false;
      });
      return;
    }

    // Verify the PIN
    bool valid = await ApiService.verifyPin(pinController.text);

    if (valid) {
      // Close dialog and continue
      Navigator.pop(context);
      widget.onVerified();
    } else {
      setState(() {
        if (ApiService.currentUser?.blocked == true) {
          error = "Account blocked after 3 wrong PINs!";
        } else {
          error = "Incorrect PIN (${ApiService.pinAttempts}/3)";
        }
        verifying = false;
      });
    }
  }

  @override
  void dispose() {
    pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text("Enter PIN"),
      content: TextField(
        controller: pinController,
        obscureText: true,
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.done,
        maxLength: 4,
        decoration: InputDecoration(
          labelText: "4 Digit PIN",
          errorText: error,
        ),
        onSubmitted: (_) => verify(),
      ),
      actions: [
        TextButton(
          onPressed: verifying ? null : () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: verifying ? null : verify,
          child: verifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text("Verify"),
        ),
      ],
    );
  }
}