import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:quizapp/Service/auth_service.dart';
import 'package:quizapp/Views/login_screen.dart';
import 'package:quizapp/Widgets/my_button.dart';
import 'package:quizapp/Widgets/snackbar.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  bool isLoading = false;
  bool isPasswordHidden = true;

  final AuthService _authService = AuthService();
  void _signUp() async {
    // Trim whitespace from inputs
    String email = emailController.text.trim();
    String name = nameController.text.trim();
    String password = passwordController.text.trim();

    // Validate inputs
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showSnackBar(context, "Lütfen tüm alanları doldurun");
      return;
    }

    if (password.length < 6) {
      showSnackBar(context, "Şifre en az 6 karakter olmalıdır");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      Uint8List? profileImageBytes;
      final result = await _authService.signUpUser(
        email: email,
        name: name,
        password: password,
        profileImage: profileImageBytes,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (result == "success") {
        showSnackBar(
          context,
          "Kayıt Başarılı. Giriş sayfasına yönlendiriliyorsunuz...",
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      } else {
        String errorMessage = _getErrorMessage(result);
        showSnackBar(context, errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      String errorMessage = _getErrorMessage(e.toString());
      showSnackBar(context, errorMessage);
    }
  }

  String _getErrorMessage(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Bu email adresi zaten kullanımda';
    } else if (error.contains('invalid-email')) {
      return 'Geçersiz email adresi';
    } else if (error.contains('weak-password')) {
      return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin';
    } else if (error.contains('network-request-failed')) {
      return 'İnternet bağlantısı hatası';
    } else if (error.contains('Please fill all the fields')) {
      return 'Lütfen tüm alanları doldurun';
    }
    return 'Kayıt başarısız: $error';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(15),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Image.asset("assets/cat1.jpg"),
                const SizedBox(height: 20),
                //Input Field for name
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "İsim",
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
                //Input Field for email
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 20),
                //Input Field for password
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Şifre",
                    prefixIcon: Icon(Icons.lock),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          isPasswordHidden = !isPasswordHidden;
                        });
                      },
                      icon: Icon(
                        isPasswordHidden
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                  obscureText: isPasswordHidden,
                ),
                const SizedBox(height: 20),
                isLoading
                    ? CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: MyButton(onTap: _signUp, buttonText: "Kayıt Ol"),
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Hesabınız var mı? ",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        letterSpacing: -1,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Giriş Yap",
                        style: TextStyle(color: Colors.blue, letterSpacing: -1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
