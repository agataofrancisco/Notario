import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../shared/widgets/app_components.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true; // true = login, false = register
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleEmailAuth() {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    if (_isLogin) {
      context.read<AuthBloc>().add(
            AuthEmailLoginRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    } else {
      context.read<AuthBloc>().add(
            AuthEmailRegisterRequested(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              displayName: _nameController.text.trim(),
            ),
          );
    }
  }

  void _handleGoogleSignIn() {
    setState(() => _isLoading = true);
    context.read<AuthBloc>().add(const AuthGoogleLoginRequested());
  }

  void _showResetPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar Senha'),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            hintText: 'Digite seu email',
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (emailController.text.trim().isNotEmpty) {
                context.read<AuthBloc>().add(
                      AuthPasswordResetRequested(emailController.text.trim()),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
          }
          if (state is AuthPasswordResetSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Email de recuperação enviado! Verifique sua caixa de entrada.'),
                backgroundColor: Colors.green,
              ),
            );
          }
          if (state is AuthLoading) {
            setState(() => _isLoading = true);
          }
          if (state is AuthAuthenticated || state is AuthUnauthenticated) {
            setState(() => _isLoading = false);
          }
        },
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.calendar_today_rounded,
                        size: 42,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const AppPageHeader(
                      title: 'NOTÁRIO',
                      subtitle: 'Motor de Disciplina',
                      centered: true,
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 28),

                    // Card de Login/Registro
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                            color:
                                Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Toggle Login/Register
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () =>
                                          setState(() => _isLogin = true),
                                      style: TextButton.styleFrom(
                                        backgroundColor: _isLogin
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.transparent,
                                        foregroundColor: _isLogin
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        'Entrar',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () =>
                                          setState(() => _isLogin = false),
                                      style: TextButton.styleFrom(
                                        backgroundColor: !_isLogin
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Colors.transparent,
                                        foregroundColor: !_isLogin
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimary
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: const Text(
                                        'Registrar',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Nome (apenas para registro)
                              if (!_isLogin) ...[
                                TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nome',
                                    prefixIcon: Icon(Icons.person),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Digite seu nome';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],

                              // Email
                              TextFormField(
                                controller: _emailController,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.email),
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Digite seu email';
                                  }
                                  if (!value.contains('@')) {
                                    return 'Email inválido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Senha
                              TextFormField(
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: 'Senha',
                                  prefixIcon: const Icon(Icons.lock),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                    ),
                                    onPressed: () {
                                      setState(() =>
                                          _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                ),
                                obscureText: _obscurePassword,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Digite sua senha';
                                  }
                                  if (!_isLogin && value.length < 6) {
                                    return 'Senha deve ter pelo menos 6 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),

                              // Esqueceu a senha?
                              if (_isLogin)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _showResetPasswordDialog,
                                    child: const Text('Esqueceu a senha?'),
                                  ),
                                ),
                              const SizedBox(height: 16),

                              // Botão de Login/Registro
                              ElevatedButton(
                                onPressed: _isLoading ? null : _handleEmailAuth,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: _isLoading
                                    ? Semantics(
                                        liveRegion: true,
                                        label: _isLogin
                                            ? 'A entrar na conta'
                                            : 'A criar a conta',
                                        child: const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            semanticsLabel: 'A processar',
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _isLogin ? 'Entrar' : 'Criar Conta',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                      child: Divider(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outlineVariant)),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'OU',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant),
                                    ),
                                  ),
                                  Expanded(
                                      child: Divider(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outlineVariant)),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Botão Google (Opcional)
                              OutlinedButton.icon(
                                onPressed:
                                    _isLoading ? null : _handleGoogleSignIn,
                                icon: const Icon(Icons.login, size: 20),
                                label: Semantics(
                                  label: _isLoading
                                      ? 'A entrar com Google'
                                      : 'Entrar com Google',
                                  child: const Text('Entrar com Google'),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Versão
                    Text(
                      'v1.0.0',
                      style: Theme.of(context).textTheme.bodySmall,
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
