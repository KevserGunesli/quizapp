import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:quizapp/Service/classroom_service.dart';
import 'package:quizapp/Views/classroom_quizzes_screen.dart';
import 'package:quizapp/Views/login_screen.dart';
import 'package:quizapp/Widgets/my_button.dart';
import 'package:quizapp/Widgets/snackbar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final ClassroomService _classroomService = ClassroomService();
  bool isLoading = true;
  Map<String, dynamic>? userData;
  Uint8List? profileImageBytes;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    if (user == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    try {
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection("userData")
          .doc(user!.uid)
          .get();
      if (documentSnapshot.exists) {
        setState(() {
          userData = documentSnapshot.data() as Map<String, dynamic>?;
          if (userData?['photoBase64'] != null) {
            profileImageBytes = base64Decode(userData!['photoBase64']);
          }
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint(e.toString());
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        showSnackBar(context, "Veri alınırken bir hata oluştu: $e");
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    final returnImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );
    if (returnImage == null) return;
    final bytes = await returnImage.readAsBytes();
    if (!mounted) return;
    setState(() {
      profileImageBytes = bytes;
    });
    String base64Image = base64Encode(bytes);
    await FirebaseFirestore.instance
        .collection("userData")
        .doc(user!.uid)
        .update({'photoBase64': base64Image});
  }

  Future<void> _joinClassroom() async {
    final codeController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sınıfa Katıl'),
        content: TextField(
          controller: codeController,
          decoration: const InputDecoration(
            labelText: 'Sınıf Kodu',
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
            child: const Text('Katıl'),
          ),
        ],
      ),
    );

    if (result == true && codeController.text.isNotEmpty) {
      try {
        await _classroomService.joinClassroom(codeController.text.trim());
        if (mounted) {
          showSnackBar(context, 'Sınıfa başarıyla katıldınız');
        }
      } catch (e) {
        if (mounted) {
          showSnackBar(context, 'Hata: $e');
        }
      }
    }
  }

  Future<void> signOut() async {
    if (!mounted) return;
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text(
          "Profil",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Kullanıcı verisi bulunamadı"),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: MyButton(onTap: signOut, buttonText: 'Çıkış Yap'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: _pickImageFromGallery,
                    child: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      radius: 60,
                      backgroundImage: profileImageBytes != null
                          ? MemoryImage(profileImageBytes!)
                          : null,
                      child: const Align(
                        alignment: Alignment.bottomRight,
                        child: CircleAvatar(
                          backgroundColor: Colors.black,
                          radius: 16,
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    userData?['name'] ?? 'Kullanıcı Adı',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Score: ${(userData?['score'] ?? 0) * 102}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 60, 139, 56),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Divider(),
                  const SizedBox(height: 15),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _classroomService.getStudentClassrooms(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return const Text("Hata oluştu");
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Center(
                            child: Text("Henüz bir sınıfa katılmadınız"),
                          );
                        }
                        final classrooms = snapshot.data!.docs;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Katıldığım Sınıflar",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: ListView.builder(
                                itemCount: classrooms.length,
                                itemBuilder: (context, index) {
                                  final data =
                                      classrooms[index].data()
                                          as Map<String, dynamic>;
                                  return Card(
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.class_,
                                        color: Colors.orange,
                                      ),
                                      title: Text(
                                        data['name'] ?? 'İsimsiz Sınıf',
                                      ),
                                      subtitle: Text("Kod: ${data['code']}"),
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ClassroomQuizzesScreen(
                                                  classroomId:
                                                      classrooms[index].id,
                                                  classroomName:
                                                      data['name'] ?? 'Sınıf',
                                                ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              MyButton(
                                onTap: _joinClassroom,
                                buttonText: 'Sınıfa Katıl',
                              ),
                              const SizedBox(height: 10),
                              MyButton(onTap: signOut, buttonText: 'Çıkış Yap'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
