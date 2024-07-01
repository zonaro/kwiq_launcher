// ignore_for_file: use_build_context_synchronously

import 'package:auto_size_text/auto_size_text.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';

class MyAppMenuScreen extends StatelessWidget {
  final ApplicationWithIcon application;

  const MyAppMenuScreen({super.key, required this.application});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            AutoSizeText(application.packageName),
          ],
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.memory(application.icon, height: 100),
            const SizedBox(height: 16),
            Text(application.appName, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                DeviceApps.openApp(application.packageName);
              },
              child: const Text('Open App'),
            ),
            ElevatedButton(
              onPressed: () {
                if (dockedApps.flatContains(application.packageName)) {
                  dockedApps = dockedApps.where((element) => element != application.packageName).toList();
                } else {
                  dockedApps = [...dockedApps, application.packageName];
                }
                apps.expired = true;
                context.restartApp();
              },
              child: Text(dockedApps.flatContains(application.packageName) ? "Undock App" : 'Dock App'),
            ),
            ElevatedButton(
              onPressed: () {
                DeviceApps.openAppSettings(application.packageName);
              },
              child: const Text('App Settings'),
            ),
            ElevatedButton(
              onPressed: () {
                if (hiddenApps.flatContains(application.packageName)) {
                  hiddenApps = hiddenApps.where((element) => element != application.packageName).toList();
                } else {
                  hiddenApps = [...hiddenApps, application.packageName];
                }
                apps.expired = true;
                context.restartApp();
              },
              child: Text(hiddenApps.flatContains(application.packageName) ? 'Show App' : 'Hide App'),
            ),
            ElevatedButton(
              onPressed: () {
                // setCategoriesOf(widget.application.packageName, categories)
                context.showSnackBar("Soon to be implemented");
              },
              child: const Text('Set Categories'),
            ),
            if (!application.systemApp)
              ElevatedButton(
                onPressed: () async {
                  if (await application.uninstallApp()) {
                    apps.expired = true;
                    context.restartApp();
                  }
                },
                child: const Text('Uninstall App'),
              ),
          ],
        ),
      ),
    );
  }
}
