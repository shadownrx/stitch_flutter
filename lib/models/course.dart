class Course {
  final String id;
  final String name;
  final String institutionId;
  final String? room;

  Course({
    required this.id,
    required this.name,
    required this.institutionId,
    this.room,
  });

  factory Course.fromMap(Map<String, dynamic> data, String documentId) {
    return Course(
      id: documentId,
      name: data['name'] ?? '',
      institutionId: data['institutionId'] ?? '',
      room: data['room'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'institutionId': institutionId, 'room': room};
  }
}
