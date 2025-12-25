import 'package:flutter/material.dart';
import 'package:quizapp/Service/classroom_service.dart';
import 'package:quizapp/Widgets/snackbar.dart';

class AddClassroomQuizScreen extends StatefulWidget {
  final String classroomId;
  final String? quizId;
  final Map<String, dynamic>? initialData;

  const AddClassroomQuizScreen({
    super.key,
    required this.classroomId,
    this.quizId,
    this.initialData,
  });

  @override
  State<AddClassroomQuizScreen> createState() => _AddClassroomQuizScreenState();
}

class _AddClassroomQuizScreenState extends State<AddClassroomQuizScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _timeLimitController;
  final List<Map<String, dynamic>> _questions = [];
  final ClassroomService _classroomService = ClassroomService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialData?['title'] ?? '',
    );
    _timeLimitController = TextEditingController(
      text: widget.initialData?['timeLimitMinutes']?.toString() ?? '',
    );
    if (widget.initialData != null) {
      final questions = widget.initialData!['questions'] as List<dynamic>;
      for (var q in questions) {
        _questions.add(q as Map<String, dynamic>);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeLimitController.dispose();
    super.dispose();
  }

  void _addQuestion() async {
    final questionController = TextEditingController();
    final option1Controller = TextEditingController();
    final option2Controller = TextEditingController();
    final option3Controller = TextEditingController();
    final option4Controller = TextEditingController();
    String? correctAnswer;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Soru Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(labelText: 'Soru'),
                ),
                TextField(
                  controller: option1Controller,
                  decoration: InputDecoration(
                    labelText: 'Seçenek 1',
                    suffixIcon: IconButton(
                      icon: Icon(
                        correctAnswer == '1'
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                      ),
                      onPressed: () =>
                          setDialogState(() => correctAnswer = '1'),
                    ),
                  ),
                ),
                TextField(
                  controller: option2Controller,
                  decoration: InputDecoration(
                    labelText: 'Seçenek 2',
                    suffixIcon: IconButton(
                      icon: Icon(
                        correctAnswer == '2'
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                      ),
                      onPressed: () =>
                          setDialogState(() => correctAnswer = '2'),
                    ),
                  ),
                ),
                TextField(
                  controller: option3Controller,
                  decoration: InputDecoration(
                    labelText: 'Seçenek 3',
                    suffixIcon: IconButton(
                      icon: Icon(
                        correctAnswer == '3'
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                      ),
                      onPressed: () =>
                          setDialogState(() => correctAnswer = '3'),
                    ),
                  ),
                ),
                TextField(
                  controller: option4Controller,
                  decoration: InputDecoration(
                    labelText: 'Seçenek 4',
                    suffixIcon: IconButton(
                      icon: Icon(
                        correctAnswer == '4'
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                      ),
                      onPressed: () =>
                          setDialogState(() => correctAnswer = '4'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
    );

    if (result == true && correctAnswer != null) {
      final options = [
        option1Controller.text,
        option2Controller.text,
        option3Controller.text,
        option4Controller.text,
      ];

      setState(() {
        _questions.add({
          'question': questionController.text,
          'options': options,
          'answer': options[int.parse(correctAnswer!) - 1],
        });
      });
    }
  }

  Future<void> _saveQuiz() async {
    if (_formKey.currentState!.validate() && _questions.isNotEmpty) {
      try {
        if (widget.quizId != null) {
          await _classroomService.updateQuiz(
            widget.classroomId,
            widget.quizId!,
            _titleController.text,
            int.parse(_timeLimitController.text),
            _questions,
          );
          if (mounted) {
            showSnackBar(context, 'Quiz başarıyla güncellendi');
            Navigator.pop(context);
          }
        } else {
          await _classroomService.addQuizToClassroom(
            widget.classroomId,
            _titleController.text,
            int.parse(_timeLimitController.text),
            _questions,
          );
          if (mounted) {
            showSnackBar(context, 'Quiz başarıyla oluşturuldu');
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Hata: $e');
        }
      }
    } else if (_questions.isEmpty) {
      showSnackBar(context, 'En az bir soru eklemelisiniz');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quizId != null ? 'Quiz Düzenle' : 'Quiz Oluştur'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Quiz Başlığı'),
                validator: (value) => value!.isEmpty ? 'Başlık gerekli' : null,
              ),
              TextFormField(
                controller: _timeLimitController,
                decoration: const InputDecoration(labelText: 'Süre (Dakika)'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Süre gerekli' : null,
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: _questions.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: ListTile(
                        title: Text(_questions[index]['question']),
                        subtitle: Text(
                          '${_questions[index]['options'].length} seçenek',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _questions.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _addQuestion,
                child: const Text('Soru Ekle'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _saveQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Quizi Kaydet'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
