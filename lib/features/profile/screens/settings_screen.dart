
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../profile/services/app_settings.dart';

class SettingsScreen extends StatelessWidget {

  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {

    final settings = context.watch<AppSettings>();

    final width = MediaQuery.of(context).size.width;
    final isTablet = width > 600;

    return Scaffold(

      appBar: AppBar(
        title: const Text("Settings"),
      ),

      body: Center(

        child: Container(

          width: isTablet ? 500 : double.infinity,

          padding: const EdgeInsets.all(16),

          child: ListView(

            children: [

              _card(

                ListTile(

                  leading: const Icon(Icons.language),

                  title: const Text("Language"),

                  subtitle: Text(settings.language),

                  onTap: () => _languageDialog(context),

                ),

              ),

              _card(

                SwitchListTile(

                  secondary: const Icon(Icons.notifications),

                  title: const Text("Notifications"),

                  value: settings.notifications,

                  onChanged: settings.setNotifications,

                ),

              ),

              _card(

                SwitchListTile(

                  secondary: const Icon(Icons.dark_mode),

                  title: const Text("Dark Mode"),

                  value: settings.darkMode,

                  onChanged: settings.setDarkMode,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

  Widget _card(Widget child) {

    return Card(

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      margin: const EdgeInsets.symmetric(vertical: 6),

      child: child,

    );

  }

  void _languageDialog(BuildContext context) {

    final settings = context.read<AppSettings>();

    showDialog(

      context: context,

      builder: (_) {

        return AlertDialog(

          title: const Text("Language"),

          content: Column(

            mainAxisSize: MainAxisSize.min,

            children: [

              ListTile(

                title: const Text("English"),

                onTap: () {

                  settings.setLanguage("English");

                  Navigator.pop(context);

                },

              ),

              

            ],

          ),

        );

      },

    );

  }

}