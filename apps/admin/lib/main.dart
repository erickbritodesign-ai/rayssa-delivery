import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rayssa_admin/app.dart';
import 'package:rayssa_admin/core/config/firebase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await FirebaseBootstrap.initialize();
  runApp(const ProviderScope(child: RayssaAdminApp()));
}
