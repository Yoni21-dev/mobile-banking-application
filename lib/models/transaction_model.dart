import 'package:intl/intl.dart';

class TransactionModel {
  String type;
  double amount;
  String date;
  String? receiverAccount;

  TransactionModel({
    required this.type,
    required this.amount,
    required this.date,
    this.receiverAccount,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      type: map['type'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: map['date'] ?? '',
      receiverAccount: map['receiverAccount'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'date': date,
      'receiverAccount': receiverAccount ?? '',
    };
  }

  String get formattedDate {
    try {
      DateTime dt = DateTime.parse(date);
      return DateFormat("dd MMM yyyy HH:mm").format(dt);
    } catch (e) {
      return date;
    }
  }
}

