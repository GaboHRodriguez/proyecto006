import 'package:flutter/material.dart';
import 'package:proyecto006/models/user.dart';
import 'package:proyecto006/services/api_service.dart';
import 'package:proyecto006/services/auth_service.dart';
import 'package:proyecto006/widgets/create_user_modal.dart'; // Reutilizar este modal

class UserManagementPage extends StatefulWidget {
  final int currentUserId; // ID del Super Usuario que está en esta página

  const UserManagementPage({super.key, required this.currentUserId});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  List<User> _users = [];
  List<String> _availableConsorcios = []; // También se necesitan aquí
  List<String> _availableGremios = []; // También se necesitan aquí

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeUserManagementData();
  }

  Future<void> _initializeUserManagementData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _authService.initialize();
      // Fetchear consorcios y gremios aquí para pasarlos al modal
      final fetchedConsorcios = await _apiService.getConsorcios();
      final fetchedGremios = await _apiService.getGremios();
      if (mounted) {
        setState(() {
          _availableConsorcios = fetchedConsorcios;
          _availableGremios = fetchedGremios;
        });
      }

      await _fetchUsers(); // Carga la lista de usuarios
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'Error al inicializar la gestión de usuarios: ${e.toString()}';
        });
      }
      print('UserManagementPage: Error en _initializeUserManagementData: $e');
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    if (!_authService.isAuthenticated) {
      if (mounted) {
        setState(() {
          _error = 'Acceso denegado: No autenticado. (Error de sesión).';
          _isLoading = false;
        });
        Navigator.of(context).pop();
      }
      return;
    }

    if (_authService.currentUser == null ||
        _authService.currentUser!.role != 'Super Usuario') {
      if (mounted) {
        setState(() {
          _error = 'Acceso denegado: No eres un Super Usuario.';
          _isLoading = false;
        });
        Navigator.of(context).pop();
      }
      return;
    }

    try {
      final fetchedUsers = await _apiService.getUsers(
        currentUserId: widget.currentUserId,
      );

      if (mounted) {
        setState(() {
          _users = fetchedUsers;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar usuarios de la API: ${e.toString()}';
        });
      }
      print('Error al cargar usuarios en UserManagementPage: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showEditUserModal([User? user]) {
    // Asegurarse de que tenemos el ID del Super Usuario logueado para pasarlo al modal
    if (_authService.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: ID del Super Usuario actual no disponible para la edición.',
          ),
        ),
      );
      return;
    }
    final int currentLoggedInSuperUserId =
        _authService.currentUser!.id; // Este es el ID que se necesita

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateUserModal(
          // Reutilizamos CreateUserModal
          apiService: _apiService,
          userToEdit: user, // Pasamos el usuario a editar (o null para nuevo)
          availableConsorcios: _availableConsorcios, // <--- PASAR AHORA
          availableGremios: _availableGremios, // <--- PASAR AHORA
          onUserCreated: () {
            // El callback ahora puede ser para crear O guardar
            _fetchUsers(); // Recarga la lista después de guardar/crear
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Usuario guardado exitosamente.')),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteUser(int userId) async {
    // No permitir que el Super Usuario se elimine a sí mismo
    if (userId == widget.currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No puedes eliminar tu propia cuenta.'),
        ),
      );
      return;
    }

    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text(
          '¿Estás seguro de que quieres eliminar al usuario con ID: $userId?',
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
      setState(() {
        _isLoading = true;
      });
      try {
        await _apiService.deleteUser(
          userIdToDelete: userId,
          currentUserId: widget.currentUserId,
        );
        _fetchUsers(); // Recarga la lista después de eliminar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Usuario eliminado exitosamente.')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = 'Error al eliminar usuario: ${e.toString()}';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar usuario: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('Error al eliminar usuario en UserManagementPage: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrar Usuarios'),
        actions: [
          IconButton(
            // Botón para añadir nuevo usuario desde esta pantalla
            icon: const Icon(Icons.add),
            tooltip: 'Añadir Usuario',
            onPressed: () =>
                _showEditUserModal(), // Llama sin usuario para crear nuevo
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUsers,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _error != null
                        ? Center(child: Text(_error!))
                        : _users.isEmpty
                        ? const Center(
                            child: Text('No hay usuarios para mostrar.'),
                          )
                        : Expanded(
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('ID')),
                                    DataColumn(label: Text('Usuario')),
                                    DataColumn(label: Text('Rol')),
                                    DataColumn(label: Text('Activo')),
                                    DataColumn(label: Text('Acciones')),
                                  ],
                                  rows: _users.map((user) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(user.id.toString())),
                                        DataCell(Text(user.username)),
                                        DataCell(Text(user.role)),
                                        DataCell(
                                          Text(user.isActive ? 'Sí' : 'No'),
                                        ),
                                        DataCell(
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  color: Colors.indigo,
                                                ),
                                                onPressed: () =>
                                                    _showEditUserModal(user),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                ),
                                                onPressed: () =>
                                                    _deleteUser(user.id),
                                              ),
                                            ],
                                          ),
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
  }
}
