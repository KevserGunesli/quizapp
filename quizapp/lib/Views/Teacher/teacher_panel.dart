import 'package:flutter/material.dart';
import 'package:quizapp/Views/Teacher/classroom_list.dart';

class TeacherPanel extends StatelessWidget {
  const TeacherPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Öğretmen Paneli'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: const ClassroomList(),
    );
  }
}
