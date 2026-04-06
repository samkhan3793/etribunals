import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'eTribunals Case Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/splash',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
