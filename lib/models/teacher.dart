class Teacher {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final List<String> institutionIds;

  Teacher({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    required this.institutionIds,
  });

  factory Teacher.fromMap(Map<String, dynamic> data, String documentId) {
    return Teacher(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      institutionIds: List<String>.from(data['institutionIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'institutionIds': institutionIds,
    };
  }
}
