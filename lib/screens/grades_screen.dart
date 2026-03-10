import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../services/database_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class GradesScreen extends StatefulWidget {
  final Course course;
  const GradesScreen({super.key, required this.course});

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  final DatabaseService _db = DatabaseService();
  final Map<String, double> _grades = {}; // studentId -> grade
  final Map<String, TextEditingController> _controllers = {};
  bool _isLoading = true;
  String _selectedPeriod = '1er Trimestre';

  final List<String> _evaluationPeriods = [
    '1er Trimestre',
    '2do Trimestre',
    '3er Trimestre',
    '1er Cuatrimestre',
    '2do Cuatrimestre',
  ];

  @override
  void initState() {
    super.initState();
    _loadGrades();
  }

  Future<void> _loadGrades() async {
    setState(() {
      _isLoading = true;
      _grades.clear();
      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
    });

    final grades = await _db.getGrades(
      widget.course.id,
      _getFormattedPeriod(_selectedPeriod),
    );
    if (mounted) {
      setState(() {
        _grades.addAll(grades);
        _isLoading = false;
      });
    }
  }

  String _getFormattedPeriod(String period) {
    return period.toLowerCase().replaceAll(' ', '_');
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(String studentId) {
    if (!_controllers.containsKey(studentId)) {
      final grade = _grades[studentId] ?? 0.0;
      _controllers[studentId] = TextEditingController(
        text: grade == 0.0 ? '' : grade.toStringAsFixed(1),
      );
    }
    return _controllers[studentId]!;
  }

  void _updateGrade(String studentId, String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    if (parsed != null) {
      setState(() {
        _grades[studentId] = parsed.clamp(0.0, 10.0);
      });
    } else if (value.isEmpty) {
      setState(() {
        _grades.remove(studentId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Column(
          children: [
            const Text(
              'Carga de Notas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              widget.course.name,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _exportGrades(context),
            icon: const Icon(Icons.download),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.tune)),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Info Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardTheme.color,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.grey.shade100
                                  : Colors.grey.shade800,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentBlue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedPeriod,
                                    dropdownColor: Theme.of(
                                      context,
                                    ).cardTheme.color,
                                    icon: const Icon(
                                      Icons.arrow_drop_down,
                                      color: AppTheme.primaryBlue,
                                    ),
                                    style: const TextStyle(
                                      color: AppTheme.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                    onChanged: (String? newValue) {
                                      if (newValue != null &&
                                          newValue != _selectedPeriod) {
                                        setState(() {
                                          _selectedPeriod = newValue;
                                        });
                                        _loadGrades();
                                      }
                                    },
                                    items: _evaluationPeriods
                                        .map<DropdownMenuItem<String>>((
                                          String value,
                                        ) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value.toUpperCase()),
                                          );
                                        })
                                        .toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.course.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  _InfoBox(
                                    label: 'PROMEDIO',
                                    value: '7.4',
                                    valueColor: AppTheme.primaryBlue,
                                  ),
                                  const SizedBox(width: 16),
                                  const _InfoBox(
                                    label: 'COMPLETADO',
                                    value: '18/24',
                                    valueColor: AppTheme.textPrimary,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        StreamBuilder<List<Student>>(
                          stream: _db.streamStudents(widget.course.id),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Text(
                                  'No hay alumnos registrados en este curso.',
                                ),
                              );
                            }

                            final students = snapshot.data!;

                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'ALUMNO',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const Text(
                                      'CALIFICACIÓN',
                                      style: TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: students.length,
                                  itemBuilder: (context, index) {
                                    final student = students[index];
                                    final controller = _controllerFor(
                                      student.id,
                                    );

                                    return _GradeItem(
                                          name: student.name,
                                          id: 'ID: ${student.id.substring(0, 5)}',
                                          attendance:
                                              '95%', // Placeholder for now
                                          controller: controller,
                                          onChanged: (value) =>
                                              _updateGrade(student.id, value),
                                        )
                                        .animate()
                                        .fade(delay: (50 * index).ms)
                                        .slideX(
                                          begin: 0.1,
                                          end: 0,
                                          delay: (50 * index).ms,
                                          curve: Curves.easeOut,
                                        );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
          ),
          // Bottom Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.grey.withOpacity(0.1)
                      : Colors.white.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _grades.isEmpty
                      ? null
                      : () async {
                          try {
                            await _db.saveGrades(
                              widget.course.id,
                              _getFormattedPeriod(_selectedPeriod),
                              _grades,
                            );
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Notas guardadas con éxito'),
                                ),
                              );
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Error al guardar las notas'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Guardar Cambios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.light
                        ? Colors.grey.shade100
                        : Colors.white.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to handle _exportGrades
  Future<void> _exportGrades(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final allGrades = await _db.getAllGradesForCourse(widget.course.id);
      final studentsList = await _db.streamStudents(widget.course.id).first;

      List<List<dynamic>> rows = [];
      List<dynamic> header = ['Nombre del Estudiante'];

      // Add a column for each evaluation period that has data
      List<String> validPeriods = [];
      for (var period in _evaluationPeriods) {
        String formatted = _getFormattedPeriod(period);
        if (allGrades.containsKey(formatted)) {
          validPeriods.add(formatted);
          header.add(period);
        }
      }
      // If no valid periods but current is selected, add it at least
      if (validPeriods.isEmpty) {
        validPeriods.add(_getFormattedPeriod(_selectedPeriod));
        header.add(_selectedPeriod);
      }

      rows.add(header);

      for (var student in studentsList) {
        List<dynamic> row = [student.name];
        for (var formattedPeriod in validPeriods) {
          if (allGrades.containsKey(formattedPeriod) &&
              allGrades[formattedPeriod]!.containsKey(student.id)) {
            row.add(allGrades[formattedPeriod]![student.id]);
          } else {
            row.add('-');
          }
        }
        rows.add(row);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/notas_${widget.course.name.replaceAll(' ', '_')}.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        await Share.shareXFiles([
          XFile(path),
        ], text: 'Reporte de notas - ${widget.course.name}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    }
  }
}

class _InfoBox extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _InfoBox({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? AppTheme.backgroundLight
            : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradeItem extends StatelessWidget {
  final String name;
  final String id;
  final String attendance;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _GradeItem({
    required this.name,
    required this.id,
    required this.attendance,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey.shade100
                : Colors.grey.shade800,
          ),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage('https://via.placeholder.com/150'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '$id • Asistencia: $attendance',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                decoration: InputDecoration(
                  hintText: '0.0',
                  hintStyle: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
