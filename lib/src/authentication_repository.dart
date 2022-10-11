class AuthenticationRepository {
  Future<bool> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 5));
    return true;
  }

  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await Future.delayed(const Duration(seconds: 5));
    return true;
  }
}
