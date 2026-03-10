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
import 'package:cloud_firestore/cloud_firestore.dart';

class RollCallScreen extends StatefulWidget {
  final Course course;
  const RollCallScreen({super.key, required this.course});

  @override
  State<RollCallScreen> createState() => _RollCallScreenState();
}

class _RollCallScreenState extends State<RollCallScreen> {
  final DatabaseService _db = DatabaseService();
  Map<String, String> _attendance =
      {}; // studentId -> status (Presente, Ausente, Tarde)
  DateTime _selectedDate = DateTime.now();

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadAttendanceForDate();
  }

  Future<void> _loadAttendanceForDate() async {
    // Clear previous attendance locally before loading
    setState(() {
      _attendance.clear();
    });

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('courses')
          .doc(widget.course.id)
          .collection('attendance')
          .doc(
            '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
          )
          .get();

      if (docRef.exists && docRef.data()!.containsKey('attendance')) {
        final Map<String, dynamic> data = docRef.data()!['attendance'];
        if (mounted) {
          setState(() {
            _attendance = data.map(
              (key, value) => MapEntry(key, value.toString()),
            );
          });
        }
      }
    } catch (e) {
      print('Error loading attendance for date: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppTheme.primaryBlue),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadAttendanceForDate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Pase de Lista',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            InkWell(
              onTap: () => _selectDate(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatDate(_selectedDate),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: AppTheme.primaryBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showAddStudentDialog(context),
            icon: const Icon(Icons.person_add_outlined),
          ),
          IconButton(
            onPressed: () => _exportAttendance(context),
            icon: const Icon(Icons.download),
          ),
        ],
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.course.name,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.course.room ?? 'Aula por definir'}',
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'EN CURSO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Student List
                  StreamBuilder<List<Student>>(
                    stream: _db.streamStudents(widget.course.id),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No hay alumnos registrados en este curso.',
                          ),
                        );
                      }

                      final students = snapshot.data!;

                      // Calculate summaries
                      final present = _attendance.values
                          .where((v) => v == 'Presente')
                          .length;
                      final absent = _attendance.values
                          .where((v) => v == 'Ausente')
                          .length;
                      final late = _attendance.values
                          .where((v) => v == 'Tarde')
                          .length;

                      return Column(
                        children: [
                          // Summary Cards
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSummaryCard(
                                'PRESENTES',
                                '$present',
                                const Color(0xFFEEF2FF),
                                AppTheme.primaryBlue,
                              ),
                              _buildSummaryCard(
                                'AUSENTES',
                                '$absent',
                                const Color(0xFFFEF2F2),
                                AppTheme.errorRed,
                              ),
                              _buildSummaryCard(
                                'TARDE',
                                '$late',
                                const Color(0xFFFFFBEB),
                                AppTheme.warningOrange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: students.length,
                            itemBuilder: (context, index) {
                              final student = students[index];
                              final status =
                                  _attendance[student.id] ?? 'Pase de Lista';

                              Color statusColor = Colors.transparent;
                              if (status == 'Presente')
                                statusColor = AppTheme.primaryBlue;
                              if (status == 'Ausente')
                                statusColor = AppTheme.errorRed;
                              if (status == 'Tarde')
                                statusColor = AppTheme.warningOrange;

                              return _buildStudentItem(
                                    student.name,
                                    'ID: ${student.id.substring(0, 7)}...',
                                    status,
                                    statusColor,
                                    studentId: student.id,
                                    isButton: _attendance[student.id] == null,
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
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24),
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ElevatedButton.icon(
          onPressed: () async {
            await _db.saveAttendance(
              widget.course.id,
              _selectedDate,
              _attendance,
            );
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Asistencia guardada con éxito')),
              );
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Finalizar Asistencia'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 60),
            backgroundColor: AppTheme.primaryBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String count,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: textColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentItem(
    String name,
    String id,
    String status,
    Color statusColor, {
    required String studentId,
    bool isButton = false,
  }) {
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
                    id,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isButton)
              OutlinedButton(
                onPressed: () {
                  _showStatusPicker(studentId);
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey.shade300
                        : Colors.grey.shade700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  status,
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              GestureDetector(
                onTap: () => _showStatusPicker(studentId),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.more_vert, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Añadir Estudiante'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Nombre Completo',
            hintText: 'Ej: Juan Pérez',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _db.addStudent(widget.course.id, nameController.text);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Estudiante añadido')),
                  );
                }
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _showStatusPicker(String studentId) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryBlue,
                ),
                title: const Text('Presente'),
                onTap: () {
                  setState(() => _attendance[studentId] = 'Presente');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: AppTheme.errorRed),
                title: const Text('Ausente'),
                onTap: () {
                  setState(() => _attendance[studentId] = 'Ausente');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.access_time_filled,
                  color: AppTheme.warningOrange,
                ),
                title: const Text('Tarde'),
                onTap: () {
                  setState(() => _attendance[studentId] = 'Tarde');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportAttendance(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.calendar_view_week,
                color: AppTheme.primaryBlue,
              ),
              title: const Text('Exportar esta semana'),
              onTap: () {
                Navigator.pop(context);
                final now = DateTime.now();
                final start = now.subtract(Duration(days: now.weekday - 1));
                final end = now.add(Duration(days: 7 - now.weekday));
                _generateAndShareCsv(start, end);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.calendar_month,
                color: AppTheme.primaryBlue,
              ),
              title: const Text('Exportar este mes'),
              onTap: () {
                Navigator.pop(context);
                final now = DateTime.now();
                final start = DateTime(now.year, now.month, 1);
                final end = DateTime(now.year, now.month + 1, 0);
                _generateAndShareCsv(start, end);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateAndShareCsv(DateTime start, DateTime end) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final records = await _db.getAttendanceByDateRange(
        widget.course.id,
        start,
        end,
      );
      final studentsList = await _db.streamStudents(widget.course.id).first;

      List<List<dynamic>> rows = [];
      List<dynamic> header = ['Nombre del Estudiante'];
      Set<String> allDateStrs = {};

      for (var record in records) {
        DateTime date = (record['date'] as Timestamp).toDate();
        String dateStr = '${date.day}/${date.month}/${date.year}';
        allDateStrs.add(dateStr);
      }

      List<String> sortedDates = allDateStrs.toList()..sort();
      header.addAll(sortedDates);
      rows.add(header);

      for (var student in studentsList) {
        List<dynamic> row = [student.name];
        for (var dateStr in sortedDates) {
          var recordForDate = records.firstWhere((r) {
            DateTime d = (r['date'] as Timestamp).toDate();
            return '${d.day}/${d.month}/${d.year}' == dateStr;
          }, orElse: () => {});

          if (recordForDate.isNotEmpty && recordForDate['attendance'] != null) {
            final att = recordForDate['attendance'] as Map<String, dynamic>;
            row.add(att[student.id] ?? '-');
          } else {
            row.add('-');
          }
        }
        rows.add(row);
      }

      String csvData = const ListToCsvConverter().convert(rows);

      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/asistencia_${widget.course.name.replaceAll(' ', '_')}.csv';
      final file = File(path);
      await file.writeAsString(csvData);

      if (mounted) {
        Navigator.pop(context);
        await Share.shareXFiles([
          XFile(path),
        ], text: 'Reporte de asistencia - ${widget.course.name}');
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
