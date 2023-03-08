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

  Future<AuthResponse> initializeAuthentication() async {
    if (amplify != null) {
      AuthSession _session = await amplify!.Auth.fetchAuthSession();
      return AuthResponse(isAuthenticated: _session.isSignedIn);
    }
    return AuthResponse(isAuthenticated: false, error: 'Something went wrong');
  }

  Future<AuthResponse> createUserWithEmailAndPassword({
    required String username,
    required String email,
    required String password,
    required String name,
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
            username: username,
            password: password,
            options: CognitoSignUpOptions(
                userAttributes: <CognitoUserAttributeKey, String>{
                  CognitoUserAttributeKey.email: email,
                  CognitoUserAttributeKey.name: name,
                }));
        // _result.nextStep;
        return AuthResponse(
            isAuthenticated: _result.isSignUpComplete,
            nextStep: true,
            logs: {
              'isAuthenticated': _result.isSignUpComplete,
              'results': _result.nextStep
            });
      } on UsernameExistsException catch (e) {
        return AuthResponse(
          isAuthenticated: false,
          error: 'Username is taken',
          logs: {'message': e.toString()},
        );
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

  Future<AuthResponse> resendConfirmationCode(String username) async {
    try {
      ResendSignUpCodeResult _result =
          await amplify!.Auth.resendSignUpCode(username: username);
      return AuthResponse(
          isAuthenticated: false,
          nextStep: true,
          logs: {'codeDeleuveryDetails': _result.codeDeliveryDetails});
    } catch (e) {
      return AuthResponse(
          isAuthenticated: false,
          nextStep: false,
          error: 'Unable to send the confirmation code.',
          logs: {'message': e.toString()});
    }
  }

  Future<AuthResponse> forgotPassword(String username) async {
    if (amplify != null) {
      try {
        ResetPasswordResult _result =
            await amplify!.Auth.resetPassword(username: username);
        return AuthResponse(
            isAuthenticated: false, isPasswordReset: _result.isPasswordReset);
      } on InvalidParameterException catch (e) {
        return AuthResponse(
          isAuthenticated: false,
          error: 'Make sure your username is valid',
          logs: {'message': e.toString()},
        );
      } catch (e) {
        return AuthResponse(
            isAuthenticated: false,
            error: 'Some error',
            logs: {'message': e.toString()});
      }
    }
    return AuthResponse(isAuthenticated: false, error: 'Something went wrong');
  }

  Future<AuthResponse> resetPasswordVerification({
    required String username,
    required String password,
    required String verificationCode,
  }) async {
    try {
      await amplify!.Auth.confirmResetPassword(
          username: username,
          newPassword: password,
          confirmationCode: verificationCode);
      return AuthResponse(
        isAuthenticated: false,
        isPasswordReset: true,
        error: 'Password has been successfully reset.',
      );
    } catch (e) {
      return AuthResponse(
          isAuthenticated: false,
          error: 'Some error',
          logs: {'message': e.toString()});
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

  Future<AuthDebugger> clearUsersData() async {
    if (sharedPreferences != null) {
      SharedPreferences _sharedPrefs = await SharedPreferences.getInstance();
      _sharedPrefs.clear();
      return AuthDebugger(response: true, message: 'User data deleted');
    } else if (amplify != null) {
      try {
        await amplify!.Auth.deleteUser();
        return AuthDebugger(response: true, message: 'User data deleted');
      } catch (e) {
        return AuthDebugger(response: false, error: e.toString());
      }
    } else {
      return AuthDebugger(response: false, error: 'Something went wrong');
    }
  }

  Future<AuthResponse> signInWithEmailAndPassword({
    // required String email,
    required String password,
    required String username,
  }) async {
    SharedPreferences? _sharedPref = await sharedPreferences;
    if (_sharedPref != null) {
      try {
        List<String> _users = _sharedPref.getStringList('users') ?? <String>[];
        List<Map<String, dynamic>> _usersDecoded =
            _users.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

        Map<String, dynamic>? _user = _usersDecoded.singleWhere(
            (element) => element['username'] == username,
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
            await amplify!.Auth.signIn(username: username, password: password);
        // _result.nextStep;
        return AuthResponse(
            isAuthenticated: _result.isSignedIn,
            logs: {'result': _result.toString()});
      } on UserNotConfirmedException catch (e) {
        AuthResponse _response = await resendConfirmationCode(username);
        return AuthResponse(
          isAuthenticated: false,
          nextStep: true,
          error: 'User not confirmed',
          logs: {
            'message': e.toString(),
            'codeDeliveryDetails': _response.logs?['codeDeleuveryDetails'],
          },
        );
      } on UserNotFoundException catch (e) {
        return AuthResponse(
          isAuthenticated: false,
          error: 'User not found',
          logs: {'message': e.toString()},
        );
      } catch (e) {
        log(e.toString());
        return AuthResponse(
          isAuthenticated: false,
          error: 'Caught an error',
          logs: {'message': e.toString()},
        );
      }
    } else {
      return AuthResponse(
          isAuthenticated: false, logs: {'error': 'Something went wrong'});
    }
  }

  Future<void> signOut() async {
    if (amplify != null) {
      await amplify!.Auth.signOut();
    }
  }
}

class AuthResponse {
  final bool isAuthenticated;
  final bool nextStep;
  final bool? isPasswordReset;
  final String? error;
  final Map<String, dynamic>? logs;

  AuthResponse({
    required this.isAuthenticated,
    this.nextStep = false,
    this.isPasswordReset = false,
    this.error,
    this.logs,
  });
}

class AuthDebugger {
  final bool? response;
  final String? message;
  final String? error;

  AuthDebugger({
    this.response,
    this.message,
    this.error,
  });
}
