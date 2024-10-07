// ignore_for_file: use_build_context_synchronously

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/categories.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:new_device_apps/device_apps.dart';
import 'package:url_launcher/url_launcher.dart';

class MyAppMenuScreen extends StatelessWidget {
  final string packageName;

  const MyAppMenuScreen({super.key, required this.packageName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            AutoSizeText(packageName),
          ],
        ),
        centerTitle: true,
      ),
      body: FutureAwaiter(
        future: () async => (await DeviceApps.getApp(packageName, true) as AppInfo),
        builder: (app) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (app.icon.isNotEmpty) Image.memory(app.icon, height: 100),
              const SizedBox(height: 16),
              Text(app.appName, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => app.openApp(),
                child: Text(loc.openItem(loc.app)),
              ),
              ElevatedButton(
                onPressed: () {
                  if (dockedApps.flatContains(app.packageName)) {
                    dockedApps = dockedApps.where((e) => e != app.packageName).toList();
                  } else {
                    dockedApps = [...dockedApps, app.packageName];
                  }
                  Get.forceAppUpdate();
                },
                child: Text(dockedApps.flatContains(app.packageName) ? "${loc.undock} ${loc.app}" : "${loc.dock} ${loc.app}"),
              ),
              ElevatedButton(
                onPressed: () => app.openSettingsScreen(),
                child: Text(loc.appSettings),
              ),
              ElevatedButton(
                  onPressed: () {
                    launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=${app.packageName}"));
                  },
                  child: Text(loc.openItem("Play Store"))),
              ElevatedButton(
                onPressed: () {
                  if (hiddenApps.flatContains(app.packageName)) {
                    hiddenApps = hiddenApps.where((element) => element != app.packageName).toList();
                  } else {
                    hiddenApps = [...hiddenApps, app.packageName];
                  }
                  Get.forceAppUpdate();
                },
                child: Text(hiddenApps.flatContains(app.packageName) ? '${loc.show} ${loc.app}' : '${loc.hide} ${loc.app}'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await context.push(CategoriesPage(app: app));
                },
                child: Text(loc.categories),
              ),
              if (!app.systemApp)
                ElevatedButton(
                  onPressed: () async {
                    if (await DeviceApps.uninstallApp(app.packageName) == true) {
                      apps.removeWhere((element) => element.packageName == app.packageName);
                    }
                  },
                  child: Text('${loc.uninstall} ${loc.app}'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
