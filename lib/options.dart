import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class Options extends ChangeNotifier {
  String session = "";
  ThemeMode themeMode = ThemeMode.light;

  void load() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    session = prefs.getString('session').toString();

    if (session.isEmpty) changeSession(const Uuid().v1().toString());

    notifyListeners();
  }

  changeSession(String session) {
    session = session;
    save();
    notifyListeners();
  }

  Future<void> save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('session', session);
  }
}
