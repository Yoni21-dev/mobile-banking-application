import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static UserModel? currentUser;
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
      // Validate inputs
      if (email.isEmpty) {
        return "Enter a valid email";
      }

      if (initialAmount <= 50) {
        return "Initial deposit must be greater than 50 Birr";
      }

      if (!isStrongPassword(password)) {
        return "Password must be 8+ chars, uppercase, number";
      }

      // Create Firebase Auth user
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      // Generate account number
      String accountNumber = generateAccountNumber();

      // Create user profile in Firestore using Firebase UID
      await _firestore.collection('users').doc(uid).set({
        'fullName': name.trim(),
        'email': email,
        'phone': phone,
        'pin': pin,
        'blocked': false,
        'accountNumber': accountNumber,
        'balance': initialAmount,
        'idImagePath': idImagePath ?? '',
        'transactions': [],
      });

      return "Account created\nAccount No: $accountNumber";
    } on FirebaseAuthException catch (e) {
      return "Registration failed: ${e.message}";
    } catch (e) {
      print("REGISTER ERROR: $e");
      return "Registration failed: ${e.toString()}";
    }
  }

  static Future<String> login(String email, String password) async {
    try {
      // Sign in with Firebase Auth
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user!.uid;

      // Fetch user profile from Firestore
      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        return "User profile not found";
      }

      final data = doc.data()!;

      if (data['blocked'] == true) {
        return "Account blocked";
      }

      // Load transactions
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
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return "Invalid credentials";
      } else if (e.code == 'wrong-password') {
        return "Invalid credentials";
      } else {
        return "Login failed: ${e.message}";
      }
    } catch (e) {
      print("LOGIN ERROR: $e");
      return "Login failed";
    }
  }

  static Future<bool> verifyPin(String inputPin) async {
    if (currentUser == null) return false;

    // Check if PIN matches
    if (currentUser!.pin == inputPin) {
      pinAttempts = 0;
      return true;
    }

    // Increment wrong attempts
    pinAttempts++;

    // If 3 or more failed attempts, block account
    if (pinAttempts >= 3) {
      currentUser!.blocked = true;

      try {
        final uid = _auth.currentUser?.uid;
        if (uid != null) {
          await _firestore.collection('users').doc(uid).update({
            'blocked': true,
          });
        }
      } catch (e) {
        print("Error blocking user: $e");
      }
    }

    return false;
  }

  /* static Future<void> deposit(double amount) async {
    
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
  } */

  static Future<bool> withdraw(double amount) async {
    if (amount <= 0) return false;
    if (currentUser!.account.balance < amount) {
      return false;
    }

    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

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

    await _firestore.collection('users').doc(uid).update({
      'balance': currentUser!.account.balance,
      'transactions': FieldValue.arrayUnion([tx]),
    });

    return true;
  }

  static Future<String> transfer(String accountNumber, double amount) async {
    if (amount <= 0) return "Invalid amount";

    final uid = _auth.currentUser?.uid;
    if (uid == null) return "Not authenticated";

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
      transaction.update(_firestore.collection('users').doc(uid), {
        'balance': currentUser!.account.balance,
        'transactions': FieldValue.arrayUnion([tx]),
      });

      double receiverBalance =
          (receiverDoc['balance'] as num).toDouble() + amount;

      transaction.update(receiverDoc.reference, {'balance': receiverBalance});
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
    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString();

    currentOtp = otp;
    return otp;
  }

  static bool verifyOtp(String code) {
    return code == currentOtp;
  }

  static Future<void> updatePassword(
    String emailOrPhone,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
    } catch (e) {
      print("Error updating password: $e");
    }
  }

  static void logout() {
    currentUser = null;
    _auth.signOut();
  }

  static Future<bool> restoreUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists) return false;

      final data = doc.data()!;

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
    } catch (e) {
      print("Error restoring user: $e");
      return false;
    }
  }
}
