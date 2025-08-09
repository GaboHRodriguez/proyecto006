// lib/services/api_service.dart (VOLVIENDO A USAR JSON COMPLETAMENTE)
// lib/services/api_service.dart (Actualizado para createUser sin currentUserId)
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:proyecto006/models/job.dart';
import 'package:proyecto006/models/department.dart';
import 'package:proyecto006/models/user.dart';
import 'package:intl/intl.dart';

class ApiService {
  static const String _baseUrl = 'https://173.230.153.11/sys/api.php';

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
      return User.fromJson(responseBody['userData']);
    } else {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ?? 'Error desconocido en el login',
        );
      } catch (e) {
        throw Exception(
          'Error de comunicación con el servidor: ${response.statusCode} - ${response.body}',
        );
      }
    }
  }

  Future<List<Job>> getJobs({String? role, int? userId}) async {
    final Map<String, String> queryParameters = {'endpoint': 'jobs'};
    if (role != null) {
      queryParameters['role'] = role;
    }
    if (userId != null) {
      queryParameters['user_id'] = userId.toString();
    }
    final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParameters);

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Job.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load jobs: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<Department>> getDepartments() async {
    final uri = Uri.parse(
      _baseUrl,
    ).replace(queryParameters: {'endpoint': 'departments'});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Department.fromJson(json)).toList();
    } else {
      throw Exception(
        'Failed to load departments: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<String>> getConsorcios() async {
    final uri = Uri.parse(
      _baseUrl,
    ).replace(queryParameters: {'endpoint': 'consorcios'});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => json.toString()).toList();
    } else {
      throw Exception(
        'Failed to load consorcios: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<List<String>> getGremios() async {
    final uri = Uri.parse(
      _baseUrl,
    ).replace(queryParameters: {'endpoint': 'gremios'});
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => json.toString()).toList();
    } else {
      throw Exception(
        'Failed to load gremios: ${response.statusCode} - ${response.body}',
      );
    }
  }

  Future<void> addJob(Job job) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'endpoint': 'jobs',
        'title': job.titulo,
        'description': job.descripcion,
        'dueDate': DateFormat('yyyy-MM-dd').format(job.dueDate),
        'building': job.building,
        'technician': job.technician,
        'status': job.status,
        'priority': job.priority,
        'departmentId': job.departmentId,
      }),
    );

    if (response.statusCode == 201) {
      final responseBody = json.decode(response.body);
      print('Add Job Success Response: $responseBody');
    } else {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ??
              'Error al añadir trabajo: ${response.statusCode}',
        );
      } catch (e) {
        throw Exception(
          'Error al añadir trabajo: ${response.statusCode} - ${response.body}',
        );
      }
    }
  }

  Future<void> updateJob(Job job) async {
    final uri = Uri.parse(
      _baseUrl,
    ).replace(queryParameters: {'id': job.id.toString()});

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'endpoint': 'jobs',
        'id': job.id,
        'title': job.titulo,
        'description': job.descripcion,
        'dueDate': DateFormat('yyyy-MM-dd').format(job.dueDate),
        'building': job.building,
        'technician': job.technician,
        'status': job.status,
        'priority': job.priority,
        'departmentId': job.departmentId,
      }),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      print('Update Job Success Response: $responseBody');
    } else {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ??
              'Error al actualizar trabajo: ${response.statusCode}',
        );
      } catch (e) {
        throw Exception(
          'Error al actualizar trabajo: ${response.statusCode} - ${response.body}',
        );
      }
    }
  }

  Future<void> deleteJob(int id) async {
    final uri = Uri.parse(
      _baseUrl,
    ).replace(queryParameters: {'endpoint': 'jobs', 'id': id.toString()});
    final response = await http.delete(uri);
    if (response.statusCode != 200) {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ??
              'Error al eliminar trabajo: ${response.statusCode}',
        );
      } catch (e) {
        throw Exception(
          'Error al eliminar trabajo: ${response.statusCode} - ${response.body}',
        );
      }
    } else {
      final responseBody = json.decode(response.body);
      print('Delete Job Success: $responseBody');
    }
  }

  Future<List<User>> getUsers({required int currentUserId}) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'endpoint': 'users',
        'current_user_id': currentUserId.toString(),
      },
    );
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => User.fromJson(json)).toList();
    } else {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ??
              'Error al cargar usuarios: ${response.statusCode}',
        );
      } catch (e) {
        throw Exception(
          'Error al cargar usuarios: ${response.statusCode} - ${response.body}',
        );
      }
    }
  }

  // --- createUser: Ya NO requiere currentUserId ---
  Future<void> createUser({
    required String username,
    required String password,
    required String roleName,
    int? consorcioId,
    int? gremioId,
    bool isActive = true,
    // Eliminado: required int currentUserId,
  }) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'endpoint': 'users',
        'username': username,
        'password': password,
        'role': roleName,
        'consorcioId': consorcioId,
        'gremioId': gremioId,
        'is_active': isActive ? 1 : 0,
        // Eliminado: 'current_user_id': currentUserId,
      }),
    );

    if (response.statusCode == 201) {
      final responseBody = json.decode(response.body);
      print('Usuario creado exitosamente: $responseBody');
    } else {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ??
              'Error al crear usuario: ${response.statusCode}',
        );
      } catch (e) {
        throw Exception(
          'Error al crear usuario: ${response.statusCode} - ${response.body}',
        );
      }
    }
  }

  Future<void> updateUser({
    required int userIdToUpdate,
    String? newUsername,
    String? newPassword,
    String? newRoleName,
    int? newConsorcioId,
    int? newGremioId,
    bool? newIsActive,
    required int
    currentUserId, // Este SÍ requiere currentUserId para permisos de edición
  }) async {
    final Map<String, dynamic> requestBody = {
      'endpoint': 'users',
      'id': userIdToUpdate,
      'current_user_id': currentUserId,
    };

    if (newUsername != null) requestBody['username'] = newUsername;
    if (newPassword != null) requestBody['password'] = newPassword;
    if (newRoleName != null) requestBody['role'] = newRoleName;
    if (newConsorcioId != null) requestBody['consorcioId'] = newConsorcioId;
    if (newGremioId != null) requestBody['gremioId'] = newGremioId;
    if (newIsActive != null) requestBody['is_active'] = newIsActive ? 1 : 0;

    final uri = Uri.parse(
      _baseUrl,
    ).replace(queryParameters: {'id': userIdToUpdate.toString()});

    final response = await http.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );

    if (response.statusCode == 200) {
      final responseBody = json.decode(response.body);
      print('Usuario actualizado exitosamente: $responseBody');
    } else {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ??
              'Error al actualizar usuario: ${response.statusCode}',
        );
      } catch (e) {
        throw Exception(
          'Error al actualizar usuario: ${response.statusCode} - ${response.body}',
        );
      }
    }
  }

  Future<void> deleteUser({
    required int userIdToDelete,
    required int currentUserId,
  }) async {
    final uri = Uri.parse(_baseUrl).replace(
      queryParameters: {
        'endpoint': 'users',
        'id': userIdToDelete.toString(),
        'current_user_id': currentUserId.toString(),
      },
    );
    final response = await http.delete(uri);
    if (response.statusCode != 200) {
      try {
        final errorBody = json.decode(response.body);
        throw Exception(
          errorBody['message'] ??
              'Error al eliminar usuario: ${response.statusCode}',
        );
      } catch (e) {
        throw Exception(
          'Error al eliminar usuario: ${response.statusCode} - ${response.body}',
        );
      }
    } else {
      final responseBody = json.decode(response.body);
      print('Usuario eliminado exitosamente: $responseBody');
    }
  }
}
