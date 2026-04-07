import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/pin_dialog.dart';

class TransferScreen extends StatefulWidget {
  const TransferScreen({super.key});

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final accountController = TextEditingController();
  final amountController = TextEditingController();

  String? accountError;
  String? amountError;
  String? receiverName;

  @override
  void dispose() {
    accountController.dispose();
    amountController.dispose();
    super.dispose();
  }

  Future<void> handleTransfer(String accountNumber, double amount) async {
    try {
      String? name = await ApiService.findAccountName(accountNumber);

      if (name == null) {
        setState(() => accountError = "Account not found");
        return;
      }

      String result = await ApiService.transfer(accountNumber, amount);

      if (!mounted) return;

      if (result == "Invalid account number") {
        setState(() => accountError = result);
      } else if (result == "Insufficient balance") {
        setState(() => amountError = result);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Transfer successful to $name")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Transfer failed: $e")),
      );
    }
  }

  void onTransferPressed() {
    String accountNumber = accountController.text.trim();
    double? amount = double.tryParse(amountController.text.trim());

    setState(() {
      accountError = null;
      amountError = null;
    });

    if (accountNumber.isEmpty) {
      setState(() => accountError = "Enter account number");
      return;
    }

    if (amount == null || amount <= 0) {
      setState(() => amountError = "Enter valid amount");
      return;
    }

    showDialog(
      context: context,
      builder: (_) => PinDialog(
        onVerified: () async {
          await handleTransfer(accountNumber, amount);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        title: const Text(
          "Transfer Money",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),

      /// 🔥 BODY
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  /// Top Card
                  Container(
                    padding: const EdgeInsets.all(25),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [Color(0xff396afc), Color(0xff2948ff)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200,
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.send, size: 55, color: Colors.white),
                        SizedBox(height: 12),
                        Text(
                          "Send money securely",
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  /// Account Input
                  TextField(
                    controller: accountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Receiver Account Number",
                      errorText: accountError,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) async {
                      if (ApiService.isValidAccountNumber(value)) {
                        String? name =
                            await ApiService.findAccountName(value);
                        setState(() => receiverName = name);
                      } else {
                        setState(() => receiverName = null);
                      }
                    },
                  ),

                  if (receiverName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Receiver: $receiverName",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                  const SizedBox(height: 20),

                  /// Amount Input
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Amount",
                      errorText: amountError,
                      prefixIcon: const Icon(Icons.money),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 18, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  /// 🔥 Spacer pushes content up when keyboard opens
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),

      /// 🔥 FIXED BUTTON
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.of(context).viewInsets.bottom + 15,
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 5,
              ),
              onPressed: onTransferPressed,
              child: const Text(
                "Transfer Now",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}