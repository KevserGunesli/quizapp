import 'package:flutter/material.dart';
import 'package:quizapp/Service/role_service.dart';
import 'package:quizapp/Views/Admin/admin_panel.dart';
import 'package:quizapp/Views/Teacher/teacher_panel.dart';
import 'package:quizapp/Views/leaderboard.dart';
import 'package:quizapp/Views/profile_screen.dart';
import 'package:quizapp/Views/quiz_category.dart';

class NavBarCategorySelectionScreen extends StatefulWidget {
  final int initialIndex;
  const NavBarCategorySelectionScreen({super.key, this.initialIndex = 0});

  @override
  State<NavBarCategorySelectionScreen> createState() =>
      NavBarCategorySelectionScreenState();
}

class NavBarCategorySelectionScreenState
    extends State<NavBarCategorySelectionScreen> {
  final PageStorageBucket bucket = PageStorageBucket();
  final RoleService _roleService = RoleService();
  bool isAdmin = false;
  bool isTeacher = false;
  bool isLoading = true;

  List<Widget> get pages => [
    const QuizCategory(),
    const Leaderboard(),
    const ProfileScreen(),
    if (isAdmin) const AdminPanel(),
    if (isTeacher) const TeacherPanel(),
  ];

  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final adminStatus = await _roleService.isCurrentUserAdmin();
    final teacherStatus = await _roleService.isCurrentUserTeacher();
    if (mounted) {
      setState(() {
        isAdmin = adminStatus;
        isTeacher = teacherStatus;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: PageStorage(bucket: bucket, child: pages[selectedIndex]),
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Kategoriler',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Lider Tablosu',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
          if (isAdmin)
            const BottomNavigationBarItem(
              icon: Icon(Icons.admin_panel_settings),
              label: 'Admin',
            ),
          if (isTeacher)
            const BottomNavigationBarItem(
              icon: Icon(Icons.school),
              label: 'Öğretmen',
            ),
        ],
      ),
    );
  }
}
