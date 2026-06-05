import 'package:rayssa_client/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:rayssa_client/features/auth/domain/repositories/auth_repository.dart';
import 'package:rayssa_core/rayssa_core.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._datasource);

  final AuthRemoteDatasource _datasource;

  @override
  Stream<UserModel?> watchCurrentUser() async* {
    await for (final firebaseUser in _datasource.authStateChanges()) {
      if (firebaseUser == null) {
        yield null;
        continue;
      }
      yield await _datasource.fetchUser(firebaseUser.uid);
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = await _datasource.authStateChanges().first;
    if (firebaseUser == null) return null;
    return _datasource.fetchUser(firebaseUser.uid);
  }

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _datasource.signInWithEmail(email: email, password: password);
  }

  @override
  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final credential = await _datasource.registerWithEmail(
      email: email,
      password: password,
    );
    final uid = credential.user!.uid;
    await _datasource.createUserProfile(
      uid: uid,
      name: name,
      phone: phone,
      email: email,
    );
  }

  @override
  Future<void> signOut() => _datasource.signOut();
}
