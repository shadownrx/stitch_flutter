import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher.dart';
import '../models/course.dart';
import '../models/student.dart';
import '../models/activity.dart';
import '../models/class_plan.dart';
import '../models/institution.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Get Teacher Data
  Future<Teacher?> getTeacher(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('teachers').doc(uid).get();
      if (doc.exists) {
        return Teacher.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting teacher: $e');
      return null;
    }
  }

  // Create or update teacher profile
  Future<Teacher?> createTeacher(
    String uid,
    String name,
    String email, {
    String? photoUrl,
  }) async {
    try {
      final docRef = _db.collection('teachers').doc(uid);
      final data = {
        'name': name,
        'email': email,
        'photoUrl': photoUrl,
        'institutionIds': [],
        'createdAt': FieldValue.serverTimestamp(),
      };

      await docRef.set(data, SetOptions(merge: true));
      final doc = await docRef.get();
      return Teacher.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error creating teacher: $e');
      return null;
    }
  }

  // Get single institution
  Future<Institution?> getInstitution(String id) async {
    try {
      DocumentSnapshot doc = await _db.collection('institutions').doc(id).get();
      if (doc.exists) {
        return Institution.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting institution: $e');
      return null;
    }
  }

  // Stream institutions for a teacher
  Stream<List<Institution>> streamInstitutions(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);
    return _db
        .collection('institutions')
        .where(FieldPath.documentId, whereIn: ids)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Institution.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Create a new institution and link it to the teacher
  Future<String?> createInstitution(
    String teacherId,
    String name,
    String? address,
  ) async {
    try {
      // 1. Create the institution
      DocumentReference instRef = await _db.collection('institutions').add({
        'name': name,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 2. Link to teacher
      await _db.collection('teachers').doc(teacherId).update({
        'institutionIds': FieldValue.arrayUnion([instRef.id]),
      });

      return instRef.id;
    } catch (e) {
      print('Error creating institution: $e');
      return null;
    }
  }

  // Join an existing institution by ID
  Future<bool> joinInstitution(String teacherId, String institutionId) async {
    try {
      // Check if institution exists
      DocumentSnapshot instDoc = await _db
          .collection('institutions')
          .doc(institutionId)
          .get();
      if (!instDoc.exists) return false;

      // Link to teacher
      await _db.collection('teachers').doc(teacherId).update({
        'institutionIds': FieldValue.arrayUnion([institutionId]),
      });

      return true;
    } catch (e) {
      print('Error joining institution: $e');
      return false;
    }
  }

  Stream<List<Course>> streamCourses(
    String teacherId, {
    String? institutionId,
  }) {
    var query = _db
        .collection('courses')
        .where('teacherId', isEqualTo: teacherId);
    if (institutionId != null) {
      query = query.where('institutionId', isEqualTo: institutionId);
    }
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Course.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  // Get Courses for a Teacher (Future)
  Future<List<Course>> getCourses(String teacherId) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('courses')
          .where('teacherId', isEqualTo: teacherId)
          .get();
      return snapshot.docs
          .map(
            (doc) => Course.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    } catch (e) {
      print('Error getting courses: $e');
      return [];
    }
  }

  // Get Grades
  Future<Map<String, double>> getGrades(
    String courseId,
    String evaluationId,
  ) async {
    try {
      final doc = await _db
          .collection('courses')
          .doc(courseId)
          .collection('grades')
          .doc(evaluationId)
          .get();
      if (doc.exists && doc.data()!.containsKey('grades')) {
        final gradesMap = doc.data()!['grades'] as Map<String, dynamic>;
        return gradesMap.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        );
      }
      return {};
    } catch (e) {
      print('Error getting grades: $e');
      return {};
    }
  }

  // Save Grades
  Future<void> saveGrades(
    String courseId,
    String evaluationId,
    Map<String, double> grades,
  ) async {
    try {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('grades')
          .doc(evaluationId)
          .set({
            'updatedAt': FieldValue.serverTimestamp(),
            'grades': grades,
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving grades: $e');
      throw e;
    }
  }

  // Create a new course
  Future<String?> createCourse(
    String teacherId,
    String institutionId,
    String name, {
    String? room,
  }) async {
    try {
      DocumentReference docRef = await _db.collection('courses').add({
        'teacherId': teacherId,
        'institutionId': institutionId,
        'name': name,
        'room': room,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating course: $e');
      return null;
    }
  }

  // Get Students for a Course
  Stream<List<Student>> streamStudents(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('students')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Student.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Stream activities for a course
  Stream<List<Activity>> streamActivities(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('activities')
        .orderBy('deadline')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Activity.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Create a new activity
  Future<String?> createActivity({
    required String courseId,
    required String title,
    required String subtitle,
    required String type,
    required DateTime deadline,
    String status = 'PENDIENTE',
  }) async {
    try {
      final docRef = await _db
          .collection('courses')
          .doc(courseId)
          .collection('activities')
          .add({
            'courseId': courseId,
            'title': title,
            'subtitle': subtitle,
            'type': type,
            'status': status,
            'deadline': deadline.toIso8601String(),
            'completedCount': 0,
            'totalCount': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
      return docRef.id;
    } catch (e) {
      print('Error creating activity: $e');
      return null;
    }
  }

  // Stream class plans for a course
  Stream<List<ClassPlan>> streamClassPlans(String courseId) {
    return _db
        .collection('courses')
        .doc(courseId)
        .collection('class_plans')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ClassPlan.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // Create a new class plan
  Future<String?> createClassPlan({
    required String courseId,
    required String title,
    required String subject,
    required String description,
    required DateTime date,
    List<String> objectives = const [],
    List<Map<String, dynamic>> resources = const [],
    String imageUrl = '',
  }) async {
    try {
      final docRef = await _db
          .collection('courses')
          .doc(courseId)
          .collection('class_plans')
          .add({
            'courseId': courseId,
            'title': title,
            'subject': subject,
            'description': description,
            'date': date.toIso8601String(),
            'objectives': objectives,
            'resources': resources,
            'imageUrl': imageUrl,
            'createdAt': FieldValue.serverTimestamp(),
          });
      return docRef.id;
    } catch (e) {
      print('Error creating class plan: $e');
      return null;
    }
  }

  // Save Attendance
  Future<void> saveAttendance(
    String courseId,
    DateTime date,
    Map<String, String> attendance,
  ) async {
    try {
      String dateStr = '${date.year}-${date.month}-${date.day}';
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .doc(dateStr)
          .set({'date': Timestamp.fromDate(date), 'attendance': attendance});
    } catch (e) {
      print('Error saving attendance: $e');
    }
  }

  // Add student to a course
  Future<void> addStudent(
    String courseId,
    String name, {
    String? photoUrl,
  }) async {
    try {
      await _db.collection('courses').doc(courseId).collection('students').add({
        'name': name,
        'photoUrl': photoUrl,
      });
    } catch (e) {
      print('Error adding student: $e');
    }
  }

  // Delete student from a course
  Future<void> deleteStudent(String courseId, String studentId) async {
    try {
      await _db
          .collection('courses')
          .doc(courseId)
          .collection('students')
          .doc(studentId)
          .delete();
    } catch (e) {
      print('Error deleting student: $e');
    }
  }

  // Get attendance by date range
  Future<List<Map<String, dynamic>>> getAttendanceByDateRange(
    String courseId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final snapshot = await _db
          .collection('courses')
          .doc(courseId)
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
          .orderBy('date', descending: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      print('Error getting attendance: $e');
      return [];
    }
  }

  // Get all grades for a course (for CSV export)
  Future<Map<String, Map<String, double>>> getAllGradesForCourse(
    String courseId,
  ) async {
    try {
      final snapshot = await _db
          .collection('courses')
          .doc(courseId)
          .collection('grades')
          .get();

      Map<String, Map<String, double>> allGrades = {};

      for (var doc in snapshot.docs) {
        if (doc.data().containsKey('grades')) {
          final gradesMap = doc.data()['grades'] as Map<String, dynamic>;
          allGrades[doc.id] = gradesMap.map(
            (key, value) => MapEntry(key, (value as num).toDouble()),
          );
        }
      }
      return allGrades;
    } catch (e) {
      print('Error getting all grades: $e');
      return {};
    }
  }
}
