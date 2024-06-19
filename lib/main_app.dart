import 'package:flutter/material.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/home.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      theme: ThemeData.light().copyWith(primaryColor: mainColor),
      darkTheme: ThemeData.dark().copyWith(primaryColor: mainColor),
      home: const Scaffold(
        body: HomePage(),
      ),
    );
  }
}
