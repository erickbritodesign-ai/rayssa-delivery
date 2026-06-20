import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rayssa_admin/app.dart';
import 'package:rayssa_admin/core/config/firebase_bootstrap.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final skipFirebase = Uri.base.queryParameters['skipFirebase'] == '1';
  if (skipFirebase) {
    runApp(
      _FirebaseDiagnosticApp(
        appName: 'Admin',
        currentUrl: Uri.base.toString(),
      ),
    );
    return;
  }

  runApp(const ProviderScope(child: _FirebaseBootstrapApp()));
}

class _FirebaseBootstrapApp extends StatefulWidget {
  const _FirebaseBootstrapApp();

  @override
  State<_FirebaseBootstrapApp> createState() => _FirebaseBootstrapAppState();
}

class _FirebaseBootstrapAppState extends State<_FirebaseBootstrapApp> {
  bool _ready = false;
  Object? _error;
  StackTrace? _stack;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await initializeDateFormatting('pt_BR', null);
      await FirebaseBootstrap.initialize();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (error, stack) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _stack = stack;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const RayssaAdminApp();
    if (_error != null) {
      return _FirebaseBootstrapErrorApp(
        error: _error!,
        stack: _stack,
        currentUrl: Uri.base.toString(),
      );
    }
    return const _FirebaseLoadingApp(appName: 'Admin');
  }
}

class _FirebaseLoadingApp extends StatelessWidget {
  const _FirebaseLoadingApp({required this.appName});

  final String appName;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'Carregando $appName...',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black, fontSize: 20),
          ),
        ),
      ),
    );
  }
}

class _FirebaseBootstrapErrorApp extends StatelessWidget {
  const _FirebaseBootstrapErrorApp({
    required this.error,
    required this.stack,
    required this.currentUrl,
  });

  final Object error;
  final StackTrace? stack;
  final String currentUrl;

  @override
  Widget build(BuildContext context) {
    final details = [
      'Tipo: ${error.runtimeType}',
      '',
      'Erro:',
      error.toString(),
      '',
      'Stack:',
      stack?.toString() ?? 'sem stack',
      '',
      'URL:',
      currentUrl,
    ].join('\n');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Erro ao iniciar Firebase',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Envie este print para o suporte.',
                  style: TextStyle(color: Colors.black, fontSize: 17),
                ),
                const SizedBox(height: 20),
                SelectableText(
                  details,
                  style: const TextStyle(
                    color: Colors.black,
                    fontFamily: 'monospace',
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FirebaseDiagnosticApp extends StatelessWidget {
  const _FirebaseDiagnosticApp({
    required this.appName,
    required this.currentUrl,
  });

  final String appName;
  final String currentUrl;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Diagnostico iOS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'App abriu sem Firebase',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black, fontSize: 20),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'skipFirebase=1',
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'App: $appName',
                    style: const TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    'URL: $currentUrl',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
