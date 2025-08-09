// lib/models/job.dart
import 'package:intl/intl.dart';

class Job {
  final int id;
  final String titulo;
  final String descripcion;
  final DateTime dueDate;
  final String building;
  final String technician;
  final String status;
  final String priority;
  final int? departmentId;
  final String? departmentUnit;
  final int? departmentOrder;

  Job({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.dueDate,
    required this.building,
    required this.technician,
    required this.status,
    required this.priority,
    this.departmentId,
    this.departmentUnit,
    this.departmentOrder,
  });

  factory Job.fromJson(Map<String, dynamic> json) {
    DateTime parsedDueDate;
    try {
      final int year = int.parse(json['AnioFin'].toString());
      final int month = int.parse(json['MesFin'].toString());
      final int day = int.parse(json['DiaFin'].toString());
      parsedDueDate = DateTime(year, month, day);
    } catch (e) {
      parsedDueDate = DateTime.now();
    }

    return Job(
      id: int.tryParse(json['ID']?.toString() ?? '0') ?? 0,
      titulo: json['Titulo'] ?? '',
      descripcion: json['Descripcion'] ?? '',
      dueDate: parsedDueDate,
      building: json['building'] ?? '',
      technician: json['technician'] ?? '',
      status: json['status'] ?? '',
      priority: json['priority'] ?? '',
      departmentId: int.tryParse(json['departmentId']?.toString() ?? ''),
      departmentUnit: json['departmentUnit'],
      departmentOrder: int.tryParse(json['departmentOrder']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': titulo,
      'description': descripcion,
      'dueDate': DateFormat('yyyy-MM-dd').format(dueDate),
      'building': building,
      'technician': technician,
      'status': status,
      'priority': priority,
      'departmentId': departmentId,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    final Map<String, dynamic> json = toJson();
    json['id'] = id;
    return json;
  }
}
