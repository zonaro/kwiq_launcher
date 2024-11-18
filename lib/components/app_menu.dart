// ignore_for_file: use_build_context_synchronously

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/categories.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/models/kwiq_config.dart';
import 'package:new_device_apps/device_apps.dart';
import 'package:url_launcher/url_launcher.dart';

class MyAppMenuScreen extends StatelessWidget {
  final string packageName;

  const MyAppMenuScreen({super.key, required this.packageName});

  @override
  Widget build(BuildContext context) {
    var cfg = kwiqConfig.getAppConfig(packageName);
    return Scaffold(
      appBar: AppBar(
        title: loc.appSettings.asText(),
      ),
      body: FutureAwaiter(
        future: () async {
          var app = (await DeviceApps.getApp(packageName, true) as ApplicationWithIcon);
          var img = MemoryImage(app.icon);
          var scheme = await ColorScheme.fromImageProvider(provider: img, brightness: context.themeBrightness);
          return (app, img, scheme);
        },
        builder: (r) {
          final app = r.$1;
          final img = r.$2;
          final scheme = r.$3;
          return Center(
            child: Theme(
              data: context.theme.copyWith(colorScheme: scheme, brightness: context.themeBrightness),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    height: context.height,
                    width: context.width,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: img,
                        fit: BoxFit.contain,
                        alignment: Alignment.topCenter,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.1),
                          BlendMode.dstATop,
                        ),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.transparent,
                          scheme.primary,
                        ],
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                      ),
                    ),
                  ).setOpacity(opacity: .3),
                  ResponsiveRow.withColumns(
                    alignment: WrapAlignment.center,
                    children: [
                      ResponsiveColumn.full(
                        child: Column(
                          children: [
                            const Gap(20),
                            if (app.icon.isNotEmpty) Image.memory(app.icon, height: 100),
                            const Gap(16),
                            Text(app.appName, style: const TextStyle(fontSize: 24)),
                            const Gap(10),
                            Text(app.packageName).onLongPress(() {
                              Clipboard.setData(ClipboardData(text: app.packageName));
                            })!,
                            const Gap(32),
                          ],
                        ),
                      ),
                      ListView(
                        shrinkWrap: true,
                        children: [
                          ListTile(
                            leading: const Icon(Icons.open_in_new),
                            title: Text(loc.openItem(loc.app)),
                            onTap: () => app.openApp(),
                          ),
                          Divider(color: scheme.primary),
                          ListTile(
                            leading: Icon(kwiqConfig.dockedApps.flatContains(app.packageName) ? Icons.push_pin : Icons.push_pin_outlined),
                            title: Text(kwiqConfig.dockedApps.flatContains(app.packageName) ? "${loc.undock} ${loc.app}" : "${loc.dock} ${loc.app}"),
                            onTap: () {
                              cfg.isDocked = !cfg.isDocked;
                              kwiqConfig.save();
                              Get.forceAppUpdate();
                            },
                          ),
                          ListTile(
                            leading: Icon(kwiqConfig.favoriteApps.flatContains(app.packageName) ? Icons.favorite : Icons.favorite_border),
                            title: Text(kwiqConfig.favoriteApps.flatContains(app.packageName) ? loc.removeFromfavorites : loc.addTo(loc.favorites)),
                            onTap: () {
                              cfg.isFavorite = !cfg.isFavorite;
                              kwiqConfig.save();
                              Get.forceAppUpdate();
                            },
                          ),
                          ListTile(
                            leading: Icon(kwiqConfig.hiddenApps.flatContains(app.packageName) ? Icons.visibility_off : Icons.visibility),
                            title: Text(kwiqConfig.hiddenApps.flatContains(app.packageName) ? '${loc.show} ${loc.app}' : '${loc.hide} ${loc.app}'),
                            onTap: () {
                              cfg.isHidden = !cfg.isHidden;
                              kwiqConfig.save();
                              Get.forceAppUpdate();
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.category),
                            title: Text(loc.categories),
                            onTap: () async {
                              await context.push(CategoriesPage(app: app));
                              Get.forceAppUpdate();
                            },
                          ),
                          Divider(color: scheme.primary),
                          ListTile(
                            leading: const Icon(Icons.settings),
                            title: Text(loc.appSettings),
                            onTap: () => app.openSettingsScreen(),
                          ),
                          ListTile(
                            leading: const Icon(Icons.shop),
                            title: Text(loc.openItem("Play Store")),
                            onTap: () {
                              launchUrl(Uri.parse("https://play.google.com/store/apps/details?id=${app.packageName}"));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
