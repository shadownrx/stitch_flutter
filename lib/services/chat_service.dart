import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/chat_room.dart';
import '../models/teacher.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get or create a chat room between two teachers
  Future<String> getOrCreateChatRoom(
    String currentUserId,
    String otherUserId,
  ) async {
    final participants = [currentUserId, otherUserId]..sort();

    final query = await _db
        .collection('chat_rooms')
        .where('participants', isEqualTo: participants)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first.id;
    } else {
      final docRef = await _db.collection('chat_rooms').add({
        'participants': participants,
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    }
  }

  // Send a message
  Future<void> sendMessage(String roomId, String senderId, String text) async {
    final batch = _db.batch();

    final messageRef = _db
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .doc();

    batch.set(messageRef, {
      'senderId': senderId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    final roomRef = _db.collection('chat_rooms').doc(roomId);
    batch.update(roomRef, {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }

  // Stream messages for a specific room
  Stream<List<ChatMessage>> streamMessages(String roomId) {
    return _db
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Stream chat rooms for the current user
  Stream<List<ChatRoom>> streamChatRooms(String userId) {
    return _db
        .collection('chat_rooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatRoom.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Search teachers to start a new chat
  Future<List<Teacher>> searchTeachers(
    String currentUserId,
    String institutionId,
  ) async {
    final snapshot = await _db
        .collection('teachers')
        .where('institutionIds', arrayContains: institutionId)
        .get();

    return snapshot.docs
        .map((doc) => Teacher.fromMap(doc.data(), doc.id))
        .where((teacher) => teacher.id != currentUserId)
        .toList();
  }
}
