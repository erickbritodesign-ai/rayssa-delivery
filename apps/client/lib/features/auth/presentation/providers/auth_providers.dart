import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_client/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:rayssa_client/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:rayssa_client/features/auth/domain/repositories/auth_repository.dart';
import 'package:rayssa_core/rayssa_core.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(AuthRemoteDatasource());
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUser();
});

class AuthStateListenable extends ChangeNotifier {
  AuthStateListenable(this._ref) {
    _ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  bool get isAuthenticated {
    final user = _ref.read(currentUserProvider).valueOrNull;
    return user != null;
  }

  UserModel? get currentUser {
    return _ref.read(currentUserProvider).valueOrNull;
  }

  bool get canAccessTableService {
    return currentUser?.canAccessTableService ?? false;
  }
}

final authStateProvider = Provider<AuthStateListenable>((ref) {
  return AuthStateListenable(ref);
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._repository) : super(const AsyncData(null));

  final AuthRepository _repository;

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.signInWithEmail(email: email, password: password),
    );
  }

  Future<void> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.register(
        name: name,
        phone: phone,
        email: email,
        password: password,
      ),
    );
  }

  Future<void> signOut() => _repository.signOut();
}
