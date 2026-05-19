import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettings extends ChangeNotifier {

  bool darkMode = false;

  bool notifications = true;

  String language = "English";

  Future loadSettings() async {

    final prefs =
        await SharedPreferences.getInstance();

    darkMode =
        prefs.getBool("darkMode") ?? false;

    notifications =
        prefs.getBool("notifications") ?? true;

    language =
        prefs.getString("language") ??
            "English";

    notifyListeners();

  }

  Future setDarkMode(bool value) async {

    darkMode = value;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
        "darkMode", value);

    notifyListeners();

  }

  Future setNotifications(bool value) async {

    notifications = value;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
        "notifications", value);

    notifyListeners();

  }

  Future setLanguage(String value) async {

    language = value;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setString(
        "language", value);

    notifyListeners();

  }

}