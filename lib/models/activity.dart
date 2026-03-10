class Activity {
  final String id;
  final String title;
  final String subtitle;
  final String type; // Tarea, Examen, Proyecto
  final String status;
  final DateTime deadline;
  final int completedCount;
  final int totalCount;
  final String courseId;

  Activity({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.status,
    required this.deadline,
    required this.completedCount,
    required this.totalCount,
    required this.courseId,
  });

  factory Activity.fromMap(String id, Map<String, dynamic> map) {
    return Activity(
      id: id,
      title: map['title'] ?? '',
      subtitle: map['subtitle'] ?? '',
      type: map['type'] ?? 'Tarea',
      status: map['status'] ?? 'PENDIENTE',
      deadline: map['deadline'] != null
          ? DateTime.parse(map['deadline'])
          : DateTime.now(),
      completedCount: map['completedCount'] ?? 0,
      totalCount: map['totalCount'] ?? 0,
      courseId: map['courseId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'status': status,
      'deadline': deadline.toIso8601String(),
      'completedCount': completedCount,
      'totalCount': totalCount,
      'courseId': courseId,
    };
  }
}
