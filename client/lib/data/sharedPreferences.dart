import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveCredential(String username, String password) async {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final SharedPreferences prefs = await _prefs;
  prefs.setString("username", username);
  prefs.setString("password", password);
  prefs.setBool("isLogged", true);
}

Future<void> logOut() async {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final SharedPreferences prefs = await _prefs;
  prefs.setString("username", "");
  prefs.setString("password", "");
  prefs.setBool("isLogged", false);
}

Future<String> getUsername() async {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final SharedPreferences prefs = await _prefs;
  bool test = prefs.getBool('test');
  print(test);
  return prefs.getString('username');
}

Future<String> getPassword() async {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final SharedPreferences prefs = await _prefs;
  return prefs.getString('password');
}

Future<bool> isLogged() async {
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final SharedPreferences prefs = await _prefs;
  bool isLogged = prefs.getBool('isLogged');
  if (isLogged == null) {
    return false;
  } else {
    return isLogged;
  }
}
