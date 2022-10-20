import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthenticationRepository {
  final Future<SharedPreferences> sharedPreferences;

  AuthenticationRepository({required this.sharedPreferences});

  Future<AuthResponse> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      SharedPreferences _sharedPref = await sharedPreferences;
      List<String> _users = _sharedPref.getStringList('users') ?? <String>[];

      Map<String, String> _user = {
        'id': const Uuid().v4(),
        'email': email,
        'password': password
      };

      _sharedPref.setStringList('users', [..._users, jsonEncode(_user)]);

      await Future.delayed(const Duration(seconds: 5));
      return AuthResponse(isAuthenticated: true, logs: {
        '_users': _users,
        '_user': _user,
        '_userEncoded': jsonEncode(_user)
      });
    } catch (e) {
      log(e.toString());
      return AuthResponse(isAuthenticated: false, logs: {'error': e});
    }
  }

  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    // try {
    //   SharedPreferences _sharedPref = await sharedPreferences;
    //   List<String> _users = _sharedPref.getStringList('users') ?? <String>[];
    //   List<Map<String, dynamic>> _usersDecoded =
    //       _users.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    //   Map<String, dynamic>? _user =
    //       _usersDecoded.firstWhere((element) => element['email'] == email);

    //   if (_user.isNotEmpty) {
    //     await Future.delayed(const Duration(seconds: 5));
    //     return AuthResponse(isAuthenticated: true, logs: {
    //       '_users': _users,
    //       '_usersDecoded': _usersDecoded,
    //       '_user': _user
    //     });
    //   }
    //   return AuthResponse(isAuthenticated: false, logs: {
    //     'message': 'User not found!',
    //     '_users': _users,
    //     '_usersDecoded': _usersDecoded,
    //     '_user': _user
    //   });
    // } catch (e) {
    //   // log(e.toString());
    //   return AuthResponse(isAuthenticated: false, logs: {'error': e});
    // }

    SharedPreferences _sharedPref = await sharedPreferences;
    List<String> _users = _sharedPref.getStringList('users') ?? <String>[];
    List<Map<String, dynamic>> _usersDecoded =
        _users.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

    Map<String, dynamic>? _user = _usersDecoded
        .singleWhere((element) => element['email'] == email, orElse: () => {});

    if (_user.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 5));
      return AuthResponse(isAuthenticated: true, logs: {
        '_users': _users,
        '_usersDecoded': _usersDecoded,
        '_user': _user
      });
    }
    return AuthResponse(isAuthenticated: false, logs: {
      'message': 'User not found!',
      '_users': _users,
      '_usersDecoded': _usersDecoded,
      '_user': _user
    });
  }
}

class AuthResponse {
  final bool isAuthenticated;
  final Map<String, dynamic>? logs;

  AuthResponse({required this.isAuthenticated, this.logs});
}
