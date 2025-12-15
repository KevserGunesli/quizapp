import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:quizapp/Views/nav_bar_category_selection_screen.dart';
import 'package:quizapp/Widgets/my_button.dart';

class ResultScreen extends StatelessWidget {
  final int score;
  final int totalQuestions;
  const ResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blueAccent,
        title: const Text("Sonuç Ekranı"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Column(
            children: [
              Stack(
                children: [
                  Lottie.network(
                    "https://lottie.host/ac43c2f1-3fc8-4245-8e79-f834cfa00c5c/MQya15WKyU.json",
                    height: 200,
                    width: 300,
                    fit: BoxFit.cover,
                  ),
                ],
              ),

              const Text(
                "QuizCompeleted!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Your Score: $score / $totalQuestions",
                style: const TextStyle(fontSize: 22),
              ),
              Text(
                "${(score / totalQuestions * 100).toStringAsFixed(2)} %",
                style: const TextStyle(fontSize: 22),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: MyButton(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                NavBarCategorySelectionScreen(initialIndex: 1),
                          ),
                          (route) => false,
                        );
                      },
                      buttonText: 'Your Ranking',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
