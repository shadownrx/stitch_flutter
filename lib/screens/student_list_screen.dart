import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import '../theme/app_theme.dart';
import '../services/database_service.dart';
import '../models/course.dart';
import '../models/student.dart';
import 'student_detail_screen.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final DatabaseService _db = DatabaseService();
  String? _selectedCourseId;

  @override
  Widget build(BuildContext context) {
    final authUser = Provider.of<auth.User?>(context);
    if (authUser == null) return const Center(child: Text('No autenticado'));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Gestión de Alumnos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Course Selector
          _buildCourseSelector(authUser.uid),

          Expanded(
            child: _selectedCourseId == null
                ? const Center(
                    child: Text('Selecciona un curso para ver los alumnos'),
                  )
                : StreamBuilder<List<Student>>(
                    stream: _db.streamStudents(_selectedCourseId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text('No hay alumnos en este curso.'),
                        );
                      }

                      final students = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return _buildStudentCard(student);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: _selectedCourseId == null
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddStudentDialog(context),
              backgroundColor: AppTheme.primaryBlue,
              child: const Icon(Icons.add, color: Colors.white),
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
              if (nameController.text.isNotEmpty && _selectedCourseId != null) {
                await _db.addStudent(_selectedCourseId!, nameController.text);
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

  Widget _buildCourseSelector(String teacherId) {
    return StreamBuilder<List<Course>>(
      stream: _db.streamCourses(teacherId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final courses = snapshot.data!;

        // Safeguard
        if (_selectedCourseId != null &&
            !courses.any((c) => c.id == _selectedCourseId)) {
          _selectedCourseId = null;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: 'Selecciona un curso',
              prefixIcon: const Icon(
                Icons.book_outlined,
                color: AppTheme.primaryBlue,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).brightness == Brightness.light
                  ? AppTheme.backgroundLight
                  : Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            initialValue: _selectedCourseId,
            dropdownColor: Theme.of(context).cardTheme.color,
            items: courses
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (value) {
              setState(() => _selectedCourseId = value);
            },
          ),
        );
      },
    );
  }

  Widget _buildStudentCard(Student student) {
    return InkWell(
      onTap: () async {
        if (_selectedCourseId != null) {
          final authUser = Provider.of<auth.User?>(context, listen: false);
          if (authUser != null) {
            // Fetch the course object to pass to the detail screen
            final courses = await _db.getCourses(authUser.uid);
            final course = courses.firstWhere((c) => c.id == _selectedCourseId);

            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      StudentDetailScreen(student: student, course: course),
                ),
              );
            }
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.accentBlue,
              backgroundImage: student.photoUrl != null
                  ? NetworkImage(student.photoUrl!)
                  : null,
              child: student.photoUrl == null
                  ? Text(
                      student.name.isNotEmpty ? student.name[0] : '?',
                      style: const TextStyle(
                        color: AppTheme.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    'ID: ${student.id.substring(0, 8)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _showDeleteConfirm(student),
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(Student student) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Estudiante'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a ${student.name}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (_selectedCourseId != null) {
                await _db.deleteStudent(_selectedCourseId!, student.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Estudiante eliminado')),
                  );
                }
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
