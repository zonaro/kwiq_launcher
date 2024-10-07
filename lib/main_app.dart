// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/home.dart';
import 'package:sizer/sizer.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => ResponsiveSizer(builder: (context, orientation, screenType) {
        return GetMaterialApp(
          themeMode: ThemeMode.system,
          theme: ThemeData.from(colorScheme: ColorScheme.light(primary: mainColor)),
          darkTheme: ThemeData.from(colorScheme: ColorScheme.dark(primary: mainColor)),
          locale: Get.deviceLocale,
          localizationsDelegates: InnerLibsLocalizations.localizationsDelegates,
          supportedLocales: InnerLibsLocalizations.supportedLocales,
          home: const HomePage(),
        );
      });
}
