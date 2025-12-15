import 'package:flutter/material.dart';
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
  final pages = [
    const QuizCategory(),
    const Leaderboard(),
    const ProfileScreen(),
  ];

  late int selectedIndex;
  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Kategoriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Lider Tablosu',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
