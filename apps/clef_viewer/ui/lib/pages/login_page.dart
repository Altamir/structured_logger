import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/clef_design_system.dart';
import '../theme/clef_theme.dart';
import '../widgets/version_bar.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onSuccess;

  const LoginPage({super.key, required this.onSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _auth = AuthService();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _auth.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      widget.onSuccess();
    } on InvalidCredentialsException {
      if (!mounted) return;
      setState(() => _error = 'Usuário ou senha inválidos');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Não foi possível conectar ao servidor');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CLEF Viewer - Login',
      theme: buildClefTheme(),
      home: Scaffold(
        backgroundColor: ClefDs.appleGrayBg,
        body: Column(
          children: [
            const VersionBar(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Card(
                    margin: const EdgeInsets.all(ClefDs.spaceXl),
                    child: Padding(
                      padding: const EdgeInsets.all(ClefDs.spaceXl),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'CLEF Viewer',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: ClefDs.spaceSm),
                            Text(
                              'Entre para acessar o visualizador de logs',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: ClefDs.appleTextSecondary),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: ClefDs.spaceXl),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Usuário',
                                border: OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.next,
                              enabled: !_loading,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe o usuário';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: ClefDs.spaceLg),
                            TextFormField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Senha',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              enabled: !_loading,
                              onFieldSubmitted: (_) => _submit(),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe a senha';
                                }
                                return null;
                              },
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: ClefDs.spaceLg),
                              Text(
                                _error!,
                                style: const TextStyle(color: ClefDs.appleRed),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: ClefDs.spaceXl),
                            FilledButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Entrar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}