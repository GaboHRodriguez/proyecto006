// lib/providers/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:proyecto006/models/user.dart';
import 'package:proyecto006/services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService;

  AuthProvider(this._authService);

  User? get currentUser => _authService.currentUser;
  bool get isAuthenticated => _authService.isAuthenticated;

  Future<void> login(String username, String password) async {
    try {
      await _authService.login(username, password);
      notifyListeners(); // Notifica a la UI que el estado de autenticación ha cambiado
    } catch (e) {
      rethrow; // Re-lanza la excepción para que la UI la maneje
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners(); // Notifica a la UI
  }

  // Puedes añadir métodos para verificar roles aquí, o en la UI directamente
  bool hasRole(String roleName) {
    return _authService.currentUser?.role == roleName;
  }
}
