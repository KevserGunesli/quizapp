import 'package:flutter/material.dart';
import 'package:quizapp/Service/auth_service.dart';
import 'package:quizapp/Views/nav_bar_category_selection_screen.dart';
import 'package:quizapp/Views/signup_screen.dart';
import 'package:quizapp/Widgets/my_button.dart';
import 'package:quizapp/Widgets/snackbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isPasswordHidden = true;
  bool isLoading = false;

  final AuthService _authService = AuthService();
  void _login() async {
    // Trim whitespace from inputs
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    // Validate inputs
    if (email.isEmpty || password.isEmpty) {
      showSnackBar(context, "Lütfen email ve şifre alanlarını doldurun");
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _authService.loginUser(
        email: email,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      if (result == "success") {
        showSnackBar(
          context,
          "Giriş Başarılı. Ana sayfaya yönlendiriliyorsunuz...",
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const NavBarCategorySelectionScreen(),
          ),
        );
      } else {
        // Parse Firebase error messages to user-friendly messages
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
    if (error.contains('invalid-credential') ||
        error.contains('wrong-password')) {
      return 'Email veya şifre hatalı';
    } else if (error.contains('user-not-found')) {
      return 'Giriş yapmadan önce kayıt olmalısınız';
    } else if (error.contains('email-not-verified')) {
      return 'Email adresiniz doğrulanmamış. Mail kutunuza doğrulama bağlantısını yeniden gönderdik.';
    } else if (error.contains('invalid-email')) {
      return 'Geçersiz email adresi';
    } else if (error.contains('user-disabled')) {
      return 'Bu hesap devre dışı bırakılmış';
    } else if (error.contains('too-many-requests')) {
      return 'Çok fazla başarısız deneme. Lütfen daha sonra tekrar deneyin';
    } else if (error.contains('network-request-failed')) {
      return 'İnternet bağlantısı hatası';
    }
    return 'Giriş başarısız: $error';
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
                Image.asset("assets/login.jpg"),
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
                //Login Button
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        child: MyButton(onTap: _login, buttonText: "Giriş Yap"),
                      ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Hesabınız yok mu? ",
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
                            builder: (context) => const SignUpScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Kayıt Ol",
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
