import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:kwiq_launcher/components/app_menu.dart';
import 'package:kwiq_launcher/main.dart';

class AppTile extends StatefulWidget {
  const AppTile({
    super.key,
    required this.app,
    this.gridColumns = 1,
    this.showLabel = true,
  });

  final AppInfo app;
  final int gridColumns;
  final bool showLabel;

  @override
  State<AppTile> createState() => _AppTileState();
}

class _AppTileState extends State<AppTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => InstalledApps.startApp(widget.app.packageName),
      onDoubleTap: () => InstalledApps.openSettings(widget.app.packageName),
      onLongPress: () async {
        await context.push(MyAppMenuScreen(packageName: widget.app.packageName));
        setState(() {});
      },
      child: Builder(builder: (context) {
        if (widget.gridColumns > 1) {
          var children = [
            if (widget.app.icon != null)
              CircleAvatar(
                backgroundImage: MemoryImage(widget.app.icon!),
              ),
            if (widget.showLabel) ...[
              const SizedBox(height: 8),
              AutoSizeText(
                widget.app.name,
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
            leading: widget.app.icon != null
                ? CircleAvatar(
                    backgroundImage: MemoryImage(widget.app.icon!),
                  )
                : null,
            title: Text(widget.app.name),
            subtitle: Text(widget.app.packageName),
            trailing: Icon(categoryIcon(getCategoriesOf(widget.app.packageName).firstOrNull ?? "")),
          );
        }
      }),
    );
  }
}
