
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {

  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;

    return Scaffold(

      appBar: AppBar(
        title: const Text("About App"),
      ),

      body: Center(

        child: Container(

          width: isTablet ? 500 : double.infinity,

          padding: const EdgeInsets.all(16),

          child: const Column(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Text(
                "Geo Fusion App",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 10),

              Text("Version 1.0"),

              SizedBox(height: 20),

              Text(
                "GeoDocs helps capture photos with GPS location "
                "and convert them into documents.",
                style: TextStyle(fontSize: 16),
              ),

            ],

          ),

        ),

      ),

    );

  }

}