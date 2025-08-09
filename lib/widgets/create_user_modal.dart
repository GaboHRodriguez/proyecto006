import 'package:flutter/material.dart';
import 'package:proyecto006/services/api_service.dart';
import 'package:proyecto006/models/user.dart';

class CreateUserModal extends StatefulWidget {
  final ApiService apiService;
  final VoidCallback? onUserCreated;
  final User? userToEdit;
  final List<String> availableConsorcios;
  final List<String> availableGremios;

  const CreateUserModal({
    super.key,
    required this.apiService,
    this.onUserCreated,
    this.userToEdit,
    this.availableConsorcios = const [],
    this.availableGremios = const [],
  });

  @override
  State<CreateUserModal> createState() => _CreateUserModalState();
}

class _CreateUserModalState extends State<CreateUserModal> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _selectedRole;
  // NO usar late aquí, inicializar directamente para evitar errores
  final List<String> _availableRoles = [
    'Super Usuario',
    'Administracion',
    'Gremios',
    'Consorcios',
  ];
  late List<String> _availableConsorcios;
  late List<String> _availableGremios;

  bool _isLoading = false;
  String? _errorMessage;
  late bool _isActive; // Declaración de _isActive

  late Future<void> _initializeModalFuture;

  @override
  void initState() {
    super.initState();
    // Siempre inicializar _isActive primero para evitar el error de 'late initialization'
    _isActive =
        true; // Valor predeterminado para nueva creación o si no se especifica

    // Inicializar controladores y campos si es edición
    if (widget.userToEdit != null) {
      _usernameController.text = widget.userToEdit!.username;
      _selectedRole = widget.userToEdit!.role;
      _isActive = widget.userToEdit!.isActive; // Se sobrescribe si es edición
    }

    _initializeModalFuture = _initModalData();
    _availableConsorcios = [];
    _availableGremios = [];
  }

  Future<void> _initModalData() async {
    print(
      'CreateUserModal: _initModalData() iniciado. Cargando opciones de dropdown...',
    );

    // Si quitamos authService del constructor, esta línea no puede existir:
    // await widget.authService.initialize(); // Esta llamada no es necesaria para crear usuario

    await _fetchDropdownData(); // Cargar los datos para los dropdowns (Consorcios/Gremios)
    print('CreateUserModal: _initModalData() finalizado. Dropdowns cargados.');
  }

  Future<void> _fetchDropdownData() async {
    try {
      final fetchedConsorcios = await widget.apiService.getConsorcios();
      final fetchedGremios = await widget.apiService.getGremios();
      if (mounted) {
        setState(() {
          _availableConsorcios = fetchedConsorcios;
          _availableGremios = fetchedGremios;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Error al cargar opciones de Consorcios/Gremios: ${e.toString()}';
        });
      }
      print('CreateUserModal: Error fetching dropdown data: $e');
    }
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedRole == null) {
      setState(() {
        _errorMessage = 'Por favor, selecciona un rol.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.userToEdit == null) {
        // Si userToEdit es null, es una CREACIÓN
        await widget.apiService.createUser(
          username: _usernameController.text,
          password: _passwordController.text,
          roleName: _selectedRole!,
          consorcioId: null, // Lógica para asignar si el rol lo requiere
          gremioId: null, // Lógica para asignar si el rol es 'Gremios'
          isActive: _isActive,
        );
      } else {
        // Si userToEdit NO es null, es una EDICIÓN
        // Necesitamos el ID del Super Usuario logueado para pasarlo a apiService.updateUser
        // Este ID debe ser pasado a CreateUserModal desde UserManagementPage.
        // Asumiendo que UserManagementPage lo pasa al llamar _showEditUserModal,
        // este modal necesitaría una nueva propiedad `currentLoggedInUserId` en su constructor.
        // Por ahora, usaremos un placeholder (que DEBES reemplazar).

        // ¡ADVERTENCIA! DEBES ASEGURARTE DE QUE EL ID DEL SUPER USUARIO LOGUEADO SE PASE AQUÍ.
        // Si no lo tienes, la API PHP fallará por falta de permisos.
        // Vamos a asumir que UserManagementPage pasa su widget.currentUserId a este modal.
        // Para esto, necesitarás añadir 'required int currentLoggedInUserId' al constructor de CreateUserModal.
        // Por ahora, pongo un valor temporal para que compile.
        final int currentLoggedInSuperUserId =
            1; // <--- TEMPORAL: REEMPLAZAR con el ID REAL del Super Usuario logueado.
        //      Idealmente, pasar desde UserManagementPage como parámetro.

        await widget.apiService.updateUser(
          userIdToUpdate: widget.userToEdit!.id,
          newUsername: _usernameController.text,
          newPassword: _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
          newRoleName: _selectedRole,
          newConsorcioId: null,
          newGremioId: null,
          newIsActive: _isActive,
          currentUserId: currentLoggedInSuperUserId, // <--- Usa el ID real aquí
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
        widget.onUserCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Usuario ${widget.userToEdit == null ? "creado" : "actualizado"} exitosamente.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
      print('CreateUserModal: Error al guardar usuario: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.userToEdit == null ? 'Crear Nuevo Usuario' : 'Editar Usuario',
      ),
      content: FutureBuilder<void>(
        future: _initializeModalFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (snapshot.hasError) {
            return SizedBox(
              height: 250,
              child: Center(
                child: Text(
                  'Error al cargar datos del modal: ${snapshot.error}',
                ),
              ),
            );
          } else {
            return SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(labelText: 'Usuario'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingrese un usuario'
                          : null,
                    ),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña (déjela vacía para no cambiar)',
                      ),
                      validator: (value) =>
                          widget.userToEdit == null &&
                              (value == null || value.isEmpty)
                          ? 'Ingrese una contraseña'
                          : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      // Aquí usamos las listas _availableRoles (no widget.availableRoles)
                      items: _availableRoles.map((role) {
                        return DropdownMenuItem(value: role, child: Text(role));
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Seleccione un rol' : null,
                    ),
                    if (widget.userToEdit != null)
                      SwitchListTile(
                        title: const Text('Activo'),
                        value: _isActive,
                        onChanged: (bool value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed:
                                (snapshot.connectionState ==
                                        ConnectionState.done &&
                                    !snapshot.hasError)
                                ? _saveUser
                                : null,
                            child: Text(
                              widget.userToEdit == null
                                  ? 'Crear'
                                  : 'Guardar Cambios',
                            ),
                          ),
                  ],
                ),
              ),
            );
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}
