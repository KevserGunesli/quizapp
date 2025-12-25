import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:quizapp/Service/classroom_service.dart';
import 'package:quizapp/Views/Teacher/add_classroom_quiz_screen.dart';
import 'package:quizapp/Views/Teacher/student_stats_screen.dart';

class ClassroomDetailScreen extends StatefulWidget {
  final String classroomId;
  final String classroomName;

  const ClassroomDetailScreen({
    super.key,
    required this.classroomId,
    required this.classroomName,
  });

  @override
  State<ClassroomDetailScreen> createState() => _ClassroomDetailScreenState();
}

class _ClassroomDetailScreenState extends State<ClassroomDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClassroomService _classroomService = ClassroomService();
  List<Map<String, dynamic>> students = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final loadedStudents = await _classroomService.getStudentsInClassroom(
        widget.classroomId,
      );
      if (mounted) {
        setState(() {
          students = loadedStudents;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Öğrenciler yüklenirken hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classroomName),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Öğrenciler'),
            Tab(text: 'Quizler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Students Tab
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : students.isEmpty
              ? const Center(child: Text('Bu sınıfta henüz öğrenci yok.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final name = student['name'] ?? 'İsimsiz';
                    final email = student['email'] ?? '';
                    final uid = student['uid'];

                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                          ),
                        ),
                        title: Text(name),
                        subtitle: Text(email),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => StudentStatsScreen(
                                studentId: uid,
                                studentName: name,
                                classroomId: widget.classroomId,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

          // Quizzes Tab
          Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AddClassroomQuizScreen(classroomId: widget.classroomId),
                  ),
                );
              },
              backgroundColor: Colors.orange,
              child: const Icon(Icons.add, color: Colors.white),
            ),
            body: StreamBuilder<QuerySnapshot>(
              stream: _classroomService.getClassroomQuizzes(widget.classroomId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Henüz quiz oluşturulmadı.'));
                }

                final quizzes = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quiz = quizzes[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.quiz, color: Colors.orange),
                        title: Text(quiz['title']),
                        subtitle: Text(
                          '${quiz['questions'].length} Soru • ${quiz['timeLimitMinutes']} Dakika',
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddClassroomQuizScreen(
                                    classroomId: widget.classroomId,
                                    quizId: quizzes[index].id,
                                    initialData: quiz,
                                  ),
                                ),
                              );
                            } else if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Quizi Sil'),
                                  content: const Text(
                                    'Bu quizi silmek istediğinizden emin misiniz?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('İptal'),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await _classroomService.deleteQuiz(
                                          widget.classroomId,
                                          quizzes[index].id,
                                        );
                                      },
                                      child: const Text(
                                        'Sil',
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (BuildContext context) =>
                              <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit),
                                    title: Text('Düzenle'),
                                  ),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    title: Text(
                                      'Sil',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
