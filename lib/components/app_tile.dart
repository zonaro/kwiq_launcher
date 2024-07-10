import 'package:auto_size_text/auto_size_text.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/app_menu.dart';
import 'package:kwiq_launcher/main.dart';

class AppTile extends StatefulWidget {
  const AppTile({
    super.key,
    required this.packageName,
    this.gridColumns = 1,
    this.showLabel = true,
    required this.onPop,
  });

  final string packageName;
  final int gridColumns;
  final bool showLabel;
  final VoidCallback onPop;

  @override
  State<AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<AppTile> {
  AwaiterData<ApplicationWithIcon> appData = AwaiterData();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        DeviceApps.openApp(widget.packageName);
      },
      onDoubleTap: () {
        DeviceApps.openAppSettings(widget.packageName);
      },
      onLongPress: () async {
        await context.push(MyAppMenuScreen(packageName: widget.packageName));
        widget.onPop();
      },
      child: FutureAwaiter(
          data: appData,
          future: () async => (await DeviceApps.getApp(widget.packageName, true)) as ApplicationWithIcon,
          builder: (app) {
            if (widget.gridColumns > 1) {
              var children = [
                CircleAvatar(
                  backgroundImage: MemoryImage(app.icon),
                ),
                if (widget.showLabel) ...[
                  const SizedBox(height: 8),
                  AutoSizeText(
                    app.appName,
                    textAlign: TextAlign.center,
                  ),
                ]
              ];
              return GridTile(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: children,
                ),
              );
            } else {
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: MemoryImage(app.icon),
                ),
                title: Text(app.appName),
                subtitle: Text(app.packageName),
                trailing: Icon(categoryIcon(app.category.name)),
              );
            }
          }),
    );
  }
}
