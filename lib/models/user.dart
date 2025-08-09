// lib/models/user.dart (CON toJson para SharedPrefs)
// lib/models/user.dart (CORREGIDO para isActive que puede ser null de API)
class User {
  final int id;
  final String username;
  final String role;
  final int? consorcioId;
  final int? departmentId;
  final int? gremioId;
  final String? token;
  final bool isActive; // Sigue siendo 'final bool' (no nullable)

  User({
    required this.id,
    required this.username,
    required this.role,
    this.consorcioId,
    this.departmentId,
    this.gremioId,
    this.token,
    required this.isActive, // Sigue siendo requerido en el constructor
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      role: json['role'] as String,
      consorcioId: json['consorcio_id'] as int?,
      departmentId: json['department_id'] as int?,
      gremioId: json['gremio_id'] as int?,
      token: json['token'] as String?,
      // CORRECCIÓN AQUÍ: Manejar si 'is_active' es null
      // Usamos `?? false` para dar un valor predeterminado si es null.
      isActive: json['is_active'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'role': role,
      'consorcio_id': consorcioId,
      'department_id': departmentId,
      'gremio_id': gremioId,
      'token': token,
      'is_active': isActive,
    };
  }
}
