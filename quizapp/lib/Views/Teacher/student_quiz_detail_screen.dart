import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class StudentQuizDetailScreen extends StatefulWidget {
  final String studentName;
  final String quizTitle;
  final int score;
  final int totalQuestions;
  final String classroomId;
  final String quizId;
  final String studentId;

  const StudentQuizDetailScreen({
    super.key,
    required this.studentName,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.classroomId,
    required this.quizId,
    required this.studentId,
  });

  @override
  State<StudentQuizDetailScreen> createState() =>
      _StudentQuizDetailScreenState();
}

class _StudentQuizDetailScreenState extends State<StudentQuizDetailScreen> {
  int touchedIndex = -1;
  bool _isLoaded = false;
  List<Map<String, dynamic>> questions = [];
  Map<int, int> userAnswers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
    Future.delayed(const Duration(milliseconds: 100), () {
      setState(() {
        _isLoaded = true;
      });
    });
  }

  Future<void> _fetchDetails() async {
    try {
      // Fetch Quiz Questions
      final quizDoc = await FirebaseFirestore.instance
          .collection('Classrooms')
          .doc(widget.classroomId)
          .collection('Quizzes')
          .doc(widget.quizId)
          .get();

      // Fetch User Answers
      final resultDoc = await FirebaseFirestore.instance
          .collection('Classrooms')
          .doc(widget.classroomId)
          .collection('Quizzes')
          .doc(widget.quizId)
          .collection('Results')
          .doc(widget.studentId)
          .get();

      if (quizDoc.exists && resultDoc.exists) {
        final quizData = quizDoc.data();
        final resultData = resultDoc.data();

        if (quizData != null && quizData['questions'] != null) {
          var questionsList = quizData['questions'];
          if (questionsList is List) {
            questions = questionsList.map((q) {
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
          }
        }

        if (resultData != null && resultData['userAnswers'] != null) {
          Map<String, dynamic> answersMap = resultData['userAnswers'];
          userAnswers = answersMap.map(
            (key, value) => MapEntry(int.parse(key), value as int),
          );
        }
      }
    } catch (e) {
      debugPrint("Error fetching details: $e");
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int incorrect = widget.totalQuestions - widget.score;
    final double percentage = (widget.score / widget.totalQuestions * 100);

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.studentName} - ${widget.quizTitle}"),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Quiz Sonucu",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  height: 250,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback:
                                (FlTouchEvent event, pieTouchResponse) {
                                  setState(() {
                                    if (!event.isInterestedForInteractions ||
                                        pieTouchResponse == null ||
                                        pieTouchResponse.touchedSection ==
                                            null) {
                                      touchedIndex = -1;
                                      return;
                                    }
                                    touchedIndex = pieTouchResponse
                                        .touchedSection!
                                        .touchedSectionIndex;
                                  });
                                },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 5,
                          centerSpaceRadius: 90,
                          sections: showingSections(widget.score, incorrect),
                          startDegreeOffset: -90,
                        ),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCirc,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            touchedIndex == 0
                                ? "Doğru"
                                : touchedIndex == 1
                                ? "Yanlış"
                                : "Başarı",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            touchedIndex == 0
                                ? "${widget.score}"
                                : touchedIndex == 1
                                ? "$incorrect"
                                : "${percentage.toStringAsFixed(0)}%",
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: touchedIndex == 0
                                  ? const Color(0xFF00BFA5)
                                  : touchedIndex == 1
                                  ? const Color(0xFFFF5252)
                                  : Colors.blueAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                if (isLoading)
                  const CircularProgressIndicator()
                else if (questions.isNotEmpty)
                  _buildAnswerList(),
                // Additional stats or info could go here
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        final correctOptionIndex = question['correctOptionKey'] as int;
        final userOptionIndex = userAnswers[index];
        final options = question['options'] as List<String>;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Soru ${index + 1}: ${question['question']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(options.length, (optIndex) {
                  Color color = Colors.black;
                  FontWeight fontWeight = FontWeight.normal;
                  IconData? icon;

                  if (optIndex == correctOptionIndex) {
                    color = Colors.green;
                    fontWeight = FontWeight.bold;
                    icon = Icons.check_circle;
                  } else if (optIndex == userOptionIndex) {
                    color = Colors.red;
                    fontWeight = FontWeight.bold;
                    icon = Icons.cancel;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: color, size: 20),
                          const SizedBox(width: 8),
                        ] else
                          const SizedBox(width: 28), // Indent for alignment
                        Expanded(
                          child: Text(
                            options[optIndex],
                            style: TextStyle(
                              color: color,
                              fontWeight: fontWeight,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (userOptionIndex == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 8, left: 28),
                    child: Text(
                      "Boş bırakıldı",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<PieChartSectionData> showingSections(int score, int incorrect) {
    return List.generate(2, (i) {
      final isTouched = i == touchedIndex;
      final radius = isTouched ? 35.0 : 25.0;

      switch (i) {
        case 0:
          return PieChartSectionData(
            value: _isLoaded ? score.toDouble() : 0,
            title: '',
            radius: radius,
            gradient: const LinearGradient(
              colors: [Color(0xFF69F0AE), Color(0xFF00BFA5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            badgeWidget: isTouched
                ? _Badge(
                    Icons.check_circle,
                    size: 40,
                    borderColor: const Color(0xFF00BFA5),
                  )
                : null,
            badgePositionPercentageOffset: 1.5,
          );
        case 1:
          return PieChartSectionData(
            value: _isLoaded ? incorrect.toDouble() : 0,
            title: '',
            radius: radius,
            gradient: const LinearGradient(
              colors: [Color(0xFFFF8A80), Color(0xFFFF5252)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            badgeWidget: isTouched
                ? _Badge(
                    Icons.cancel,
                    size: 40,
                    borderColor: const Color(0xFFFF5252),
                  )
                : null,
            badgePositionPercentageOffset: 1.5,
          );
        default:
          throw Exception('Oh no');
      }
    });
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.icon, {required this.size, required this.borderColor});
  final IconData icon;
  final double size;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: .5),
            offset: const Offset(3, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Icon(icon, color: borderColor, size: size * 0.6),
      ),
    );
  }
}
