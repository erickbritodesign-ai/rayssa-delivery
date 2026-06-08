import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rayssa_core/rayssa_core.dart';

class AuthRemoteDatasource {
  AuthRemoteDatasource({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> createUserProfile({
    required String uid,
    required String name,
    required String phone,
    required String email,
  }) {
    final user = UserModel(
      id: uid,
      name: name,
      email: email,
      phone: phone,
      role: UserRole.customer,
      createdAt: DateTime.now(),
    );
    return _firestore
        .collection(FirestoreCollections.usuarios)
        .doc(uid)
        .set(user.toFirestore());
  }

  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _firestore
        .collection(FirestoreCollections.usuarios)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc.id, doc.data()!);
  }

  Future<void> signOut() => _auth.signOut();
}
