import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/Widgets/snackbar.dart';

class QuestionManagement extends StatefulWidget {
  const QuestionManagement({super.key});

  @override
  State<QuestionManagement> createState() => _QuestionManagementState();
}

class _QuestionManagementState extends State<QuestionManagement> {
  final CollectionReference _categoriesCollection = FirebaseFirestore.instance
      .collection('ListofQuestions');

  String? selectedCategory;
  List<Map<String, dynamic>> questions = [];

  Future<void> _loadQuestions(String categoryId) async {
    try {
      final doc = await _categoriesCollection.doc(categoryId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          questions = List<Map<String, dynamic>>.from(data['questions'] ?? []);
        });
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Sorular yüklenirken hata: $e');
      }
    }
  }

  Future<void> _addQuestion() async {
    if (selectedCategory == null) {
      showSnackBar(context, 'Lütfen önce bir kategori seçin');
      return;
    }

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
          title: const Text('Yeni Soru Ekle'),
          content: SingleChildScrollView(
            child: RadioGroup<String>(
              groupValue: correctAnswer,
              onChanged: (value) => setDialogState(() => correctAnswer = value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    decoration: const InputDecoration(
                      labelText: 'Soru',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: option1Controller,
                    decoration: InputDecoration(
                      labelText: 'Seçenek 1',
                      border: const OutlineInputBorder(),
                      suffixIcon: Radio<String>(value: '1'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: option2Controller,
                    decoration: InputDecoration(
                      labelText: 'Seçenek 2',
                      border: const OutlineInputBorder(),
                      suffixIcon: Radio<String>(value: '2'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: option3Controller,
                    decoration: InputDecoration(
                      labelText: 'Seçenek 3',
                      border: const OutlineInputBorder(),
                      suffixIcon: Radio<String>(value: '3'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: option4Controller,
                    decoration: InputDecoration(
                      labelText: 'Seçenek 4',
                      border: const OutlineInputBorder(),
                      suffixIcon: Radio<String>(value: '4'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Doğru cevabı seçmek için sağdaki radio butonunu tıklayın',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
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

    if (result == true &&
        questionController.text.isNotEmpty &&
        correctAnswer != null) {
      final options = [
        option1Controller.text,
        option2Controller.text,
        option3Controller.text,
        option4Controller.text,
      ];

      final answerIndex = int.parse(correctAnswer!) - 1;
      final answer = options[answerIndex];

      final newQuestion = {
        'question': questionController.text,
        'options': options,
        'answer': answer,
      };

      try {
        questions.add(newQuestion);
        await _categoriesCollection.doc(selectedCategory).update({
          'questions': questions,
        });
        setState(() {});
        if (mounted) {
          showSnackBar(context, 'Soru başarıyla eklendi');
        }
      } catch (e) {
        questions.removeLast();
        if (mounted) {
          showSnackBar(context, 'Soru eklenirken hata: $e');
        }
      }
    }
  }

  Future<void> _editQuestion(int index) async {
    final question = questions[index];
    final questionController = TextEditingController(
      text: question['question'],
    );
    final options = List<String>.from(question['options'] ?? []);
    final option1Controller = TextEditingController(
      text: options.isNotEmpty ? options[0] : '',
    );
    final option2Controller = TextEditingController(
      text: options.length > 1 ? options[1] : '',
    );
    final option3Controller = TextEditingController(
      text: options.length > 2 ? options[2] : '',
    );
    final option4Controller = TextEditingController(
      text: options.length > 3 ? options[3] : '',
    );

    String? correctAnswer;
    final currentAnswer = question['answer'];
    for (int i = 0; i < options.length; i++) {
      if (options[i] == currentAnswer) {
        correctAnswer = (i + 1).toString();
        break;
      }
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Soruyu Düzenle'),
          content: SingleChildScrollView(
            child: RadioGroup<String>(
              groupValue: correctAnswer,
              onChanged: (value) => setDialogState(() => correctAnswer = value),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: questionController,
                    decoration: const InputDecoration(
                      labelText: 'Soru',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: option1Controller,
                    decoration: InputDecoration(
                      labelText: 'Seçenek 1',
                      border: const OutlineInputBorder(),
                      suffixIcon: Radio<String>(value: '1'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: option2Controller,
                    decoration: InputDecoration(
                      labelText: 'Seçenek 2',
                      border: const OutlineInputBorder(),
                      suffixIcon: Radio<String>(value: '2'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: option3Controller,
                    decoration: InputDecoration(
                      labelText: 'Seçenek 3',
                      border: const OutlineInputBorder(),
                      suffixIcon: Radio<String>(value: '3'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: option4Controller,
                    decoration: InputDecoration(
                      labelText: 'Seçenek 4',
                      border: const OutlineInputBorder(),
                      suffixIcon: Radio<String>(value: '4'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (result == true && correctAnswer != null) {
      final newOptions = [
        option1Controller.text,
        option2Controller.text,
        option3Controller.text,
        option4Controller.text,
      ];

      final answerIndex = int.parse(correctAnswer!) - 1;
      final answer = newOptions[answerIndex];

      questions[index] = {
        'question': questionController.text,
        'options': newOptions,
        'answer': answer,
      };

      try {
        await _categoriesCollection.doc(selectedCategory).update({
          'questions': questions,
        });
        setState(() {});
        if (mounted) {
          showSnackBar(context, 'Soru başarıyla güncellendi');
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Soru güncellenirken hata: $e');
        }
      }
    }
  }

  Future<void> _deleteQuestion(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soruyu Sil'),
        content: const Text('Bu soruyu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        questions.removeAt(index);
        await _categoriesCollection.doc(selectedCategory).update({
          'questions': questions,
        });
        setState(() {});
        if (mounted) {
          showSnackBar(context, 'Soru başarıyla silindi');
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Soru silinirken hata: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soru Yönetimi'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: selectedCategory != null
          ? FloatingActionButton(
              onPressed: _addQuestion,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Column(
        children: [
          // Kategori seçimi
          Padding(
            padding: const EdgeInsets.all(16),
            child: StreamBuilder<QuerySnapshot>(
              stream: _categoriesCollection.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final categories = snapshot.data!.docs;

                return DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Seçin',
                    border: OutlineInputBorder(),
                  ),
                  items: categories.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return DropdownMenuItem(
                      value: doc.id,
                      child: Text(data['title'] ?? doc.id),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                      questions = [];
                    });
                    if (value != null) {
                      _loadQuestions(value);
                    }
                  },
                );
              },
            ),
          ),

          // Sorular listesi
          Expanded(
            child: selectedCategory == null
                ? const Center(child: Text('Lütfen bir kategori seçin'))
                : questions.isEmpty
                ? const Center(child: Text('Bu kategoride soru bulunamadı'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ExpansionTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(
                            question['question'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Seçenekler:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...List.generate(
                                    (question['options'] as List?)?.length ?? 0,
                                    (i) {
                                      final option = question['options'][i];
                                      final isCorrect =
                                          option == question['answer'];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isCorrect
                                                  ? Icons.check_circle
                                                  : Icons.circle_outlined,
                                              color: isCorrect
                                                  ? Colors.green
                                                  : Colors.grey,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                option,
                                                style: TextStyle(
                                                  color: isCorrect
                                                      ? Colors.green
                                                      : null,
                                                  fontWeight: isCorrect
                                                      ? FontWeight.bold
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _editQuestion(index),
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        label: const Text('Düzenle'),
                                      ),
                                      TextButton.icon(
                                        onPressed: () => _deleteQuestion(index),
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        label: const Text('Sil'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
