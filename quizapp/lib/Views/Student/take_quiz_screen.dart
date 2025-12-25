import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quizapp/Service/classroom_service.dart';

class TakeQuizScreen extends StatefulWidget {
  final String classroomId;
  final String quizId;
  final Map<String, dynamic> quizData;

  const TakeQuizScreen({
    super.key,
    required this.classroomId,
    required this.quizId,
    required this.quizData,
  });

  @override
  State<TakeQuizScreen> createState() => _TakeQuizScreenState();
}

class _TakeQuizScreenState extends State<TakeQuizScreen> {
  final ClassroomService _classroomService = ClassroomService();
  late PageController _pageController;
  late Timer _timer;
  int _remainingSeconds = 0;
  final Map<int, int> _selectedAnswers = {}; // questionIndex -> optionIndex
  int _currentQuestionIndex = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _remainingSeconds = (widget.quizData['timeLimitMinutes'] as int) * 60;
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer.cancel();
        _submitQuiz(timeOut: true);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submitQuiz({bool timeOut = false}) async {
    if (_isSubmitting) return;
    setState(() {
      _isSubmitting = true;
    });
    _timer.cancel();

    int score = 0;
    final questions = widget.quizData['questions'] as List<dynamic>;

    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      final correctAnswer = question['answer'] as String;
      final selectedOptionIndex = _selectedAnswers[i];

      if (selectedOptionIndex != null) {
        final options = question['options'] as List<dynamic>;
        if (options[selectedOptionIndex] == correctAnswer) {
          score++;
        }
      }
    }

    try {
      await _classroomService.saveQuizResult(
        widget.classroomId,
        widget.quizId,
        score,
        questions.length,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(timeOut ? 'Süre Doldu!' : 'Quiz Tamamlandı'),
            content: Text('Puanınız: $score / ${questions.length}'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to detail screen
                },
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Hata oluştu: $e')));
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.quizData['questions'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizData['title']),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(
                _formattedTime,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics:
                  const NeverScrollableScrollPhysics(), // Disable swipe to enforce flow or allow it? Let's disable to prevent accidental skips without seeing. Actually swipe is fine.
              onPageChanged: (index) {
                setState(() {
                  _currentQuestionIndex = index;
                });
              },
              itemCount: questions.length,
              itemBuilder: (context, index) {
                final question = questions[index];
                final options = question['options'] as List<dynamic>;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: RadioGroup<int>(
                    groupValue: _selectedAnswers[index],
                    onChanged: (value) {
                      setState(() {
                        _selectedAnswers[index] = value!;
                      });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Soru ${index + 1}/${questions.length}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          question['questionText'],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ...List.generate(options.length, (optionIndex) {
                          final isSelected =
                              _selectedAnswers[index] == optionIndex;
                          return Card(
                            color: isSelected ? Colors.orange.shade100 : null,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? Colors.orange
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              title: Text(options[optionIndex]),
                              leading: Radio<int>(
                                value: optionIndex,
                                activeColor: Colors.orange,
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedAnswers[index] = optionIndex;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentQuestionIndex > 0)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: const Text('Önceki'),
                  )
                else
                  const SizedBox(),
                if (_currentQuestionIndex < questions.length - 1)
                  ElevatedButton(
                    onPressed: () {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Sonraki'),
                  )
                else
                  ElevatedButton(
                    onPressed: _submitQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Bitir'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
