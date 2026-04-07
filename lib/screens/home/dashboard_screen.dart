import 'package:flutter/material.dart';
//import 'dart:io';
import '../../services/api_service.dart';
//import '../account/deposit_screen.dart';
import '../account/withdraw_screen.dart';
import '../account/transfer_screen.dart';
import '../account/balance_screen.dart';
import '../account/history_screen.dart';
import '../auth/login_screen.dart';
import '../profile/id_preview_screen.dart';
import '../../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void refresh() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    restoreSession();
  }

  Future<void> restoreSession() async {
    if (ApiService.currentUser != null) return;

    final prefs = await SharedPreferences.getInstance();
    final savedUser = prefs.getString('loggedUser');

    if (savedUser != null) {
      await ApiService.restoreUser(savedUser);
      setState(() {});
    }
  }

  void openScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen)).then((
      _,
    ) {
      refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "Main Account",
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),

            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();

              await prefs.remove('loggedUser');

              ApiService.logout();

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeaderCard(user),

              const SizedBox(height: 25),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.05,
                  padding: const EdgeInsets.only(
                    bottom: 16,
                  ), // Added extra bottom padding
                  physics:
                      const BouncingScrollPhysics(), // Allows scrolling when keyboard is open
                  children: [
                    _buildCard(
                      Icons.remove_circle,
                      "Withdraw",
                      Colors.orange,
                      () => openScreen(const WithdrawScreen()),
                    ),
                    _buildCard(
                      Icons.send,
                      "Transfer",
                      Colors.blue,
                      () => openScreen(const TransferScreen()),
                    ),
                    _buildCard(
                      Icons.account_balance_wallet,
                      "Balance",
                      Colors.purple,
                      () => openScreen(const BalanceScreen()),
                    ),
                    _buildCard(
                      Icons.history,
                      "History",
                      Colors.red,
                      () => openScreen(const HistoryScreen()),
                    ),
                    _buildCard(Icons.credit_card, "View ID", Colors.teal, () {
                      if (user.idImagePath != null &&
                          user.idImagePath!.isNotEmpty) {
                        openScreen(
                          IDPreviewScreen(idImagePath: user.idImagePath!),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("No ID uploaded")),
                        );
                      }
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xff1e3c72), Color(0xff2a5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (user.idImagePath != null &&
                      user.idImagePath!.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            IDPreviewScreen(idImagePath: user.idImagePath!),
                      ),
                    );
                  }
                },
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white,

                  backgroundImage:
                      (user.idImagePath != null && user.idImagePath!.isNotEmpty)
                      ? NetworkImage(user.idImagePath!)
                      : null,

                  child: (user.idImagePath == null || user.idImagePath!.isEmpty)
                      ? const Icon(Icons.person, size: 30, color: Colors.grey)
                      : null,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 22),

          const Text(
            "Available Balance",
            style: TextStyle(color: Colors.white70),
          ),

          const SizedBox(height: 8),

          Text(
            "${user.account.balance.toStringAsFixed(2)} Birr",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            "Account: ${user.account.accountNumber}",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, size: 32, color: color),
            ),

            const SizedBox(height: 14),

            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
