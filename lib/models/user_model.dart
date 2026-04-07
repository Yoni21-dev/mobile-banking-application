import 'account_model.dart';
import 'transaction_model.dart';

class UserModel {
  String fullName;
  String email;
  String phone;
  String password;
  String pin;
  bool blocked;
  AccountModel account;
  List<TransactionModel> transactions;
  String? idImagePath;

  UserModel({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.pin,
    this.blocked = false,
    required this.account,
    this.transactions = const [],
    this.idImagePath,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      password: map['password'] ?? '',
      pin: map['pin'] ?? '',
      blocked: map['blocked'] ?? false,
      account: AccountModel(
        accountNumber: map['accountNumber'] ?? '',
        balance: (map['balance'] ?? 0).toDouble(),
      ),
      idImagePath: map['idImagePath'] ?? '',
      transactions: map['transactions'] != null
          ? List<TransactionModel>.from(
              (map['transactions'] as List).map(
                (t) => TransactionModel.fromMap(t),
              ),
            )
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'password': password,
      'pin': pin,
      'blocked': blocked,
      'accountNumber': account.accountNumber,
      'balance': account.balance,
      'idImagePath': idImagePath ?? '',
      'transactions': transactions.map((t) => t.toMap()).toList(),
    };
  }
}

