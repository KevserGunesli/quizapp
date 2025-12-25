import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClassroomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a new classroom
  Future<String> createClassroom(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    String code = _generateClassroomCode();

    await _firestore.collection('Classrooms').add({
      'teacherId': user.uid,
      'name': name,
      'code': code,
      'studentIds': [],
      'createdAt': FieldValue.serverTimestamp(),
    });

    return code;
  }

  Future<void> joinClassroom(String code) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final query = await _firestore
        .collection('Classrooms')
        .where('code', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Sınıf bulunamadı");
    }

    final doc = query.docs.first;
    final List studentIds = doc['studentIds'] ?? [];

    if (studentIds.contains(user.uid)) {
      throw Exception("Zaten bu sınıftasınız");
    }

    await doc.reference.update({
      'studentIds': FieldValue.arrayUnion([user.uid]),
    });
  }

  // Add a quiz to a classroom
  Future<void> addQuizToClassroom(
    String classroomId,
    String title,
    int timeLimitMinutes,
    List<Map<String, dynamic>> questions,
  ) async {
    await _firestore
        .collection('Classrooms')
        .doc(classroomId)
        .collection('Quizzes')
        .add({
          'title': title,
          'timeLimitMinutes': timeLimitMinutes,
          'questions': questions,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  // Delete a quiz
  Future<void> deleteQuiz(String classroomId, String quizId) async {
    await _firestore
        .collection('Classrooms')
        .doc(classroomId)
        .collection('Quizzes')
        .doc(quizId)
        .delete();
  }

  // Update a quiz
  Future<void> updateQuiz(
    String classroomId,
    String quizId,
    String title,
    int timeLimitMinutes,
    List<Map<String, dynamic>> questions,
  ) async {
    await _firestore
        .collection('Classrooms')
        .doc(classroomId)
        .collection('Quizzes')
        .doc(quizId)
        .update({
          'title': title,
          'timeLimitMinutes': timeLimitMinutes,
          'questions': questions,
        });
  }

  // Get classrooms for teacher
  Stream<QuerySnapshot> getTeacherClassrooms() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('Classrooms')
        .where('teacherId', isEqualTo: user.uid)
        .snapshots();
  }

  // Get classrooms for student
  Stream<QuerySnapshot> getStudentClassrooms() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('Classrooms')
        .where('studentIds', arrayContains: user.uid)
        .snapshots();
  }

  // Get quizzes for a classroom
  Stream<QuerySnapshot> getClassroomQuizzes(String classroomId) {
    return _firestore
        .collection('Classrooms')
        .doc(classroomId)
        .collection('Quizzes')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Save quiz result
  Future<void> saveQuizResult(
    String classroomId,
    String quizId,
    int score,
    int totalQuestions,
  ) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('Classrooms')
        .doc(classroomId)
        .collection('Quizzes')
        .doc(quizId)
        .collection('Results')
        .doc(user.uid)
        .set({
          'userId': user.uid,
          'score': score,
          'totalQuestions': totalQuestions,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  // Get students in a classroom
  Future<List<Map<String, dynamic>>> getStudentsInClassroom(
    String classroomId,
  ) async {
    final doc = await _firestore
        .collection('Classrooms')
        .doc(classroomId)
        .get();
    if (!doc.exists) return [];

    final List studentIds = doc['studentIds'] ?? [];
    if (studentIds.isEmpty) return [];

    List<Map<String, dynamic>> students = [];

    for (String id in studentIds) {
      final userDoc = await _firestore.collection('userData').doc(id).get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        data['uid'] = id;
        students.add(data);
      }
    }

    return students;
  }

  String _generateClassroomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }
}
