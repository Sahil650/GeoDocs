
import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {

  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;

    return Scaffold(

      appBar: AppBar(
        title: const Text("Privacy"),
      ),

      body: Center(

        child: Container(

          width: isTablet ? 500 : double.infinity,

          padding: const EdgeInsets.all(16),

          child: const Text(

            "Your data is securely stored.\n\n"
            "GeoDocs App only accesses location for geo-tagging photos.\n\n"
            "We do not share your personal data.",

            style: TextStyle(fontSize: 16),

          ),

        ),

      ),

    );

  }

}