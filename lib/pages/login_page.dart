import 'package:flutter/material.dart';
import 'package:proyecto006/models/user.dart';
import 'package:proyecto006/pages/home_page.dart';
import 'package:proyecto006/services/api_service.dart';
import 'package:proyecto006/services/auth_service.dart';
import 'package:proyecto006/widgets/create_user_modal.dart';
import 'dart:async'; // Importar para usar Timer

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAdminButtonEnabled = false;

  Timer? _debounceTimer; // Timer para el debouncing

  // Método para verificar si el usuario es Super Usuario (con debouncing)
  void _onCredentialsChanged() {
    // Si los campos de usuario y contraseña están vacíos, deshabilitar el botón inmediatamente
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) {
        setState(() {
          _isAdminButtonEnabled = false;
          _isLoading =
              false; // Asegurarse de que el indicador de carga se oculte
        });
      }
      _debounceTimer?.cancel(); // Cancelar cualquier timer pendiente
      return;
    }

    // Cancelar el timer anterior si existe
    _debounceTimer?.cancel();
    // Iniciar un nuevo timer
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      // Ejecutar la verificación solo después de 500ms de inactividad
      _checkSuperUserCredentials();
    });
  }

  Future<void> _checkSuperUserCredentials() async {
    if (!mounted) return; // Asegurarse de que el widget está montado

    setState(() {
      _isLoading = true; // Mostrar carga
      _errorMessage = null;
    });

    try {
      final User tempUser = await _apiService.login(
        _usernameController.text,
        _passwordController.text,
      );

      if (mounted) {
        setState(() {
          _isAdminButtonEnabled = (tempUser.role == 'Super Usuario');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isAdminButtonEnabled =
              false; // Deshabilitar si falla la verificación
        });
      }
      print('Error en _checkSuperUserCredentials: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Ocultar carga
        });
      }
    }
  }

  Future<void> _performLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final User user = await _authService.login(
          _usernameController.text,
          _passwordController.text,
        );

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showCreateUserModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateUserModal(
          apiService: _apiService,
          onUserCreated: () {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Usuario creado exitosamente.')),
              );
            }
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel(); // Cancelar el timer al descartar el widget
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Inicio de Sesión',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Gestión de Mantenimiento',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Usuario',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese su usuario';
                        }
                        return null;
                      },
                      onChanged: (_) =>
                          _onCredentialsChanged(), // Llama al nuevo método debounced
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, ingrese su contraseña';
                        }
                        return null;
                      },
                      onChanged: (_) =>
                          _onCredentialsChanged(), // Llama al nuevo método debounced
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _performLogin,
                                  child: const Text('Ingresar'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _showCreateUserModal,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Crear usuario'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isAdminButtonEnabled
                                      ? () async {
                                          await _performLogin();
                                        }
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isAdminButtonEnabled
                                        ? Colors.orange
                                        : Colors.grey,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Administrar usuarios'),
                                ),
                              ),
                            ],
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
