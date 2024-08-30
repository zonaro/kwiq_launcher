// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/home_page.dart';
import 'package:sizer/sizer.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<bool> get checkWhatsapp async => await InstalledApps.isAppInstalled('com.whatsapp') == true || await InstalledApps.isAppInstalled('com.whatsapp.w4b') == true;

  @override
  Widget build(BuildContext context) => ResponsiveSizer(builder: (context, orientation, screenType) {
        return GetMaterialApp(
          themeMode: ThemeMode.system,
          theme: ThemeData.from(colorScheme: ColorScheme.light(primary: mainColor)),
          darkTheme: ThemeData.from(colorScheme: ColorScheme.dark(primary: mainColor)),
          home: const HomePage(),
        );
      });
}
