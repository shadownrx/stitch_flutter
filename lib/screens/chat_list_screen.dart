import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_room.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../models/teacher.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final DatabaseService _db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentUser = authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes'), centerTitle: true),
      body: StreamBuilder<List<ChatRoom>>(
        stream: chatService.streamChatRooms(currentUser?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  const Text('No hay conversaciones activas.'),
                ],
              ),
            );
          }

          final rooms = snapshot.data!;

          return ListView.builder(
            itemCount: rooms.length,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemBuilder: (context, index) {
              final room = rooms[index];
              final otherUserId = room.participants.firstWhere(
                (id) => id != currentUser?.uid,
              );

              return FutureBuilder<Teacher?>(
                future: _db.getTeacher(otherUserId),
                builder: (context, teacherSnapshot) {
                  final teacher = teacherSnapshot.data;
                  final name = teacher?.name ?? 'Cargando...';
                  final photoUrl = teacher?.photoUrl;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: photoUrl != null
                            ? NetworkImage(photoUrl)
                            : null,
                        child: photoUrl == null
                            ? Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                              )
                            : null,
                      ),
                      title: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        room.lastMessage.isNotEmpty
                            ? room.lastMessage
                            : 'Inicia una conversación',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: Text(
                        DateFormat('HH:mm').format(room.lastMessageTime),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          '/chat_detail',
                          arguments: {
                            'roomId': room.id,
                            'otherTeacherName': name,
                            'otherTeacherId': otherUserId,
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // For simplicity, we get the first institution of the teacher
          final teacher = await _db.getTeacher(currentUser?.uid ?? '');
          if (teacher != null && teacher.institutionIds.isNotEmpty) {
            if (context.mounted) {
              Navigator.pushNamed(
                context,
                '/teacher_selection',
                arguments: teacher.institutionIds.first,
              );
            }
          }
        },
        backgroundColor: AppTheme.primaryBlue,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }
}
