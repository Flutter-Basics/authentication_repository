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
      print('--- Debugging ---');
      print('');
      print(_users);
      print('');
      print(' --- ');
      print('');

      Map<String, String> _user = {
        'id': const Uuid().v4(),
        'email': email,
        'password': password
      };
      print(_user);
      print('');
      print(' --- ');
      print('');
      print(jsonEncode(_user));
      print('');
      print(' --- End --- ');

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

      print('--- Debugging ---');
      print(_users);
      print('');
      print(' --- ');
      print('');
      print(_usersDecoded);
      print('');
      print(' --- ');
      print('');

      Map<String, String> _user =
          _usersDecoded.firstWhere((element) => element['email'] == email);

      print(_user);
      print('');
      print(' --- End --- ');

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
