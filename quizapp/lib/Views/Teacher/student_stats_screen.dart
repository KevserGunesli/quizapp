import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/Views/Teacher/student_quiz_detail_screen.dart';

class StudentStatsScreen extends StatelessWidget {
  final String studentId;
  final String studentName;
  final String classroomId;

  const StudentStatsScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.classroomId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$studentName - İstatistikler')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Classrooms')
            .doc(classroomId)
            .collection('Quizzes')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Bir hata oluştu'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final quizzes = snapshot.data!.docs;

          if (quizzes.isEmpty) {
            return const Center(child: Text('Bu sınıfta henüz quiz yok.'));
          }

          return ListView.builder(
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quiz = quizzes[index];
              final quizId = quiz.id;
              final quizTitle = quiz['title'];

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Classrooms')
                    .doc(classroomId)
                    .collection('Quizzes')
                    .doc(quizId)
                    .collection('Results')
                    .doc(studentId)
                    .snapshots(),
                builder: (context, resultSnapshot) {
                  if (!resultSnapshot.hasData) {
                    return ListTile(
                      title: Text(quizTitle),
                      subtitle: const Text('Yükleniyor...'),
                    );
                  }

                  final resultDoc = resultSnapshot.data!;

                  if (!resultDoc.exists) {
                    return ListTile(
                      title: Text(quizTitle),
                      subtitle: const Text('Girilmedi'),
                      trailing: const Icon(Icons.close, color: Colors.red),
                    );
                  }

                  final data = resultDoc.data() as Map<String, dynamic>;
                  final score = data['score'];
                  final total = data['totalQuestions'];

                  return ListTile(
                    title: Text(quizTitle),
                    subtitle: Text('Puan: $score / $total'),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.blueAccent,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentQuizDetailScreen(
                            studentName: studentName,
                            quizTitle: quizTitle,
                            score: score,
                            totalQuestions: total,
                            classroomId: classroomId,
                            quizId: quizId,
                            studentId: studentId,
                          ),
                        ),
                      );
                    },
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
