import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactions = ApiService.currentUser?.transactions.reversed.toList() ?? [];

    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),

      appBar: AppBar(
        title: const Text(
          "Transaction History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),

      body: transactions.isEmpty
          ? const Center(
              child: Text(
                "No Transactions Yet",
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];

                IconData icon;
                Color color;

                switch (tx.type) {
                  case "Deposit":
                    icon = Icons.arrow_downward;
                    color = Colors.green;
                    break;
                  case "Withdraw":
                    icon = Icons.arrow_upward;
                    color = Colors.orange;
                    break;
                  default:
                    icon = Icons.send;
                    color = Colors.blue;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),

                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),

                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: color.withOpacity(0.12),
                      child: Icon(icon, color: color),
                    ),

                    title: Text(
                      tx.type,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),

                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        tx.formattedDate,
                        style: const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),

                    trailing: Text(
                      "${tx.amount.toStringAsFixed(2)} Birr",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}