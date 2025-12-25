import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quizapp/Service/classroom_service.dart';
import 'package:quizapp/Views/Teacher/classroom_detail_screen.dart';
import 'package:quizapp/Widgets/snackbar.dart';

class ClassroomList extends StatefulWidget {
  const ClassroomList({super.key});

  @override
  State<ClassroomList> createState() => _ClassroomListState();
}

class _ClassroomListState extends State<ClassroomList> {
  final ClassroomService _classroomService = ClassroomService();

  Future<void> _createClassroom() async {
    final nameController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Sınıf Oluştur'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Sınıf Adı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    if (result == true && nameController.text.isNotEmpty) {
      try {
        String code = await _classroomService.createClassroom(
          nameController.text,
        );
        if (mounted) {
          showSnackBar(context, 'Sınıf oluşturuldu. Kod: $code');
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Hata: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _createClassroom,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _classroomService.getTeacherClassrooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Hata: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Henüz sınıf oluşturmadınız.'));
          }

          final classrooms = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: classrooms.length,
            itemBuilder: (context, index) {
              final doc = classrooms[index];
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name'] ?? 'İsimsiz Sınıf';
              final code = data['code'] ?? '';
              final studentCount = (data['studentIds'] as List?)?.length ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: const Icon(Icons.class_, color: Colors.white),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Kod: $code • $studentCount Öğrenci'),
                  trailing: IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      showSnackBar(context, 'Sınıf kodu kopyalandı');
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ClassroomDetailScreen(
                          classroomId: doc.id,
                          classroomName: name,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
