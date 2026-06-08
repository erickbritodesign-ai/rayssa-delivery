import 'package:rayssa_core/rayssa_core.dart';

abstract class AuthRepository {
  Stream<UserModel?> watchCurrentUser();
  Future<UserModel?> getCurrentUser();
  Future<void> signInWithEmail(
      {required String email, required String password});
  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
}
