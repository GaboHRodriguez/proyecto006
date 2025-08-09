// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:proyecto006/models/user.dart';

class AuthService {
  static const String _baseUrl = 'https://funcioncreativa.com.ar/sys/api.php';

  static const String _currentUserKey = 'current_user_data';
  static const String _tokenKey = 'auth_token';

  User? _currentUser;
  String? _token;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;

  // Constructor: Ahora NO llama a _loadUserFromPrefs()
  // Esta función ahora será llamada explícitamente y se podrá esperar por ella.
  AuthService();

  // Método para inicializar el servicio (cargar usuario)
  // Ahora es público y deberá ser llamado externamente.
  Future<void> initialize() async {
    print('AuthService: Iniciando carga de usuario...');
    await _loadUserFromPrefs(); // <-- Esta es la llamada asíncrona principal
    print(
      'AuthService: Carga de usuario finalizada. _currentUser es: ${_currentUser?.username ?? 'null'}',
    );
  }

  // Carga los datos del usuario desde SharedPreferences (como JSON)
  Future<void> _loadUserFromPrefs() async {
    print(
      'AuthService._loadUserFromPrefs: Intentando leer de SharedPreferences...',
    );
    final prefs =
        await SharedPreferences.getInstance(); // <-- Esta puede ser lenta
    final userDataString = prefs.getString(_currentUserKey);
    _token = prefs.getString(_tokenKey);

    if (userDataString != null) {
      try {
        _currentUser = User.fromJson(json.decode(userDataString));
        print(
          'AuthService._loadUserFromPrefs: Usuario decodificado: ${_currentUser?.username}',
        );
      } catch (e) {
        print('AuthService._loadUserFromPrefs: Error decodificando datos: $e');
        _currentUser = null;
        await prefs.remove(_currentUserKey);
        await prefs.remove(_tokenKey);
      }
    } else {
      print(
        'AuthService._loadUserFromPrefs: No se encontraron datos de usuario.',
      );
    }
    /*
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(
      _currentUserKey,
    ); // <-- Lee el JSON string
    if (userDataString != null) {
      try {
        _currentUser = User.fromJson(
          json.decode(userDataString),
        ); // <-- Decodifica y crea el User
      } catch (e) {
        // ... si hay un error aquí, significa que el JSON guardado era inválido o corrupto
      }
    } 
    final userDataString = prefs.getString(_currentUserKey);
    _token = prefs.getString(_tokenKey);

    if (userDataString != null) {
      try {
        _currentUser = User.fromJson(json.decode(userDataString));
        print(
          'Usuario cargado de SharedPreferences: ${_currentUser?.username}',
        ); // Log de depuración
      } catch (e) {
        print('Error decodificando datos de usuario de SharedPreferences: $e');
        _currentUser = null;
        await prefs.remove(_currentUserKey);
        await prefs.remove(_tokenKey);
      }
    } else {
      print('No user data found in SharedPreferences.'); // Log de depuración
    }*/
  }

  // Lógica de inicio de sesión
  Future<User> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({
        'endpoint': 'login',
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      final user = User.fromJson(responseBody['userData']);
      final String? receivedToken = responseBody['token'] as String?;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, jsonEncode(user.toJson()));
      await prefs.setString(_tokenKey, receivedToken ?? '');

      _token = receivedToken;
      _currentUser = user;
      print(
        'Login exitoso. Usuario: ${_currentUser?.username}',
      ); // Log de depuración
      return user;
    } else {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(
          'Login falló: ${errorBody['message'] ?? response.body}',
        );
      } catch (e) {
        throw Exception(
          'Login falló: ${response.statusCode} - ${response.body}',
        );
      }
    }
  }

  // Lógica de cierre de sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await prefs.remove(_tokenKey);

    _currentUser = null;
    _token = null;
    print('Sesión cerrada. Usuario nulo.'); // Log de depuración
  }
}
