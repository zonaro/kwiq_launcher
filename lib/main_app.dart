// ignore_for_file: use_build_context_synchronously

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
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
        onRestart: (context) async {
          apps = await DeviceApps.getInstalledApplications(
            includeAppIcons: true,
            includeSystemApps: true,
            onlyAppsWithLaunchIntent: true,
          );
          contacts = await FlutterContacts.getContacts(
            withProperties: true,
            withPhoto: true,
            withAccounts: true,
            withGroups: true,
            withThumbnail: true,
            deduplicateProperties: true,
            sorted: true,
          );
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
