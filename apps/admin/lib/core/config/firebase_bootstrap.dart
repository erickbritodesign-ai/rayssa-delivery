import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseBootstrap {
  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;

    if (kDebugMode) {
      // ignore: avoid_print
      print('[Rayssa Admin] Configure Firebase com flutterfire configure.');
    }

    await Firebase.initializeApp();
  }
}
