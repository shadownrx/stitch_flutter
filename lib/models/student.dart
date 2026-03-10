class Student {
  final String id;
  final String name;
  final String? photoUrl;

  Student({required this.id, required this.name, this.photoUrl});

  factory Student.fromMap(Map<String, dynamic> data, String documentId) {
    return Student(
      id: documentId,
      name: data['name'] ?? '',
      photoUrl: data['photoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'photoUrl': photoUrl};
  }
}
