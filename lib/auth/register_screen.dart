import 'package:etribunals/core/constants/app_colors.dart';
import 'package:etribunals/core/widgets/common_widgets.dart';
import 'package:etribunals/core/utils/form_validators.dart';  // Import form validators
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // For form validation

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register User
  Future<void> _registerUser() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Firebase Authentication Register
        // ignore: unused_local_variable
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );

        Fluttertoast.showToast(msg: 'Registration Successful');
        Navigator.pushReplacementNamed(context, '/dashboard');
      } on FirebaseAuthException catch (e) {
        Fluttertoast.showToast(msg: e.message ?? 'Registration Failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: customText("Register")),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary, AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),
              // Input Fields with Validators
              inputTextField(
                controller: nameController,
                label: "Full Name",
                validator: FormValidators.validateName,
              ),
              const SizedBox(height: 20),
              inputTextField(
                controller: emailController,
                label: "Email",
                validator: FormValidators.validateEmail,
              ),
              const SizedBox(height: 20),
              inputTextField(
                controller: passwordController,
                label: "Password",
                isPassword: true,
                validator: FormValidators.validatePassword,
              ),
              const SizedBox(height: 30),
              customButton("Register", _registerUser),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: customText("Already have an account? Login", color: Colors.white70),
              )
            ],
          ),
        ),
      ),
    );
  }
}
