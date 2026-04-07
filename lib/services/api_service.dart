import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert'; 
class ApiService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static UserModel? currentUser;
  static String? currentUserDocId;
  static String? currentOtp;
  static int pinAttempts = 0;

  static String generateAccountNumber() {
    return "1000${Random().nextInt(9000000) + 1000000}";
  }
  

  static bool isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

 static List<Map<String, dynamic>> users = [];
  static String hashPassword(String input) {
    return sha256.convert(utf8.encode(input.trim())).toString();
  }

  static Future<String> register(
  String name,
  String email,
  String phone,
  String password,
  String pin,
  double initialAmount,
  String? idImagePath,
) async {
  try {
    // Validate email/phone
    if (email.isEmpty && phone.isEmpty) {
      return "Enter a valid email or Ethiopian phone";
    }

    // Check deposit
    if (initialAmount <= 50) return "Initial deposit must be greater than 50 Birr";

    // Hash password and pin
    String hashedPassword = hashPassword(password);
    String hashedPin = hashPassword(pin);

    // Check existing user in Firestore
    final emailQuery = email.isNotEmpty
        ? await _firestore.collection('users').where('email', isEqualTo: email).get()
        : await _firestore.collection('users').where('email', isEqualTo: "__none__").get();

    final phoneQuery = phone.isNotEmpty
        ? await _firestore.collection('users').where('phone', isEqualTo: phone).get()
        : await _firestore.collection('users').where('phone', isEqualTo: "__none__").get();

    if (emailQuery.docs.isNotEmpty || phoneQuery.docs.isNotEmpty) {
      return "User already exists";
    }

    // Generate account number
    String accountNumber = generateAccountNumber();

    // Save user to Firestore
    final docRef = await _firestore.collection('users').add({
      'fullName': name.trim(),
      'email': email,
      'phone': phone,
      'password': hashedPassword,
      'pin': hashedPin,
      'blocked': false,
      'accountNumber': accountNumber,
      'balance': initialAmount,
      'idImagePath': idImagePath ?? '',
      'transactions': [],
    });

    // Save locally for offline usage (optional)
    users.add({
      'fullName': name.trim(),
      'email': email,
      'phone': phone,
      'password': hashedPassword,
      'pin': hashedPin,
      'blocked': false,
      'accountNumber': accountNumber,
      'balance': initialAmount,
      'idImagePath': idImagePath ?? '',
      'transactions': [],
    });

    return "Account created\nAccount No: $accountNumber";
  } catch (e, st) {
    print("REGISTER ERROR: $e\n$st"); // <-- prints exact Firestore error
    return "Registration failed: ${e.toString()}"; // <-- more informative
  }
}static Future<String> login(String emailOrPhone, String password) async {
  try {
    // Hash the input password
    String hashedInput = hashPassword(password);

    // First try finding by email
    final emailQuery = await _firestore
        .collection('users')
        .where('email', isEqualTo: emailOrPhone)
        .get();

    // If not found by email, try phone
    final phoneQuery = emailQuery.docs.isEmpty
        ? await _firestore
            .collection('users')
            .where('phone', isEqualTo: emailOrPhone)
            .get()
        : emailQuery;

    if (phoneQuery.docs.isEmpty) return "Invalid credentials";

    final doc = phoneQuery.docs.first;
    final data = doc.data();

    // Compare hashed password
    if (data['password'] != hashedInput) return "Invalid credentials";

    if (data['blocked'] == true) return "Account blocked";

    currentUserDocId = doc.id;

    // Load transactions
    List<TransactionModel> loadedTransactions = [];
    if (data['transactions'] != null) {
      for (var tx in data['transactions']) {
        loadedTransactions.add(TransactionModel(
          type: tx['type'],
          amount: (tx['amount'] as num).toDouble(),
          date: tx['date'],
          receiverAccount: tx['receiverAccount'],
        ));
      }
    }

    currentUser = UserModel(
      fullName: data['fullName'],
      email: data['email'],
      phone: data['phone'],
      password: data['password'],
      pin: data['pin'],
      blocked: data['blocked'],
      idImagePath: data['idImagePath'],
      account: AccountModel(
        accountNumber: data['accountNumber'],
        balance: (data['balance'] as num).toDouble(),
      ),
    );

    currentUser!.transactions = loadedTransactions;

    return "Login successful";
  } catch (e) {
    print("LOGIN ERROR: $e");
    return "Login failed";
  }
}

  static Future<bool> verifyPin(String inputPin) async {
  if (currentUser == null || currentUserDocId == null) return false;

  // Hash the entered PIN
  String hashedInput = hashPassword(inputPin);

  // Check if PIN matches
  if (currentUser!.pin == hashedInput) {
    pinAttempts = 0; // reset attempts on success
    return true;
  }

  // Increment wrong attempts
  pinAttempts++;

  // If 3 or more failed attempts, block account
  if (pinAttempts >= 3) {
    currentUser!.blocked = true;

    try {
      await _firestore.collection('users').doc(currentUserDocId).update({
        'blocked': true,
      });
    } catch (e) {
      print("Error blocking user: $e");
    }
  }

  return false;
}

  static Future<void> deposit(double amount) async {
    
     if (amount <= 0) return;
    if (currentUserDocId == null) return;

    currentUser!.account.balance += amount;

    final tx = {
      'type': 'Deposit',
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
    };

    currentUser!.transactions.add(
      TransactionModel(
        type: 'Deposit',
        amount: amount,
        date: DateTime.now().toIso8601String(),
      ),
    );

    await _firestore.collection('users').doc(currentUserDocId).update({
      'balance': currentUser!.account.balance,
      'transactions': FieldValue.arrayUnion([tx]),
    });
  }

  static Future<bool> withdraw(double amount) async {
    if (amount <= 0) return false;
    if (currentUser!.account.balance < amount || currentUserDocId == null) {
      return false;
    }

    currentUser!.account.balance -= amount;

    final tx = {
      'type': 'Withdraw',
      'amount': amount,
      'date': DateTime.now().toIso8601String(),
    };

    currentUser!.transactions.add(
      TransactionModel(
        type: 'Withdraw',
        amount: amount,
        date: DateTime.now().toIso8601String(),
      ),
    );

    await _firestore.collection('users').doc(currentUserDocId).update({
      'balance': currentUser!.account.balance,
      'transactions': FieldValue.arrayUnion([tx]),
    });

    return true;
  }



  static Future<String> transfer(String accountNumber, double amount) async {
    if (amount <= 0) return "Invalid amount";
    final receiverQuery = await _firestore
        .collection('users')
        .where('accountNumber', isEqualTo: accountNumber)
        .get();

    if (receiverQuery.docs.isEmpty) {
      return "Account not found";
    }

    if (currentUser!.account.balance < amount) {
      return "Insufficient balance";
    }
    if (accountNumber == currentUser!.account.accountNumber) {
  return "Cannot transfer to your own account";
}

    final receiverDoc = receiverQuery.docs.first;

    currentUser!.account.balance -= amount;

    final tx = {
      'type': 'Transfer',
      'amount': amount,
      'receiverAccount': accountNumber,
      'date': DateTime.now().toIso8601String(),
    };

    currentUser!.transactions.add(
      TransactionModel(
        type: 'Transfer',
        amount: amount,
        date: DateTime.now().toIso8601String(),
        receiverAccount: accountNumber,
      ),
    );

    await _firestore.runTransaction((transaction) async {
      transaction.update(
        _firestore.collection('users').doc(currentUserDocId),
        {
          'balance': currentUser!.account.balance,
          'transactions': FieldValue.arrayUnion([tx]),
        },
      );

      double receiverBalance =
          (receiverDoc['balance'] as num).toDouble() + amount;

      transaction.update(receiverDoc.reference, {
        'balance': receiverBalance,
      });
    });

    return "Transfer successful";
  }

  static Future<String?> findAccountName(String accountNumber) async {
    final query = await _firestore
        .collection('users')
        .where('accountNumber', isEqualTo: accountNumber)
        .get();

    if (query.docs.isEmpty) return null;

    return query.docs.first['fullName'];
  }

  static bool isValidAccountNumber(String accountNumber) {
    return accountNumber.startsWith("1000") &&
        accountNumber.length == 11 &&
        RegExp(r'^[0-9]+$').hasMatch(accountNumber);
  }

  static String generateOtp() {
    final otp =
        (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();

    currentOtp = otp;
    return otp;
  }

  static bool verifyOtp(String code) {
    return code == currentOtp;
  }

  static Future<void> updatePassword(
      String emailOrPhone, String newPassword) async {
    final query = await _firestore.collection('users').get();

    for (var doc in query.docs) {
      if (doc['email'] == emailOrPhone || doc['phone'] == emailOrPhone) {
        await doc.reference.update({
          'password': newPassword,
        });
      }
    }
  }

  static void logout() {
    currentUser = null;
    currentUserDocId = null;
  }
static Future<bool> restoreUser(String emailOrPhone) async {
  final query = await _firestore.collection('users').get();

  for (var doc in query.docs) {
    final data = doc.data();

    if (data['email'] == emailOrPhone || data['phone'] == emailOrPhone) {
      currentUserDocId = doc.id;

      List<TransactionModel> loadedTransactions = [];

      if (data['transactions'] != null) {
        for (var tx in data['transactions']) {
          loadedTransactions.add(
            TransactionModel(
              type: tx['type'],
              amount: (tx['amount'] as num).toDouble(),
              date: tx['date'],
              receiverAccount: tx['receiverAccount'],
            ),
          );
        }
      }

      currentUser = UserModel(
        fullName: data['fullName'],
        email: data['email'],
        phone: data['phone'],
        password: data['password'],
        pin: data['pin'],
        blocked: data['blocked'],
        idImagePath: data['idImagePath'],
        account: AccountModel(
          accountNumber: data['accountNumber'],
          balance: (data['balance'] as num).toDouble(),
        ),
      );

      currentUser!.transactions = loadedTransactions;

      return true;
    }
  }

  return false;
}

}



