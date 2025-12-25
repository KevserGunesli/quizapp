import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/Views/quiz_screen.dart';

class ClassroomQuizzesScreen extends StatelessWidget {
  final String classroomId;
  final String classroomName;

  const ClassroomQuizzesScreen({
    super.key,
    required this.classroomId,
    required this.classroomName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(classroomName),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Classrooms')
            .doc(classroomId)
            .collection('Quizzes')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text("Hata oluştu"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Bu sınıfta henüz quiz yok"));
          }

          final quizzes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: quizzes.length,
            itemBuilder: (context, index) {
              final quizData = quizzes[index].data() as Map<String, dynamic>;
              final quizId = quizzes[index].id;
              final title = quizData['title'] ?? 'İsimsiz Quiz';

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                return const SizedBox.shrink();
              }

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('Classrooms')
                    .doc(classroomId)
                    .collection('Quizzes')
                    .doc(quizId)
                    .collection('Results')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      margin: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                      child: ListTile(title: Text("Yükleniyor...")),
                    );
                  }

                  bool isCompleted = snapshot.hasData && snapshot.data!.exists;
                  String subtitleText =
                      "${quizData['questions']?.length ?? 0} Soru";

                  if (isCompleted) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final score = data['score'];
                    final total = data['totalQuestions'];
                    subtitleText = "Tamamlandı - Puan: $score / $total";
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 8,
                    ),
                    color: isCompleted ? Colors.grey.shade100 : Colors.white,
                    child: ListTile(
                      leading: Icon(
                        Icons.quiz,
                        color: isCompleted ? Colors.grey : Colors.blueAccent,
                      ),
                      title: Text(
                        title,
                        style: TextStyle(
                          color: isCompleted ? Colors.grey : Colors.black,
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      subtitle: Text(
                        subtitleText,
                        style: TextStyle(
                          color: isCompleted
                              ? Colors.green
                              : Colors.grey.shade600,
                          fontWeight: isCompleted
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isCompleted
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : const Icon(Icons.arrow_forward_ios),
                      onTap: isCompleted
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuizScreen(
                                    categoryName: title,
                                    classroomId: classroomId,
                                    quizId: quizId,
                                  ),
                                ),
                              );
                            },
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
