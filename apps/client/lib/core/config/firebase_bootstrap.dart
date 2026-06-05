import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Inicializa Firebase.
///
/// Após criar o projeto no Console, execute:
/// `flutterfire configure --project=rayssa-delivery-dev`
/// e descomente o import de [DefaultFirebaseOptions].
class FirebaseBootstrap {
  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) return;

    // ignore: avoid_print
    if (kDebugMode) {
      print(
        '[Rayssa] Configure Firebase com flutterfire e '
        'substitua FirebaseBootstrap por DefaultFirebaseOptions.',
      );
    }

    await Firebase.initializeApp();
  }
}
