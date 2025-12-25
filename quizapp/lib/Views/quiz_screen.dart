// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/Views/result_screen.dart';
import 'package:quizapp/Widgets/my_button.dart';

class QuizScreen extends StatefulWidget {
  final String categoryName;
  final String? classroomId;
  final String? quizId;

  const QuizScreen({
    super.key,
    required this.categoryName,
    this.classroomId,
    this.quizId,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> questions = [];
  int currentQuestionIndex = 0, score = 0;
  int? selectedOption;
  bool hasAnswered = false, isLoading = true;
  Map<int, int> userAnswers = {};

  @override
  void initState() {
    _fetchQuestions();
    super.initState();
  }

  //to fetch the question
  Future<void> _fetchQuestions() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot;
      if (widget.classroomId != null && widget.quizId != null) {
        snapshot = await FirebaseFirestore.instance
            .collection('Classrooms')
            .doc(widget.classroomId)
            .collection('Quizzes')
            .doc(widget.quizId)
            .get();
      } else {
        snapshot = await FirebaseFirestore.instance
            .collection('ListofQuestions')
            .doc(widget.categoryName)
            .get();
      }

      if (snapshot.exists) {
        var data = snapshot.data();
        if (data != null && data['questions'] != null) {
          var questionsList = data['questions'];

          if (questionsList is List) {
            var fetchedQuestions = questionsList.map((q) {
              var questionData = q as Map<String, dynamic>;
              var options = (questionData['options'] as List).cast<String>();
              var answer = questionData['answer'] as String;
              var correctIndex = options.indexOf(answer);

              return {
                'question': questionData['question'] ?? "No Question",
                'correctOptionKey': correctIndex,
                'options': options,
              };
            }).toList();

            setState(() {
              questions = fetchedQuestions;
            });
          }
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  //doğru cevabı kontrol et
  void _checkAnswer(int index) {
    setState(() {
      hasAnswered = true;
      selectedOption = index;
      userAnswers[currentQuestionIndex] = index;
      if (questions[currentQuestionIndex]['correctOptionKey'] == index) {
        score++;
      }
    });
  }

  Future<void> _nextQuestion() async {
    if (currentQuestionIndex < questions.length - 1) {
      setState(() {
        currentQuestionIndex++;
        hasAnswered = false;
        selectedOption = null;
      });
    } else {
      await _updateUserScore();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            score: score,
            totalQuestions: questions.length,
            questions: questions,
            userAnswers: userAnswers,
          ),
        ),
      );
    }
  }

  // Future<void> _updateUserScore() async {
  //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ResultScreen()));
  // }

  Future<void> _updateUserScore() async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      var userRef = FirebaseFirestore.instance
          .collection("userData")
          .doc(user.uid);

      // Save detailed result
      await FirebaseFirestore.instance.collection('QuizResults').add({
        'userId': user.uid,
        'categoryName': widget.categoryName,
        'score': score,
        'totalQuestions': questions.length,
        'timestamp': FieldValue.serverTimestamp(),
        'classroomId': widget.classroomId,
        'quizId': widget.quizId,
      });

      if (widget.classroomId != null && widget.quizId != null) {
        await FirebaseFirestore.instance
            .collection('Classrooms')
            .doc(widget.classroomId)
            .collection('Quizzes')
            .doc(widget.quizId)
            .collection('Results')
            .doc(user.uid)
            .set({
              'score': score,
              'totalQuestions': questions.length,
              'timestamp': FieldValue.serverTimestamp(),
              'userAnswers': userAnswers.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            });
      }

      if (widget.classroomId == null) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          var snapshot = await transaction.get(userRef);

          if (!snapshot.exists) return;

          int existingScore = snapshot['score'] ?? 0;

          transaction.update(userRef, {'score': existingScore + score});
        });
      }
    } catch (e) {
      debugPrint('error updating score $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sonuç kaydedilirken hata oluştu: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (questions.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: Text("Bu kategori için soru bulunamadı.")),
      );
    }
    return Scaffold(
      appBar: _buildAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / questions.length,
              backgroundColor: Colors.grey[300],
              color: Colors.blueAccent,
              minHeight: 8.0,
            ),
            const SizedBox(height: 20.0),
            //sorular için
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                questions[currentQuestionIndex]['question'],
                style: const TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            //cevap seçenekleri için
            const SizedBox(height: 30),
            Expanded(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  return _buildOption(index);
                },
                separatorBuilder: (_, __) => const SizedBox(height: 15.0),
                itemCount: questions[currentQuestionIndex]['options'].length,
              ),
            ),
            //conditionally render the Next button
            if (hasAnswered)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: MyButton(
                  onTap: _nextQuestion,
                  buttonText: currentQuestionIndex == questions.length - 1
                      ? "Finish"
                      : "Next",
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(int index) {
    bool isCorrect =
        questions[currentQuestionIndex]['correctOptionKey'] == index;
    bool isSelected = selectedOption == index;
    Color bgColor = hasAnswered
        ? (isCorrect
              ? Colors.green.shade300
              : isSelected
              ? Colors.red.shade300
              : Colors.grey.shade200)
        : Colors.grey.shade200;
    Color textColor = hasAnswered && (isCorrect || isSelected)
        ? Colors.white
        : Colors.black;
    return InkWell(
      onTap: hasAnswered
          ? null
          : () {
              _checkAnswer(index);
            },
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        padding: EdgeInsets.symmetric(vertical: 15, horizontal: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade400,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          questions[currentQuestionIndex]['options'][index],
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16.0,
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      foregroundColor: Colors.white,
      title: Text(
        "${widget.categoryName} (${currentQuestionIndex + 1}/${questions.length})",
      ),
      backgroundColor: Colors.blueAccent,
    );
  }
}
