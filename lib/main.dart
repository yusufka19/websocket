import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const FootballQuizApp());
}

class FootballQuizApp extends StatelessWidget {
  const FootballQuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Quiz',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
