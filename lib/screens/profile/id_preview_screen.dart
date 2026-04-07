import 'package:flutter/material.dart';
import 'dart:io';

class IDPreviewScreen extends StatelessWidget {
  final String idImagePath;

  const IDPreviewScreen({super.key, required this.idImagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f7fb),
      appBar: AppBar(
        title: const Text(
          "National ID Preview",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade300,
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: idImagePath.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(12),
                          child: Text(
                            "Tap / Pinch to Zoom",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        Expanded(
                          child: InteractiveViewer(
                            panEnabled: true,
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: _buildImage(), // 🔥 FIX HERE
                          ),
                        ),
                      ],
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.all(30),
                    child: Text(
                      "No ID uploaded",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  /// 🔥 SMART IMAGE LOADER (MAIN FIX)
  Widget _buildImage() {
    // 👉 If it's a network image (Firebase URL)
    if (idImagePath.startsWith('http')) {
      return Image.network(
        idImagePath,
        fit: BoxFit.contain,
        width: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Text(
              "Failed to load image",
              style: TextStyle(color: Colors.red),
            ),
          );
        },
      );
    }

    // 👉 Otherwise it's a local file
    final file = File(idImagePath);

    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Text(
              "Invalid file",
              style: TextStyle(color: Colors.red),
            ),
          );
        },
      );
    }

    // 👉 If path is wrong
    return const Center(
      child: Text(
        "Image not found",
        style: TextStyle(color: Colors.red),
      ),
    );
  }
}