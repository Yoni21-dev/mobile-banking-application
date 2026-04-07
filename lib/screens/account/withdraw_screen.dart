import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/pin_dialog.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final amountController = TextEditingController();
  String? amountError;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<void> handleWithdraw(double amount) async {
    try {
      // Check if user is blocked
      if (ApiService.currentUser?.blocked ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account is blocked!")),
        );
        return;
      }

      bool success = await ApiService.withdraw(amount);

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Withdraw Successful")),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Insufficient Balance")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Withdrawal failed: $e")),
      );
    }
  }

  void onWithdrawPressed() {
    double? amount = double.tryParse(amountController.text.trim());

    setState(() {
      amountError = null;
    });

    if (amount == null || amount <= 0) {
      setState(() {
        amountError = "Enter valid amount";
      });
      return;
    }

    // Show PIN dialog before proceeding
    showDialog(
      context: context,
      builder: (_) => PinDialog(
        onVerified: () async {
          await handleWithdraw(amount);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
return Scaffold(
  backgroundColor: const Color(0xfff5f7fb),
  resizeToAvoidBottomInset: true,

  appBar: AppBar(
    title: const Text(
      "Withdraw Money",
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    centerTitle: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    foregroundColor: Colors.black87,
  ),

  /// 🔥 BODY (NO BUTTON HERE)
  body: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// Top Card
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(
              colors: [
                Color(0xfff7971e),
                Color(0xffffd200),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.shade200,
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            children: [
              Icon(Icons.money_off, size: 55, color: Colors.white),
              SizedBox(height: 12),
              Text(
                "Withdraw from your account",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),

        const SizedBox(height: 35),

        /// Amount Field
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Withdraw Amount",
            errorText: amountError,
            prefixIcon: const Icon(Icons.money_off),
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
      ],
    ),
  ),

  /// 🔥 FIXED BUTTON (KEY PART)
  bottomNavigationBar: AnimatedPadding(
    duration: const Duration(milliseconds: 200),
    padding: EdgeInsets.fromLTRB(
      20,
      10,
      20,
      MediaQuery.of(context).viewInsets.bottom + 15, // 🔥 moves with keyboard
    ),
    child: SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 5,
          ),
          onPressed: onWithdrawPressed,
          child: const Text(
            "Confirm Withdraw",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    ),
  ),
);
  }
}