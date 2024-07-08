import 'package:auto_size_text/auto_size_text.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/app_menu.dart';

class AppTile extends StatefulWidget {
  const AppTile({
    super.key,
    required this.application,
    this.gridColumns = 1,
    this.showLabel = true,
    required this.onPop,
  });

  final Application application;
  final int gridColumns;
  final bool showLabel;
  final VoidCallback onPop;

  @override
  State<AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<AppTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        widget.application.openApp();
      },
      onDoubleTap: () {
        widget.application.openSettingsScreen();
      },
      onLongPress: () async {
        await context.push(MyAppMenuScreen(application: widget.application as ApplicationWithIcon));
        widget.onPop();
      },
      child: Builder(builder: (context) {
        if (widget.gridColumns > 1) {
          var children = [
            CircleAvatar(
              backgroundImage: MemoryImage((widget.application as ApplicationWithIcon).icon),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 8),
              AutoSizeText(
                widget.application.appName,
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
              backgroundImage: MemoryImage((widget.application as ApplicationWithIcon).icon),
            ),
            title: Text(widget.application.appName),
            subtitle: Text(widget.application.packageName),
          );
        }
      }),
    );
  }
}
