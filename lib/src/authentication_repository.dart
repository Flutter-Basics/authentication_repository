import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthenticationRepository {
  Future<bool> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      SharedPreferences _sharedPref = await SharedPreferences.getInstance();
      List<String> _users = _sharedPref.getStringList('users') ?? <String>[];

      Map<String, String> _user = {
        'id': const Uuid().v4(),
        'email': email,
        'password': password
      };

      _sharedPref.setStringList('users', [..._users, jsonEncode(_user)]);

      await Future.delayed(const Duration(seconds: 5));
      return true;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      SharedPreferences _sharedPref = await SharedPreferences.getInstance();

      List<String> _users = _sharedPref.getStringList('users') ?? <String>[];
      List<Map<String, String>> _usersDecoded =
          _users.map((e) => jsonDecode(e) as Map<String, String>).toList();

      Map<String, String> _user =
          _usersDecoded.firstWhere((element) => element['email'] == email);
      if (_user.isNotEmpty) {
        await Future.delayed(const Duration(seconds: 5));
        return true;
      }
      return false;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }
}
