// ignore_for_file: use_build_context_synchronously

import 'package:auto_size_text/auto_size_text.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';

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
        future: () async => (await DeviceApps.getApp(packageName, true)) as ApplicationWithIcon,
        builder: (app) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.memory(app.icon, height: 100),
              const SizedBox(height: 16),
              Text(app.appName, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  DeviceApps.openApp(app.packageName);
                },
                child: const Text('Open App'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (homeApps.flatContains(app.packageName)) {
                    homeApps = homeApps.where((e) => e != app.packageName).toList();
                  } else {
                    homeApps = [...homeApps, app.packageName];
                  }
                  context.restartApp();
                },
                child: Text(homeApps.flatContains(app.packageName) ? "Undock App" : 'Dock App'),
              ),
              ElevatedButton(
                onPressed: () {
                  DeviceApps.openAppSettings(app.packageName);
                },
                child: const Text('App Settings'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (hiddenApps.flatContains(app.packageName)) {
                    hiddenApps = hiddenApps.where((element) => element != app.packageName).toList();
                  } else {
                    hiddenApps = [...hiddenApps, app.packageName];
                  }
                  context.restartApp();
                },
                child: Text(hiddenApps.flatContains(app.packageName) ? 'Show App' : 'Hide App'),
              ),
              ElevatedButton(
                onPressed: () {
                  // setCategoriesOf(widget.application.packageName, categories)
                  context.showSnackBar("Soon to be implemented");
                },
                child: const Text('Set Categories'),
              ),
              if (!app.systemApp)
                ElevatedButton(
                  onPressed: () async {
                    if (await app.uninstallApp()) {
                      context.restartApp();
                    }
                  },
                  child: const Text('Uninstall App'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
