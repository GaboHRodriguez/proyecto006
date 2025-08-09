// lib/widgets/job_form_modal.dart
import 'package:flutter/material.dart';
import 'package:proyecto006/models/job.dart';
import 'package:proyecto006/models/department.dart';
import 'package:intl/intl.dart';

class JobFormModal extends StatefulWidget {
  final Job? job;
  final Function(Job) onSave;
  final List<Department> availableDepartments;
  final List<String> availableConsorcios;
  final List<String> availableGremios;

  const JobFormModal({
    super.key,
    this.job,
    required this.onSave,
    required this.availableDepartments,
    required this.availableConsorcios,
    required this.availableGremios,
  });

  @override
  State<JobFormModal> createState() => _JobFormModalState();
}

class _JobFormModalState extends State<JobFormModal> {
  final _formKey = GlobalKey<FormState>();
  late String _titulo;
  late String _descripcion;
  late String _status;
  late String _building;
  late String _technician;
  late DateTime _dueDate;
  late String _priority;
  late String _jobTargetType;
  Department? _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _titulo = widget.job?.titulo ?? '';
    _descripcion = widget.job?.descripcion ?? '';
    _status = widget.job?.status ?? 'Pendiente';
    _building =
        widget.job?.building ??
        (widget.availableConsorcios.isNotEmpty
            ? widget.availableConsorcios.first
            : '');
    _technician =
        widget.job?.technician ??
        (widget.availableGremios.isNotEmpty
            ? widget.availableGremios.first
            : '');
    _dueDate = widget.job?.dueDate ?? DateTime.now();
    _priority = widget.job?.priority ?? 'Media';

    // Lógica segura para encontrar el departamento inicial
    if (widget.job?.departmentId != null) {
      _jobTargetType = 'department';
      try {
        _selectedDepartment = widget.availableDepartments.firstWhere(
          (dept) => dept.id == widget.job!.departmentId,
        );
      } catch (e) {
        _selectedDepartment = null;
      }
    } else {
      _jobTargetType = 'building';
      _selectedDepartment = null;
    }
  }

  List<Department> get _filteredDepartments {
    return widget.availableDepartments
        .where((d) => d.consorcioNombre == _building)
        .toList();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _dueDate) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_jobTargetType == 'department' &&
          _selectedDepartment == null &&
          _filteredDepartments.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona un departamento.'),
          ),
        );
        return;
      }

      final jobToSave = Job(
        id: widget.job?.id ?? 0,
        titulo: _titulo,
        descripcion: _descripcion,
        dueDate: _dueDate,
        building: _building,
        technician: _technician,
        status: _status,
        priority: _priority,
        departmentId: _jobTargetType == 'department'
            ? _selectedDepartment?.id
            : null,
        departmentUnit: _jobTargetType == 'department'
            ? _selectedDepartment?.unidad
            : null,
        departmentOrder: _jobTargetType == 'department'
            ? _selectedDepartment?.orden
            : null,
      );
      widget.onSave(jobToSave);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Department> currentFilteredDepartments = _filteredDepartments;

    return AlertDialog(
      title: Text(
        widget.job == null ? 'Añadir Nuevo Trabajo' : 'Editar Trabajo',
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                initialValue: _titulo,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Ingresa un título' : null,
                onSaved: (value) => _titulo = value!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _descripcion,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                validator: (value) =>
                    (value?.isEmpty ?? true) ? 'Ingresa una descripción' : null,
                onSaved: (value) => _descripcion = value!,
              ),
              const SizedBox(height: 16),
              const Text("Asignar a:", style: TextStyle(color: Colors.grey)),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Edificio'),
                      value: 'building',
                      groupValue: _jobTargetType,
                      onChanged: (v) => setState(() {
                        _jobTargetType = v!;
                        _selectedDepartment = null;
                      }),
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      title: const Text('Depto.'),
                      value: 'department',
                      groupValue: _jobTargetType,
                      onChanged: (v) => setState(() => _jobTargetType = v!),
                    ),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                value: _building,
                decoration: const InputDecoration(
                  labelText: 'Edificio (Consorcio)',
                ),
                items: widget.availableConsorcios.map<DropdownMenuItem<String>>(
                  (String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  },
                ).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _building = newValue!;
                    _selectedDepartment =
                        null; // Resetea el depto. al cambiar de edificio
                  });
                },
              ),
              if (_jobTargetType == 'department') ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<Department>(
                  value: _selectedDepartment,
                  decoration: const InputDecoration(labelText: 'Departamento'),
                  hint: Text(
                    currentFilteredDepartments.isEmpty
                        ? 'No hay deptos. para este edificio'
                        : 'Selecciona un depto.',
                  ),
                  items: currentFilteredDepartments
                      .map<DropdownMenuItem<Department>>((Department dept) {
                        return DropdownMenuItem<Department>(
                          value: dept,
                          child: Text('${dept.unidad} - ${dept.nombre}'),
                        );
                      })
                      .toList(),
                  onChanged: (currentFilteredDepartments.isEmpty)
                      ? null
                      : (Department? newValue) {
                          setState(() => _selectedDepartment = newValue);
                        },
                ),
              ],
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _technician,
                decoration: const InputDecoration(
                  labelText: 'Técnico Asignado',
                ),
                items: widget.availableGremios.map<DropdownMenuItem<String>>((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) =>
                    setState(() => _technician = newValue!),
                validator: (v) => v == null ? 'Selecciona un técnico' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: AbsorbPointer(
                  child: TextFormField(
                    controller: TextEditingController(
                      text: DateFormat('dd/MM/yyyy').format(_dueDate),
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Fecha Límite',
                      suffixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _status,
                decoration: const InputDecoration(labelText: 'Estado'),
                items:
                    <String>[
                      'Pendiente',
                      'En Progreso',
                      'Completado',
                      'Cancelado',
                      'Revisión',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                onChanged: (String? newValue) =>
                    setState(() => _status = newValue!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Prioridad'),
                items: <String>['Baja', 'Media', 'Alta']
                    .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    })
                    .toList(),
                onChanged: (String? newValue) =>
                    setState(() => _priority = newValue!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(onPressed: _saveForm, child: const Text('Guardar')),
      ],
    );
  }
}
