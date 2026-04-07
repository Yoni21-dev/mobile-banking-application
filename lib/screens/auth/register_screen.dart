// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final emailOrPhone = TextEditingController();
  final password = TextEditingController();
  final pin = TextEditingController();
  final amount = TextEditingController();

  File? idImage;
  final ImagePicker picker = ImagePicker();

  bool _obscurePassword = true;
  bool _obscurePin = true;
  bool loading = false;

  String hashString(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }

  Future<void> pickIdImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          idImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("PICK IMAGE ERROR: $e");
      showMsg("Failed to pick image");
    }
  }

  Future<String?> uploadIdToCloudinary(File image) async {
    const cloudName = 'dl34jbpv1';
    const uploadPreset = 'id_upload';

    final url =
        Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    try {
      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', image.path));

      final response = await request.send();
      final resStr = await response.stream.bytesToString();
      final data = json.decode(resStr);

      if (response.statusCode == 200) {
        return data['secure_url'];
      } else {
        showMsg("Upload failed: ${data['error']['message']}");
        return null;
      }
    } catch (e) {
      showMsg("Upload error: $e");
      return null;
    }
  }

  Future<void> register() async {
    if (name.text.isEmpty ||
        emailOrPhone.text.isEmpty ||
        password.text.isEmpty ||
        pin.text.isEmpty ||
        amount.text.isEmpty) {
      showMsg("All fields are required");
      return;
    }

    if (idImage == null) {
      showMsg("Upload National ID / Kebele ID");
      return;
    }

    String input = emailOrPhone.text.trim();
    final ethiopianPhoneRegex = RegExp(r'^(09|011)\d{8}$');
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

    if (!ethiopianPhoneRegex.hasMatch(input) &&
        !emailRegex.hasMatch(input)) {
      showMsg("Enter valid email or Ethiopian phone");
      return;
    }

    if (!RegExp(r'^\d{4}$').hasMatch(pin.text)) {
      showMsg("PIN must be 4 digits");
      return;
    }

    if (!ApiService.isStrongPassword(password.text)) {
      showMsg("Password must be 8+ chars, uppercase, number");
      return;
    }

    double? initialAmount = double.tryParse(amount.text);

    if (initialAmount == null) {
      showMsg("Invalid amount");
      return;
    }

    setState(() {
      loading = true;
    });

    String? idUrl = await uploadIdToCloudinary(idImage!);

    if (idUrl == null) {
      setState(() {
        loading = false;
      });
      showMsg("ID upload failed");
      return;
    }

  String email = emailRegex.hasMatch(input) ? input.trim().toLowerCase() : "";
  String phone = ethiopianPhoneRegex.hasMatch(input) ? input.trim() : "";

if (email.isEmpty && phone.isEmpty) {
  showMsg("Enter a valid email or Ethiopian phone");
  return;
}

String result = await ApiService.register(
  name.text.trim(),
  email,
  phone,
  password.text.trim(),
  pin.text.trim(),
  initialAmount,
  idUrl,
);

    setState(() {
      loading = false;
    });

    showMsg(result);

    if (!result.contains("exists") &&
        !result.contains("greater") &&
        !result.contains("failed")) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  InputDecoration fieldStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Create Account"),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Colors.green,
                child: Icon(
                  Icons.account_balance,
                  size: 45,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              TextField(
                controller: name,
                decoration: fieldStyle("Full Name", Icons.person),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: emailOrPhone,
                decoration: fieldStyle("Email or Phone", Icons.email),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Upload National ID / Kebele ID",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              idImage == null
                  ? Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Center(
                        child: Text("No ID uploaded"),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.file(
                        idImage!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => pickIdImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Take Photo"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => pickIdImage(ImageSource.gallery),
                      icon: const Icon(Icons.upload),
                      label: const Text("Upload ID"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: password,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: pin,
                obscureText: _obscurePin,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "4 Digit PIN",
                  prefixIcon: const Icon(Icons.pin),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePin
                        ? Icons.visibility
                        : Icons.visibility_off),
                    onPressed: () {
                      setState(() {
                        _obscurePin = !_obscurePin;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: amount,
                keyboardType: TextInputType.number,
                decoration:
                    fieldStyle("Initial Deposit (>50 Birr)", Icons.money),
              ),
              const SizedBox(height: 25),
              loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: register,
                      child: const Text(
                        "Register",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}