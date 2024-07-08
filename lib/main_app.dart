// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:get/get.dart' hide ContextExtensionss;
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/desktop_home.dart';
import 'package:kwiq_launcher/pages/welcome.dart';
import 'package:sizer/sizer.dart';

import 'pages/home_page.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => RestartWidget(
        onRestart: (context) {
          apps.clear();
          contacts.clear();
        },
        child: GetMaterialApp(
          themeMode: ThemeMode.system,
          theme: ThemeData.from(colorScheme: ColorScheme.light(primary: mainColor)),
          darkTheme: ThemeData.from(colorScheme: ColorScheme.dark(primary: mainColor)),
          home: Sizer(
            builder: (context, orientation, deviceType) => FutureAwaiter(
              data: AwaiterData(validate: false),
              future: () => WelcomeScreen.allowed,
              builder: (a) => a
                  ? orientation == Orientation.portrait
                      ? const HomePage()
                      : const Windows11MimicScreen()
                  : const WelcomeScreen(),
            ),
          ),
        ),
      );
}
