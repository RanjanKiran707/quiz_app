// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:quiz_app/core/di/app_dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDependencies.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quiz App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3A5A40)),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(child: Text('Quiz App')),
      ),
    );
  }
}
