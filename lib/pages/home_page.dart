import 'package:flutter/material.dart';
import 'package:proyecto006/models/job.dart';
import 'package:proyecto006/services/api_service.dart';
import 'package:proyecto006/widgets/job_from_modal.dart';
import 'package:intl/intl.dart';
import 'package:proyecto006/models/department.dart';
import 'package:proyecto006/pages/login_page.dart';
import 'package:proyecto006/services/auth_service.dart'; // Importa AuthService
import 'package:proyecto006/pages/user_management_page.dart'; // ¡NUEVA IMPORTACIÓN!

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService(); // Instancia de AuthService

  List<Job> _jobs = [];
  List<Department> _departments = [];
  List<String> _availableConsorcios = [];
  List<String> _availableGremios = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'Todos';
  String _filterBuilding = 'Todos';

  String? _userRole;
  int? _userConsorcioId;
  int? _userGremioId;
  int? _currentUserId; // ID del usuario actual

  @override
  void initState() {
    super.initState();
    _initializeUserAndData();
  }

  Future<void> _initializeUserAndData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    print('HomePage: _initializeUserAndData() iniciado.');
    try {
      print('HomePage: Llamando a _authService.initialize()...');
      await _authService.initialize();

      if (mounted) {
        setState(() {
          _currentUserId = _authService.currentUser?.id;
          _userRole = _authService.currentUser?.role;
          _userConsorcioId = _authService.currentUser?.consorcioId;
          _userGremioId = _authService.currentUser?.gremioId;
        });
        print(
          'HomePage: Datos de usuario cargados en estado. ID: $_currentUserId, Rol: $_userRole',
        );
      }

      await _fetchData();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al inicializar datos del usuario: ${e.toString()}';
        });
      }
      print('HomePage: Error en _initializeUserAndData: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('HomePage: _initializeUserAndData() finalizado.');
    }
  }

  Future<void> _logout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      int? userIdForFilter;
      if (_userRole == 'Administracion') {
        userIdForFilter = _userConsorcioId;
      } else if (_userRole == 'Gremios') {
        userIdForFilter = _userGremioId;
      }

      final fetchedJobs = await _apiService.getJobs(
        role: _userRole,
        userId: userIdForFilter,
      );

      final fetchedDepartments = await _apiService.getDepartments();
      final fetchedConsorcios = await _apiService.getConsorcios();
      final fetchedGremios = await _apiService.getGremios();

      if (mounted) {
        setState(() {
          _jobs = fetchedJobs;
          _departments = fetchedDepartments;
          _availableConsorcios = ['Todos', ...fetchedConsorcios];
          _availableGremios = ['Todos', ...fetchedGremios];
          if (!_availableConsorcios.contains(_filterBuilding)) {
            _filterBuilding = 'Todos';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar datos: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showJobFormModal([Job? job]) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return JobFormModal(
          job: job,
          onSave: (Job savedJob) async {
            String successMessage = job == null
                ? "Trabajo añadido exitosamente."
                : "Trabajo actualizado exitosamente.";
            String errorMessage = "Error al guardar el trabajo.";

            try {
              if (savedJob.id == 0) {
                await _apiService.addJob(savedJob);
              } else {
                await _apiService.updateJob(savedJob);
              }

              if (mounted) {
                _fetchData();
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(successMessage)));
              }

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            } catch (e) {
              errorMessage =
                  "Error al guardar el trabajo: ${e.toString().replaceFirst("Exception: ", "")}";
              print("Error al guardar trabajo: $e");

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          availableDepartments: _departments,
          availableConsorcios: _availableConsorcios
              .where((c) => c != 'Todos')
              .toList(),
          availableGremios: _availableGremios
              .where((g) => g != 'Todos')
              .toList(),
        );
      },
    );
  }

  Future<void> _deleteJob(int id) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este trabajo?',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmDelete == true) {
      try {
        await _apiService.deleteJob(id);
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Trabajo eliminado exitosamente.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar trabajo: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print("Error al eliminar trabajo: $e");
      }
    }
  }

  List<Job> get _filteredJobs {
    return _jobs.where((job) {
      final statusMatch =
          _filterStatus == 'Todos' || job.status == _filterStatus;
      final buildingMatch =
          _filterBuilding == 'Todos' || job.building == _filterBuilding;
      return statusMatch && buildingMatch;
    }).toList();
  }

  void _navigateToUserManagement() {
    print('HomePage: Botón Gestionar Usuarios presionado.');
    if (_authService.currentUser == null) {
      print(
        'DEBUG: _authService.currentUser es NULL en _navigateToUserManagement. Redirigiendo o mostrando error.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Datos de usuario no disponibles para gestión. Intente reiniciar la app o iniciar sesión nuevamente.',
          ),
        ),
      );
      return;
    }
    if (_authService.currentUser!.role != 'Super Usuario') {
      print(
        'DEBUG: Rol del usuario actual es ${_authService.currentUser!.role}, NO es Super Usuario. Redirigiendo o mostrando error.',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Acceso denegado: Solo Super Usuarios pueden administrar usuarios.',
          ),
        ),
      );
      return;
    }
    print(
      'DEBUG: Usuario actual: ID=${_authService.currentUser!.id}, Rol=${_authService.currentUser!.role}',
    );

    // TODO: Implementar y navegar a UserManagementPage(currentUserId: _authService.currentUser!.id!)
    // ¡Navegar a la nueva página de gestión de usuarios!
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) =>
                UserManagementPage(currentUserId: _authService.currentUser!.id),
          ),
        )
        .then((_) {
          // Opcional: Si necesitas recargar datos al regresar de la gestión de usuarios
          _fetchData();
        });
  }

  void _navigateToEditProfile() {
    print('HomePage: Botón Editar Perfil presionado.');
    if (_authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Datos de usuario no disponibles para editar perfil. Intente reiniciar la app o iniciar sesión nuevamente.',
          ),
        ),
      );
      print(
        'DEBUG: _authService.currentUser es null en _navigateToEditProfile',
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Navegar a Editar Perfil (próximamente).')),
    );
    // TODO: Implementar y navegar a EditProfilePage(user: _authService.currentUser!)
  }

  @override
  Widget build(BuildContext context) {
    final bool canEditJobs =
        _userRole == 'Super Usuario' || _userRole == 'Administracion';
    final bool isSuperUser = _userRole == 'Super Usuario';

    return Scaffold(
      appBar: AppBar(
        title: Text('Gestión (${_userRole ?? ''})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Editar Perfil',
            onPressed: _navigateToEditProfile,
          ),
          if (isSuperUser)
            IconButton(
              icon: const Icon(Icons.group),
              tooltip: 'Gestionar Usuarios',
              onPressed:
                  _navigateToUserManagement, // ¡Llama a la nueva función!
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar Sesión',
            onPressed: _logout,
          ),
          if (canEditJobs)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                onPressed: () => _showJobFormModal(),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Añadir Trabajo',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
      body:
          _isLoading // Muestra un CircularProgressIndicator mientras se carga
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _filterStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                ),
                                items:
                                    <String>[
                                      'Todos',
                                      'Pendiente',
                                      'En Progreso',
                                      'Completado',
                                      'Revisión',
                                      'Cancelado',
                                    ].map<DropdownMenuItem<String>>((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _filterStatus = newValue!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _filterBuilding,
                                decoration: const InputDecoration(
                                  labelText: 'Edificio',
                                ),
                                items: _availableConsorcios
                                    .map<DropdownMenuItem<String>>((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    })
                                    .toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    _filterBuilding = newValue!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: _error != null
                          ? Center(child: Text(_error!))
                          : _filteredJobs.isEmpty
                          ? const Center(
                              child: Text('No hay trabajos para mostrar.'),
                            )
                          : Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Título')),
                                    DataColumn(label: Text('Edificio/Depto.')),
                                    DataColumn(label: Text('Técnico')),
                                    DataColumn(label: Text('Fecha Límite')),
                                    DataColumn(label: Text('Estado')),
                                    DataColumn(label: Text('Prioridad')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows: _filteredJobs.map((job) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                job.titulo,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                job.descripcion,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            job.departmentUnit != null
                                                ? '${job.building} / ${job.departmentUnit}'
                                                : job.building,
                                          ),
                                        ),
                                        DataCell(Text(job.technician)),
                                        DataCell(
                                          Text(
                                            DateFormat(
                                              'dd/MM/yyyy',
                                            ).format(job.dueDate),
                                          ),
                                        ),
                                        DataCell(Text(job.status)),
                                        DataCell(Text(job.priority)),
                                        DataCell(
                                          canEditJobs
                                              ? Row(
                                                  children: [
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.edit,
                                                        color: Colors.indigo,
                                                      ),
                                                      onPressed: () =>
                                                          _showJobFormModal(
                                                            job,
                                                          ),
                                                    ),
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete,
                                                        color: Colors.red,
                                                      ),
                                                      onPressed: () =>
                                                          _deleteJob(job.id),
                                                    ),
                                                  ],
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
    //);
  }
}
