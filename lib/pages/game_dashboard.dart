// ignore_for_file: use_build_context_synchronously
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/models/kwiq_config.dart';
import 'package:new_device_apps/device_apps.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:xbox_ui/xbox_internal_page.dart';
import 'package:xbox_ui/xbox_ui.dart';

DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

class XboxScreen extends StatefulWidget {
  const XboxScreen({super.key});

  @override
  State<XboxScreen> createState() => _XboxScreenState();
}

class _XboxScreenState extends State<XboxScreen> {
  string username = 'XboxUser';
  string detail = '';
  Iterable<AppInfo> get cloudApps => apps.where((app) => app.packageName.flatEqualAny(famousCloudApps) || kwiqConfig.getCategoriesOfApp(app).containsAny(["Cloud", "Cloud Gaming"]));

  Iterable<string> get famousCloudApps => [
        "com.parsec.app",
        "com.valvesoftware.steamlink",
        "com.microsoft.xcloud",
        "com.nvidia.geforcenow",
        "com.google.stadia.android",
        "com.limelight",
        "com.rainway",
        "com.remotemyapp.vortex",
      ];

  Iterable<AppInfo> get games => visibleApps.where((app) => kwiqConfig.getCategoriesOfApp(app).containsAny(["Games", "Game"])).orderByDescending((x) => x.updateTimeMillis);

  XboxInternalPage appDashPage() {
    return XboxInternalPage(
      title: loc.apps,
      entries: [
        for (var cat in visibleAppsByCategory.entries)
          XboxInternalEntry(
            title: cat.key,
            icon: categoryIcon(cat.key),
            pageBuilder: (context) {
              return SizedBox(
                height: context.height,
                width: context.width,
                child: GridView.count(
                  crossAxisCount: 6,
                  shrinkWrap: true,
                  children: [
                    for (var app in cat.value)
                      XboxTile.game(
                        title: app.appName,
                        size: const Size.square(40),
                        image: MemoryImage(app.icon),
                        onTap: () => app.openApp(),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return XboxDashboard(
      username: username,
      userdetail: detail,
      topBarItens: [
        XboxMenuItem(
          icon: Icons.cloud,
          onTap: () => launchUrlString("http://xbox.ccom/play"),
          title: "Cloud Gaming",
        ),
        XboxMenuItem(
          icon: Icons.settings,
          onTap: () => DeviceApps.openApp("com.android.settings"),
          title: loc.settings,
        ),
      ],
      menu: const XboxMenu(
        items: [
          ListTile(title: Text("First")),
          ListTile(title: Text("Second")),
          ListTile(title: Text("Third")),
        ],
      ),
      child: XboxTileView(items: [
        if (games.isNotEmpty)
          XboxTileList(tiles: [
            for (var app in games.take(9))
              XboxTile.game(
                title: app.appName,
                size: const Size.square(80),
                image: MemoryImage(app.icon),
                growOnFocus: .8,
                menuItems: {
                  loc.open: () => app.openApp(),
                  loc.settings: () => app.openSettingsScreen(),
                  loc.uninstall: () => app.uninstallApp(),
                },
                onTap: () => app.openApp(),
              )
          ]),
        XboxTileList(tiles: [
          XboxTile.banner(
            title: loc.games,
            icon: Icons.videogame_asset,
            description: loc.openItem(loc.games),
            size: const Size(180, 120),
            images: games.orderByRandom.map((x) => MemoryImage(x.icon)).take(8).toList(),
            parallelogramTile: true,
          ),
          for (var app in games.orderByDescending((x) => x.updateTimeMillis).take(3))
            XboxTile.game(
              title: app.appName,
              size: const Size.square(120),
              image: MemoryImage(app.icon),
              menuItems: {
                loc.open: () => app.openApp(),
                loc.settings: () => app.openSettingsScreen(),
                loc.uninstall: () => app.uninstallApp(),
              },
              onTap: () => app.openApp(),
            ),
          XboxTile.icon(icon: Icons.settings, title: loc.settings, size: const Size.square(120), onTap: () => DeviceApps.openApp("com.android.settings")),
        ]),
        XboxTileList(tiles: [
          XboxTile.banner(
            title: loc.apps,
            icon: Icons.apps,
            description: loc.openItem(loc.apps),
            size: const Size(180, 120),
            images: visibleApps.orderByRandom.map((x) => MemoryImage(x.icon)).take(8).toList(),
            parallelogramTile: true,
            onTap: () => inn.to(() => appDashPage()),
          ),
          for (var app in visibleApps.orderByDescending((x) => x.updateTimeMillis).take(3))
            XboxTile.game(
              title: app.appName,
              size: const Size.square(120),
              image: MemoryImage(app.icon),
              menuItems: {
                loc.open: () => app.openApp(),
                loc.settings: () => app.openSettingsScreen(),
                loc.uninstall: () => app.uninstallApp(),
              },
              onTap: () => app.openApp(),
            ),
          XboxTile.icon(icon: Icons.settings, title: loc.settings, size: const Size.square(120), onTap: () => DeviceApps.openApp("com.android.settings")),
        ]),
      ]),
    );
  }

  @override
  void initState() {
    Xbox.accentColor = kwiqConfig.currentColor;
    Xbox.userWallpaper = kwiqConfig.currentWallpapers.firstOrNull?.image;
    deviceInfo.androidInfo.then((value) {
      setState(() {
        username = value.product;
        detail = value.model;
      });
    });
    super.initState();
  }
}
