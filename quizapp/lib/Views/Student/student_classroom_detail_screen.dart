import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/Service/classroom_service.dart';
import 'package:quizapp/Views/Student/take_quiz_screen.dart';
import 'package:quizapp/Views/Teacher/student_stats_screen.dart'; // Reusing for stats visualization

class StudentClassroomDetailScreen extends StatefulWidget {
  final String classroomId;
  final String classroomName;

  const StudentClassroomDetailScreen({
    super.key,
    required this.classroomId,
    required this.classroomName,
  });

  @override
  State<StudentClassroomDetailScreen> createState() =>
      _StudentClassroomDetailScreenState();
}

class _StudentClassroomDetailScreenState
    extends State<StudentClassroomDetailScreen> {
  final ClassroomService _classroomService = ClassroomService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classroomName),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _classroomService.getClassroomQuizzes(widget.classroomId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Bu sınıfta henüz quiz yok.'));
          }

          final quizzes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quizDoc = quizzes[index];
              final quiz = quizDoc.data() as Map<String, dynamic>;
              final quizId = quizDoc.id;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Classrooms')
                    .doc(widget.classroomId)
                    .collection('Quizzes')
                    .doc(quizId)
                    .collection('Results')
                    .doc(currentUserId)
                    .snapshots(),
                builder: (context, resultSnapshot) {
                  bool isTaken =
                      resultSnapshot.hasData && resultSnapshot.data!.exists;
                  Map<String, dynamic>? resultData;
                  if (isTaken) {
                    resultData =
                        resultSnapshot.data!.data() as Map<String, dynamic>;
                  }

                  return Card(
                    child: ListTile(
                      leading: Icon(
                        isTaken ? Icons.check_circle : Icons.quiz,
                        color: isTaken ? Colors.green : Colors.orange,
                      ),
                      title: Text(quiz['title']),
                      subtitle: Text(
                        isTaken
                            ? 'Puan: ${resultData?['score']} / ${resultData?['totalQuestions']}'
                            : '${quiz['questions'].length} Soru • ${quiz['timeLimitMinutes']} Dakika',
                      ),
                      trailing: isTaken
                          ? IconButton(
                              icon: const Icon(Icons.bar_chart),
                              onPressed: () {
                                // Navigate to stats
                                // We can reuse StudentStatsScreen but filter for this specific quiz or show all
                                // Or maybe a specific QuizResultScreen
                                // For now, let's show a dialog or simple result view
                                // The user asked for "graphs", so maybe StudentStatsScreen is good but it shows all quizzes.
                                // Let's navigate to StudentStatsScreen for this student in this class.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentStatsScreen(
                                      studentId: currentUserId,
                                      studentName:
                                          "Benim İstatistiklerim", // Or get actual name
                                      classroomId: widget.classroomId,
                                    ),
                                  ),
                                );
                              },
                            )
                          : ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TakeQuizScreen(
                                      classroomId: widget.classroomId,
                                      quizId: quizId,
                                      quizData: quiz,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Başla'),
                            ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
