// ignore_for_file: use_build_context_synchronously

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/app_tile.dart';
import 'package:kwiq_launcher/components/digital_clock.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/app_page.dart';
import 'package:kwiq_launcher/pages/file_manager.dart';
import 'package:kwiq_launcher/pages/search.dart';
import 'package:kwiq_launcher/pages/settings.dart';
import 'package:permission_handler/permission_handler.dart';
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

