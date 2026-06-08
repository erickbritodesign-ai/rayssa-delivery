import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rayssa_client/core/theme/app_theme.dart';
import 'package:rayssa_client/core/widgets/ray_brand.dart';
import 'package:rayssa_client/features/auth/presentation/providers/auth_providers.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).signIn(
          _emailController.text.trim(),
          _passwordController.text,
        );
    final error = ref.read(authControllerProvider).error;
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyAuthErrorMessage(error))),
      );
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim().isNotEmpty
        ? _emailController.text.trim()
        : await _askPasswordResetEmail();

    if (email == null || email.trim().isEmpty) return;

    await ref
        .read(authControllerProvider.notifier)
        .sendPasswordResetEmail(email.trim());

    final error = ref.read(authControllerProvider).error;
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Enviamos um link de recuperação para seu e-mail. Verifique também a caixa de spam.'
              : friendlyAuthErrorMessage(error),
        ),
      ),
    );
  }

  Future<String?> _askPasswordResetEmail() async {
    final controller = TextEditingController(text: _emailController.text.trim());
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar senha'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'E-mail',
            prefixIcon: Icon(Icons.mail_outline),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: dark ? AppTheme.darkSurface : AppTheme.cream,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: dark
                ? const [
                    AppTheme.darkSurface,
                    AppTheme.darkCard,
                    AppTheme.darkSurface,
                  ]
                : [
                    AppTheme.cream,
                    AppTheme.blush.withOpacity(0.45),
                    AppTheme.warmWhite,
                  ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
                  decoration: BoxDecoration(
                    color: dark
                        ? AppTheme.darkCard.withOpacity(0.96)
                        : AppTheme.warmWhite.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: dark ? AppTheme.darkLine : AppTheme.line,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.chocolate.withOpacity(dark ? 0.34 : 0.1),
                        blurRadius: 28,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.chocolate,
                                AppTheme.deepRed,
                                AppTheme.primaryRed,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: RayBrandMark(
                              size: 74,
                              showWordmark: false,
                              onDark: true,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Lanchonete da Ray',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontSize: 30),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Pastelaria artesanal',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: dark
                                        ? AppTheme.darkMuted
                                        : AppTheme.muted,
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) => value == null || value.isEmpty
                              ? 'Informe o e-mail'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              tooltip: _obscurePassword
                                  ? 'Mostrar senha'
                                  : 'Ocultar senha',
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          validator: (value) => value == null || value.length < 6
                              ? 'Mínimo 6 caracteres'
                              : null,
                        ),
                        Center(
                          child: TextButton(
                            onPressed:
                                authState.isLoading ? null : _resetPassword,
                            child: const Text('Esqueci minha senha'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: authState.isLoading ? null : _submit,
                          child: authState.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Entrar'),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.push('/register'),
                          child: const Text('Criar conta'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
