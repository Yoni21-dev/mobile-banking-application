import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecurityService {
  // Hash a password
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Compare hashed password
  static bool verifyPassword(String inputPassword, String storedHash) {
    return hashPassword(inputPassword) == storedHash;
  }
}