import 'package:flutter_riverpod/flutter_riverpod.dart';

// TODO: persistir com shared_preferences quando a dependência local for adicionada.
final darkThemeEnabledProvider = StateProvider<bool>((ref) => false);
