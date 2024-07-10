import 'package:auto_size_text/auto_size_text.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/app_menu.dart';
import 'package:kwiq_launcher/main.dart';

class AppTile extends StatefulWidget {
  const AppTile({
    super.key,
    required this.app,
    this.gridColumns = 1,
    this.showLabel = true,
  });

  final ApplicationWithIcon app;
  final int gridColumns;
  final bool showLabel;

  @override
  State<AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<AppTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => widget.app.openApp(),
      onDoubleTap: () => widget.app.openSettingsScreen(),
      onLongPress: () async {
        await context.push(MyAppMenuScreen(packageName: widget.app.packageName));
      },
      child: Builder(builder: (context) {
        if (widget.gridColumns > 1) {
          var children = [
            CircleAvatar(
              backgroundImage: MemoryImage(widget.app.icon),
            ),
            if (widget.showLabel) ...[
              const SizedBox(height: 8),
              AutoSizeText(
                widget.app.appName,
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
              backgroundImage: MemoryImage(widget.app.icon),
            ),
            title: Text(widget.app.appName),
            subtitle: Text(widget.app.packageName),
            trailing: Icon(categoryIcon(widget.app.category.name)),
          );
        }
      }),
    );
  }
}
