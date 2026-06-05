import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_core/rayssa_core.dart';

final adminAuthStateProvider = Provider<AdminAuthListenable>((ref) {
  return AdminAuthListenable(ref);
});

class AdminAuthListenable extends ChangeNotifier {
  AdminAuthListenable(this._ref) {
    _ref.listen(adminSessionProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  bool get isAuthenticated {
    final session = _ref.read(adminSessionProvider).valueOrNull;
    return session?.role == UserRole.admin;
  }
}

final adminSessionProvider = StreamProvider<UserModel?>((ref) async* {
  await for (final user in FirebaseAuth.instance.authStateChanges()) {
    if (user == null) {
      yield null;
      continue;
    }
    final doc = await FirebaseFirestore.instance
        .collection(FirestoreCollections.usuarios)
        .doc(user.uid)
        .get();
    if (!doc.exists) {
      yield null;
      continue;
    }
    yield UserModel.fromFirestore(doc.id, doc.data()!);
  }
});

final adminAuthControllerProvider =
    StateNotifierProvider<AdminAuthController, AsyncValue<void>>((ref) {
  return AdminAuthController();
});

class AdminAuthController extends StateNotifier<AsyncValue<void>> {
  AdminAuthController() : super(const AsyncData(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection(FirestoreCollections.usuarios)
          .doc(uid)
          .get();
      final profile =
          doc.exists ? UserModel.fromFirestore(doc.id, doc.data()!) : null;
      if (profile?.role != UserRole.admin) {
        await FirebaseAuth.instance.signOut();
        throw StateError('Acesso restrito a administradores');
      }
    });
  }

  Future<void> signOut() => FirebaseAuth.instance.signOut();
}
