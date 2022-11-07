import 'dart:convert';
import 'dart:developer';

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class AuthenticationRepository {
  final Future<SharedPreferences>? sharedPreferences;
  final AmplifyClass? amplify;

  AuthenticationRepository({this.amplify, this.sharedPreferences});
  AuthenticationRepository.sharedPreferences(this.sharedPreferences,
      {this.amplify});
  AuthenticationRepository.amplify(this.amplify, {this.sharedPreferences});

  Future<AuthResponse> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    SharedPreferences? _sharedPref = await sharedPreferences;
    if (sharedPreferences != null) {
      try {
        List<String> _users = _sharedPref!.getStringList('users') ?? <String>[];

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
        return AuthResponse(
            isAuthenticated: false,
            logs: {'error': 'Shared Preferences error'});
      }
    } else if (amplify != null) {
      try {
        SignUpResult _result = await amplify!.Auth.signUp(
            username: email,
            password: password,
            options: CognitoSignUpOptions(
                userAttributes: <CognitoUserAttributeKey, String>{
                  CognitoUserAttributeKey.email: email
                }));
        _result.nextStep;
        return AuthResponse(
            isAuthenticated: _result.isSignUpComplete,
            nextStep: true,
            logs: {
              'isAuthenticated': _result.isSignUpComplete,
              'results': _result.nextStep
            });
      } catch (e) {
        log(e.toString());
        return AuthResponse(
            isAuthenticated: false, logs: {'error': 'Amplify error'});
      }
    } else {
      return AuthResponse(
          isAuthenticated: false, logs: {'error': 'Something went wrong!'});
    }
  }

  Future<AuthResponse> confirmSignUp({
    required String username,
    required String confirmationCode,
  }) async {
    try {
      SignUpResult _result = await amplify!.Auth.confirmSignUp(
          username: username, confirmationCode: confirmationCode);
      return AuthResponse(isAuthenticated: _result.isSignUpComplete, logs: {
        'isAuthenticated': _result.isSignUpComplete,
        'message': _result.nextStep
      });
    } catch (e) {
      return AuthResponse(
          isAuthenticated: false, logs: {'error': e.toString()});
    }
  }

  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    SharedPreferences? _sharedPref = await sharedPreferences;
    if (_sharedPref != null) {
      try {
        List<String> _users = _sharedPref.getStringList('users') ?? <String>[];
        List<Map<String, dynamic>> _usersDecoded =
            _users.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

        Map<String, dynamic>? _user = _usersDecoded.singleWhere(
            (element) => element['email'] == email,
            orElse: () => {});

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
      } catch (e) {
        log(e.toString());
        return AuthResponse(
            isAuthenticated: false,
            logs: {'error': 'Shared Preferences error.'});
      }
    } else if (amplify != null) {
      try {
        SignInResult _result =
            await amplify!.Auth.signIn(username: email, password: password);
        return AuthResponse(
            isAuthenticated: _result.isSignedIn,
            logs: {'result': _result.toString()});
      } catch (e) {
        log(e.toString());
        return AuthResponse(
            isAuthenticated: false, logs: {'error': 'Amplify error'});
      }
    } else {
      return AuthResponse(
          isAuthenticated: false, logs: {'error': 'Something went wrong'});
    }
  }
}

class AuthResponse {
  final bool isAuthenticated;
  final bool nextStep;
  final Map<String, dynamic>? logs;

  AuthResponse(
      {required this.isAuthenticated, this.nextStep = false, this.logs});
}
