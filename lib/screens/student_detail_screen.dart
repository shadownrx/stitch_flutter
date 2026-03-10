import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/student.dart';
import '../models/course.dart';
import '../services/database_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  final Course course;

  const StudentDetailScreen({
    super.key,
    required this.student,
    required this.course,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = true;

  Map<String, double> _gradesByPeriod = {};
  int _totalClasses = 0;
  int _presentClasses = 0;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  Future<void> _loadStudentData() async {
    // Load attendance
    final now = DateTime.now();
    // Assuming course started 3 months ago for arbitrary lookup window
    final start = now.subtract(const Duration(days: 90));
    final end = now.add(const Duration(days: 7));

    final attendanceRecords = await _db.getAttendanceByDateRange(
      widget.course.id,
      start,
      end,
    );
    int present = 0;
    int total = 0;

    for (var record in attendanceRecords) {
      if (record.containsKey('attendance')) {
        final Map<String, dynamic> att = record['attendance'];
        if (att.containsKey(widget.student.id)) {
          total++;
          if (att[widget.student.id] == 'Presente') {
            present++;
          }
        }
      }
    }

    // Load grades
    final allGrades = await _db.getAllGradesForCourse(widget.course.id);
    Map<String, double> grades = {};

    allGrades.forEach((period, gradesMap) {
      if (gradesMap.containsKey(widget.student.id)) {
        grades[period] = gradesMap[widget.student.id]!;
      }
    });

    if (mounted) {
      setState(() {
        _totalClasses = total;
        _presentClasses = present;
        _gradesByPeriod = grades;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double attendancePercentage = _totalClasses > 0
        ? (_presentClasses / _totalClasses) * 100
        : 100.0;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Seguimiento del Alumno',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.accentBlue,
                    backgroundImage: widget.student.photoUrl != null
                        ? NetworkImage(widget.student.photoUrl!)
                        : null,
                    child: widget.student.photoUrl == null
                        ? Text(
                            widget.student.name.isNotEmpty
                                ? widget.student.name[0]
                                : '?',
                            style: const TextStyle(
                              color: AppTheme.primaryBlue,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.student.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'ID: ${widget.student.id.substring(0, 8)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats Grid
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Asistencia',
                          value: '${attendancePercentage.toStringAsFixed(1)}%',
                          subtitle: '$_presentClasses / $_totalClasses clases',
                          color: attendancePercentage >= 75
                              ? AppTheme.primaryBlue
                              : AppTheme.errorRed,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          title: 'Promedio General',
                          value: _gradesByPeriod.isEmpty
                              ? '-'
                              : (_gradesByPeriod.values.reduce(
                                          (a, b) => a + b,
                                        ) /
                                        _gradesByPeriod.length)
                                    .toStringAsFixed(1),
                          subtitle: '${_gradesByPeriod.length} evaluaciones',
                          color: AppTheme.warningOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Grades List
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Historial de Notas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_gradesByPeriod.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          'No hay notas registradas para este alumno.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._gradesByPeriod.entries.map((entry) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.light
                                ? Colors.grey.shade100
                                : Colors.grey.shade800,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              entry.key.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.accentBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                entry.value.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
