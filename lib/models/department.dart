class Department {
  final int id;
  final int consorcioId;
  final int codigo;
  final String unidad;
  final int orden;
  final String nombre;
  final String email;
  final String telefono;
  final String whatsapp;
  final String consorcioNombre; // Para mostrar en el dropdown

  Department({
    required this.id,
    required this.consorcioId,
    required this.codigo,
    required this.unidad,
    required this.orden,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.whatsapp,
    required this.consorcioNombre,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    // Parseo robusto para todos los campos int, manejando strings o nulos.
    final int parsedId = json['ID'] is int
        ? json['ID']
        : int.tryParse(json['ID']?.toString() ?? '') ?? 0;
    final int parsedConsorcioId = json['consorcioId'] is int
        ? json['consorcioId']
        : int.tryParse(json['consorcioId']?.toString() ?? '') ?? 0;
    final int parsedCodigo = json['Codigo'] is int
        ? json['Codigo']
        : int.tryParse(json['Codigo']?.toString() ?? '') ?? 0;
    final int parsedOrden = json['Orden'] is int
        ? json['Orden']
        : int.tryParse(json['Orden']?.toString() ?? '') ?? 0;

    return Department(
      id: parsedId,
      consorcioId: parsedConsorcioId,
      codigo: parsedCodigo,
      unidad: json['Unidad'] as String,
      orden: parsedOrden,
      nombre: json['Nombre'] as String,
      email: json['Email'] as String,
      telefono: json['Telefono'] as String,
      whatsapp: json['Whatsapp'] as String,
      consorcioNombre: json['consorcioNombre'] as String,
    );
  }
}
