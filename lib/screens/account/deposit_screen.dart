/*import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/pin_dialog.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final amountController = TextEditingController();
  String? amountError;

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<void> handleDeposit(double amount) async {
    try {
      // Make sure user is not blocked
      if (ApiService.currentUser?.blocked ?? false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account is blocked!")),
        );
        return;
      }

      await ApiService.deposit(amount);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Deposit Successful")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deposit failed: $e")),
      );
    }
  }

  void onDepositPressed() {
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

    // Show PIN dialog for verification
    showDialog(
      context: context,
      builder: (_) => PinDialog(
        onVerified: () async {
          await handleDeposit(amount);
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
      "Deposit Money",
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
                Color(0xff11998e),
                Color(0xff38ef7d),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade200,
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            children: [
              Icon(Icons.account_balance_wallet,
                  size: 55, color: Colors.white),
              SizedBox(height: 12),
              Text(
                "Deposit into your account",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ],
          ),
        ),

        const SizedBox(height: 35),

        /// Amount Input
        TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Deposit Amount",
            errorText: amountError,
            prefixIcon: const Icon(Icons.money),
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

  /// 🔥 FIXED BUTTON (PERFECT SOLUTION)
  bottomNavigationBar: AnimatedPadding(
    duration: const Duration(milliseconds: 200),
    padding: EdgeInsets.fromLTRB(
      20,
      10,
      20,
      MediaQuery.of(context).viewInsets.bottom + 15, // 🔥 magic line
    ),
    child: SafeArea(
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 5,
          ),
          onPressed: onDepositPressed,
          child: const Text(
            "Confirm Deposit",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    ),
  ),
);
  }
}
*/