import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

typedef StudentLogin = Future<void> Function(String email, String password);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLogin});

  final StudentLogin onLogin;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'student@campus.com');
  final _passwordController = TextEditingController();
  String _selectedRole = 'ESTUDIANTE';
  bool _isBusy = false;
  bool _showPassword = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      await widget.onLogin(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: CampusColors.indigo,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Campus Connect',
                      style: TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: CampusColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Acceso por perfil',
                      style: TextStyle(fontSize: 16, color: CampusColors.muted),
                    ),
                    const SizedBox(height: 30),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Perfil de prueba',
                        prefixIcon: Icon(Icons.people_outline_rounded),
                      ),
                      items: _demoAccounts
                          .map(
                            (account) => DropdownMenuItem(
                              value: account.role,
                              child: Text(account.label),
                            ),
                          )
                          .toList(),
                      onChanged: (role) {
                        final account = _demoAccounts.firstWhere(
                          (item) => item.role == role,
                        );
                        setState(() {
                          _selectedRole = account.role;
                          _emailController.text = account.email;
                          _passwordController.text = account.password;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Correo electrónico',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (value) {
                        if (value == null || !value.contains('@')) {
                          return 'Ingresa un correo válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_showPassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          tooltip: _showPassword
                              ? 'Ocultar contraseña'
                              : 'Mostrar contraseña',
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingresa tu contraseña'
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      ),
                    ],
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isBusy ? null : _submit,
                        icon: _isBusy
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.login_rounded),
                        label: Text(
                          _isBusy ? 'Ingresando...' : 'Iniciar sesión',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CampusColors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Selecciona un perfil para completar las credenciales de prueba.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: CampusColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoAccount {
  const _DemoAccount({
    required this.role,
    required this.label,
    required this.email,
    required this.password,
  });

  final String role;
  final String label;
  final String email;
  final String password;
}

const _demoAccounts = [
  _DemoAccount(
    role: 'ESTUDIANTE',
    label: 'Estudiante',
    email: 'student@campus.com',
    password: 'student123',
  ),
  _DemoAccount(
    role: 'DOCENTE',
    label: 'Docente',
    email: 'teacher@campus.com',
    password: 'teacher123',
  ),
  _DemoAccount(
    role: 'ACUDIENTE',
    label: 'Acudiente',
    email: 'parent@campus.com',
    password: 'parent123',
  ),
  _DemoAccount(
    role: 'DIRECTIVO',
    label: 'Directivo',
    email: 'director@campus.com',
    password: 'admin123',
  ),
];
