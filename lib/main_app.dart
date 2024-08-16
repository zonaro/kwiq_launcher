// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/desktop_home.dart';
import 'package:kwiq_launcher/pages/welcome.dart';

import 'pages/home_page.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
        themeMode: ThemeMode.system,
        theme: ThemeData.from(colorScheme: ColorScheme.light(primary: mainColor)),
        darkTheme: ThemeData.from(colorScheme: ColorScheme.dark(primary: mainColor)),
        home: FutureBool(
          future: () async {
            var a = await WelcomeScreen.allowed;
            if (a) {
              if (apps.isEmpty) {
                await loadApps();
              }
              if (contacts.isEmpty) {
                await loadContacts();
              }
            }
            return a;
          }(),
          trueWidget: context.orientation == Orientation.portrait ? const HomePage() : const Windows11MimicScreen(),
          falseWidget: const WelcomeScreen(),
        ),
      );
}
