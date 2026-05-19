
import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {

  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;

    return Scaffold(

      appBar: AppBar(
        title: const Text("Help & Support"),
      ),

      body: Center(

        child: Container(

          width: isTablet ? 500 : double.infinity,

          padding: const EdgeInsets.all(16),

          child: ListView(

            children: const [

              _HelpTile(
                title: "How to use camera?",
                subtitle: "Open Camera tab and capture photo",
              ),

              _HelpTile(
                title: "How geo tagging works?",
                subtitle: "App saves GPS location with image",
              ),

              _HelpTile(
                title: "Contact support",
                subtitle: "Devopsaksentt@gmail.com",
              ),

            ],

          ),

        ),

      ),

    );

  }

}

class _HelpTile extends StatelessWidget {

  final String title;
  final String subtitle;

  const _HelpTile({

    required this.title,
    required this.subtitle,

  });

  @override
  Widget build(BuildContext context) {

    return Card(

      margin: const EdgeInsets.symmetric(vertical: 6),

      child: ListTile(

        title: Text(title),

        subtitle: Text(subtitle),

      ),

    );

  }

}