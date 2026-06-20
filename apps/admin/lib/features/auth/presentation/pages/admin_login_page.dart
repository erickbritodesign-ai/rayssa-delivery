import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rayssa_admin/features/auth/presentation/providers/admin_auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _keepConnected = true;

  @override
  void initState() {
    super.initState();
    _loadRememberedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (kIsWeb) {
      try {
        await FirebaseAuth.instance.setPersistence(
          _keepConnected ? Persistence.LOCAL : Persistence.SESSION,
        );
      } catch (_) {
        // O login continua mesmo se o navegador bloquear o armazenamento.
      }
    }
    await ref.read(adminAuthControllerProvider.notifier).signIn(
          email,
          _passwordController.text,
        );
    final error = ref.read(adminAuthControllerProvider).error;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
      return;
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      if (_keepConnected) {
        await preferences.setString('admin.rememberedEmail', email);
      } else {
        await preferences.remove('admin.rememberedEmail');
      }
    } catch (_) {
      // SharedPreferences é apenas conveniência; a sessão do Firebase continua.
    }
  }

  Future<void> _loadRememberedEmail() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final email = preferences.getString('admin.rememberedEmail');
      if (!mounted || email == null || email.isEmpty) return;
      setState(() {
        _emailController.text = email;
        _keepConnected = true;
      });
    } catch (_) {
      // Sem plugin/storage disponível, o login abre normalmente sem e-mail.
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminAuthControllerProvider);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Rayssa Admin',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'E-mail'),
                  autofillHints: const [AutofillHints.username],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) {
                    if (!state.isLoading) _submit();
                  },
                ),
                CheckboxListTile(
                  value: _keepConnected,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('Manter conectado'),
                  subtitle: const Text(
                    'O e-mail e a sessão ficam salvos neste aparelho.',
                  ),
                  onChanged: state.isLoading
                      ? null
                      : (value) {
                          setState(() => _keepConnected = value ?? true);
                        },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _submit,
                    child: state.isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Entrar'),
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
