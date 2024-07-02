// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:sizer/sizer.dart';

import 'pages/home_page.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, deviceType) => GetMaterialApp(
        themeMode: ThemeMode.system,
        theme: ThemeData.light().copyWith(primaryColor: mainColor),
        darkTheme: ThemeData.dark().copyWith(primaryColor: mainColor),
        home: const RestartWidget(
          child: HomePage(),
        ),
      ),
    );
  }
}

