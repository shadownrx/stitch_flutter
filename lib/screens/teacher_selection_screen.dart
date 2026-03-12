import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/teacher.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class TeacherSelectionScreen extends StatelessWidget {
  final String institutionId;

  const TeacherSelectionScreen({super.key, required this.institutionId});

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Chat'), centerTitle: true),
      body: FutureBuilder<List<Teacher>>(
        future: chatService.searchTeachers(
          currentUser?.uid ?? '',
          institutionId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No se encontraron otros docentes en esta institución.',
              ),
            );
          }

          final teachers = snapshot.data!;

          return ListView.builder(
            itemCount: teachers.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: teacher.photoUrl != null
                        ? NetworkImage(teacher.photoUrl!)
                        : null,
                    child: teacher.photoUrl == null
                        ? Text(teacher.name[0].toUpperCase())
                        : null,
                  ),
                  title: Text(
                    teacher.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(teacher.email),
                  onTap: () async {
                    final roomId = await chatService.getOrCreateChatRoom(
                      currentUser?.uid ?? '',
                      teacher.id,
                    );
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(
                        context,
                        '/chat_detail',
                        arguments: {
                          'roomId': roomId,
                          'otherTeacherName': teacher.name,
                          'otherTeacherId': teacher.id,
                        },
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
