import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/app_menu.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/models/kwiq_config.dart';

class AppTile extends StatefulWidget {
  final AppInfo app;

  final int gridColumns;
  final bool showLabel;
  const AppTile({
    super.key,
    required this.app,
    this.gridColumns = 1,
    this.showLabel = true,
  });

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
        setState(() {});
      },
      child: Builder(builder: (context) {
        if (widget.gridColumns > 1) {
          var children = [
            if (widget.app.icon.isNotEmpty)
              CircleAvatar(
                backgroundImage: MemoryImage(widget.app.icon),
              ),
            const SizedBox(
              height: 10,
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: children,
              ),
            ),
          );
        } else {
          return ListTile(
            leading: widget.app.icon.isNotEmpty
                ? CircleAvatar(
                    backgroundImage: MemoryImage(widget.app.icon),
                  )
                : null,
            title: Text(widget.app.appName),
            subtitle: Text(widget.app.packageName),
            trailing: Icon(categoryIcon(kwiqConfig.getCategoriesOfApp(widget.app).firstOrNull ?? "")),
          );
        }
      }),
    );
  }
}
