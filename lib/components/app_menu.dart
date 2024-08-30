// ignore_for_file: use_build_context_synchronously

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:kwiq_launcher/components/categories.dart';
import 'package:kwiq_launcher/main.dart';
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
        future: () async => (await InstalledApps.getAppInfo(packageName)),
        builder: (app) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (app.icon != null) Image.memory(app.icon!, height: 100),
              const SizedBox(height: 16),
              Text(app.name, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  InstalledApps.startApp(app.packageName);
                },
                child: const Text('Open App'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (dockedApps.flatContains(app.packageName)) {
                    dockedApps = dockedApps.where((e) => e != app.packageName).toList();
                  } else {
                    dockedApps = [...dockedApps, app.packageName];
                  }
                },
                child: Text(dockedApps.flatContains(app.packageName) ? "Undock App" : 'Dock App'),
              ),
              ElevatedButton(
                onPressed: () {
                  InstalledApps.openSettings(app.packageName);
                },
                child: const Text('App Settings'),
              ),
              ElevatedButton(
                  onPressed: () {
                    launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=${app.packageName}"));
                  },
                  child: const Text("Show on PlayStore")),
              ElevatedButton(
                onPressed: () {
                  if (hiddenApps.flatContains(app.packageName)) {
                    hiddenApps = hiddenApps.where((element) => element != app.packageName).toList();
                  } else {
                    hiddenApps = [...hiddenApps, app.packageName];
                  }
                },
                child: Text(hiddenApps.flatContains(app.packageName) ? 'Show App' : 'Hide App'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await context.push(CategoriesPage(app: app));
                },
                child: const Text('Set Categories'),
              ),
              FutureAwaiter(
                future: () async => await InstalledApps.isSystemApp(app.packageName),
                builder: (b) => b ?? false
                    ? ElevatedButton(
                        onPressed: () async {
                          if (await InstalledApps.uninstallApp(app.packageName) == true) {
                            apps = apps.where((element) => element.packageName != app.packageName).toList();
                          }
                        },
                        child: const Text('Uninstall App'),
                      )
                    : nil,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
