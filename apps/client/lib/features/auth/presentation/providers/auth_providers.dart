import 'package:firebase_auth/firebase_auth.dart';
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

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.sendPasswordResetEmail(email),
    );
  }

  Future<void> signOut() => _repository.signOut();
}

String friendlyAuthErrorMessage(Object? error) {
  final code =
      error is FirebaseAuthException ? error.code : _codeFromRawError(error);

  switch (code) {
    case 'invalid-email':
      return 'Digite um e-mail válido.';
    case 'wrong-password':
    case 'invalid-credential':
      return 'Senha incorreta.';
    case 'user-not-found':
      return 'Não encontramos uma conta com este e-mail.';
    case 'email-already-in-use':
      return 'Este e-mail já está cadastrado.';
    case 'weak-password':
      return 'Use uma senha mais forte.';
    case 'network-request-failed':
      return 'Verifique sua conexão e tente novamente.';
    default:
      return 'Não foi possível concluir. Tente novamente.';
  }
}

String? _codeFromRawError(Object? error) {
  final text = error?.toString() ?? '';
  final match = RegExp(r'\[firebase_auth/([^\]]+)\]').firstMatch(text);
  return match?.group(1);
}
