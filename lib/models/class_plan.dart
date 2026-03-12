class ClassPlan {
  final String id;
  final String courseId;
  final String title;
  final String subject;
  final DateTime date;
  final String description;
  final List<String> objectives;
  final List<Map<String, dynamic>> resources;
  final String imageUrl;
  final String status; // PENDIENTE, COMPLETADO

  ClassPlan({
    required this.id,
    required this.courseId,
    required this.title,
    required this.subject,
    required this.date,
    required this.description,
    required this.objectives,
    required this.resources,
    required this.imageUrl,
    this.status = 'PENDIENTE',
  });

  factory ClassPlan.fromMap(String id, Map<String, dynamic> map) {
    return ClassPlan(
      id: id,
      courseId: map['courseId'] ?? '',
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      description: map['description'] ?? '',
      objectives: List<String>.from(map['objectives'] ?? []),
      resources: List<Map<String, dynamic>>.from(map['resources'] ?? []),
      imageUrl: map['imageUrl'] ?? 'https://via.placeholder.com/600x400',
      status: map['status'] ?? 'PENDIENTE',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'subject': subject,
      'date': date.toIso8601String(),
      'description': description,
      'objectives': objectives,
      'resources': resources,
      'imageUrl': imageUrl,
      'status': status,
    };
  }
}
