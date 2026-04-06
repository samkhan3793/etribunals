import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/utils/form_validators.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Firebase Auth login
        final FirebaseAuth auth = FirebaseAuth.instance;
        // ignore: unused_local_variable
        UserCredential userCredential = await auth.signInWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passwordController.text.trim(),
        );
        Fluttertoast.showToast(msg: 'Login Successful');
        // Navigate to the home screen or dashboard after successful login
        Navigator.pushReplacementNamed(context, '/dashboard');
      } on FirebaseAuthException catch (e) {
        String message = "Login failed. Please try again.";
        if (e.code == 'user-not-found') {
          message = "No user found for that email.";
        } else if (e.code == 'wrong-password') {
          message = "Wrong password provided.";
        }
        showToast(message);
      }
    }
  }

  void showToast(String message) {
    // Here, implement the logic to show a toast using a package or a custom implementation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: customText("Login"), backgroundColor: Colors.lightBlueAccent,centerTitle: true,),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 66, 117, 139), AppColors.secondary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              inputTextField(
                controller: emailController,
                label: "Email",
                inputType: TextInputType.emailAddress,
                validator: FormValidators.validateEmail,  // Use the validateEmail from form_validator.dart
              ),
              const SizedBox(height: 20),
              inputTextField(
                controller: passwordController,
                label: "Password",
                isPassword: true,
                validator: FormValidators.validatePassword,  // Use the validatePassword from form_validator.dart
              ),
              const SizedBox(height: 30),
              customButton("Login", _login),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
                child: customText("Don't have an account? Register", color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
