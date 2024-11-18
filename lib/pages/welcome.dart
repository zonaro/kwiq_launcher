// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:restart_app/restart_app.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FutureAwaiter(
        future: () async => await allowed,
        builder: (x) => FloatingActionButton.extended(
          onPressed: () {},
          label: const Text('Continue'),
        ),
      ),
      body: SizedBox(
        width: Get.width,
        height: Get.height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(35.0),
              child: Image.asset('assets/kwiq.png'), // Replace with your app icon image
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Welcome to Kwiq Launcher!',
                    style: TextStyle(fontSize: 24),
                  ),
                  Text("First, we need some permissions to get started."),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: permissionList,
              ),
            ),
            Gap(Get.height * .12),
          ],
        ),
      ),
    );
  }

  static Future<bool> get allowed async => await Future.wait(permissionList.map((x) async => await x.permission.status.isGranted || await x.permission.status.isRestricted || x.majorPermission == false)).then((statuses) => statuses.every((status) => status == true));

  static List<PermissionItem> get permissionList => [
        const PermissionItem(
          icon: Icons.storage,
          permission: Permission.manageExternalStorage,
          title: 'External Storage',
          description: "This application can list, open and manage files on your device without external applications.",
        ),
        const PermissionItem(
          icon: Icons.camera,
          permission: Permission.camera,
          title: 'Camera',
          description: "Take photos and record videos.",
        ),
        const PermissionItem(
          icon: Icons.contacts,
          permission: Permission.contacts,
          title: 'Contacts',
          description: "Show contacts from your device.",
        ),
      ];
}

class PermissionItem extends StatefulWidget {
  final Permission permission;
  final String title;
  final string description;
  final IconData icon;
  final bool majorPermission;

  const PermissionItem({
    super.key,
    required this.permission,
    required this.title,
    required this.description,
    required this.icon,
    this.majorPermission = true,
  });

  @override
  State<PermissionItem> createState() => _PermissionItemState();
}

class _PermissionItemState extends State<PermissionItem> {
  Future<bool> get permissionGranted => widget.permission.status.isGranted;

  @override
  Widget build(BuildContext context) {
    return FutureAwaiter<bool>(
      future: () => widget.permission.isRestricted,
      builder: (_) => const SizedBox.shrink(),
      emptyChild: ListTile(
        title: Text(widget.title),
        subtitle: Text(widget.description),
        leading: Icon(widget.icon),
        trailing: SizedBox(
          width: 50,
          child: FutureAwaiter<bool>(
            future: () => permissionGranted,
            builder: (_) => const Icon(Icons.check, color: Colors.green),
            emptyChild: const Icon(Icons.close, color: Colors.red),
          ),
        ),
        onTap: () async {
           await widget.permission.request();
          // Handle permission status here
          Get.reloadAll(force: true);
          Restart.restartApp();
        },
      ),
    );
  }
}
