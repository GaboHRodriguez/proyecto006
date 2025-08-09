// lib/providers/job_provider.dart
import 'package:flutter/foundation.dart';
import 'package:proyecto006/models/job.dart';
import 'package:proyecto006/models/department.dart';
import 'package:proyecto006/services/api_service.dart';

class JobProvider with ChangeNotifier {
  final ApiService _apiService;

  List<Job> _jobs = [];
  List<Department> _departments = [];
  List<String> _availableConsorcios = [];
  List<String> _availableGremios = [];
  bool _isLoading = false;
  String? _error;
  String _filterStatus = 'Todos';
  String _filterBuilding = 'Todos';

  JobProvider(this._apiService); // Inyecta ApiService

  List<Job> get jobs => _jobs;
  List<Department> get departments => _departments;
  List<String> get availableConsorcios => _availableConsorcios;
  List<String> get availableGremios => _availableGremios;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterStatus => _filterStatus;
  String get filterBuilding => _filterBuilding;

  List<Job> get filteredJobs {
    return _jobs.where((job) {
      final statusMatch =
          _filterStatus == 'Todos' || job.status == _filterStatus;
      final buildingMatch =
          _filterBuilding == 'Todos' || job.building == _filterBuilding;
      return statusMatch && buildingMatch;
    }).toList();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    _error = null;
    notifyListeners(); // Notifica que el estado de carga cambió

    try {
      final fetchedJobs = await _apiService.getJobs();
      final fetchedDepartments = await _apiService.getDepartments();
      final fetchedConsorcios = await _apiService.getConsorcios();
      final fetchedGremios = await _apiService.getGremios();

      _jobs = fetchedJobs;
      _departments = fetchedDepartments;
      _availableConsorcios = ['Todos', ...fetchedConsorcios];
      _availableGremios = ['Todos', ...fetchedGremios];
      if (!_availableConsorcios.contains(_filterBuilding)) {
        _filterBuilding = 'Todos';
      }
    } catch (e) {
      _error = 'Error al cargar datos: ${e.toString()}';
      print('Error fetching data in JobProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notifica que los datos han cargado o hubo un error
    }
  }

  Future<void> addJob(Job job) async {
    try {
      await _apiService.addJob(job);
      await fetchData(); // Recargar datos después de añadir
    } catch (e) {
      _error = 'Error al añadir trabajo: ${e.toString()}';
      notifyListeners();
      rethrow; // Re-lanza el error para que la UI lo pueda manejar (ej. SnackBar)
    }
  }

  Future<void> updateJob(Job job) async {
    try {
      await _apiService.updateJob(job);
      await fetchData(); // Recargar datos después de actualizar
    } catch (e) {
      _error = 'Error al actualizar trabajo: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteJob(int id) async {
    try {
      await _apiService.deleteJob(id);
      await fetchData(); // Recargar datos después de eliminar
    } catch (e) {
      _error = 'Error al eliminar trabajo: ${e.toString()}';
      notifyListeners();
      rethrow;
    }
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setFilterBuilding(String building) {
    _filterBuilding = building;
    notifyListeners();
  }
}
