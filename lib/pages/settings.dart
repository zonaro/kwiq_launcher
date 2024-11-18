// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/models/kwiq_config.dart';
import 'package:kwiq_launcher/pages/my_wallpapers.dart';
import 'package:new_device_apps/device_apps.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:system_theme/system_theme.dart';

final loc = Get.context!.innerLibsLocalizations;

Future<void> showColorPicker(BuildContext context) async {
  await showDialog(
    context: context,
    builder: (BuildContext context) {
      Color selectedColor = kwiqConfig.accentColor;
      return AlertDialog(
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: selectedColor,
            onColorChanged: (color) {
              selectedColor = color;
            },
            labelTypes: const [ColorLabelType.rgb],
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              await SystemTheme.accentColor.load();
              selectedColor = SystemTheme.accentColor.accent;

              Get.forceAppUpdate();
            },
            child: loc.defaultWord.asText(),
          ),
          TextButton(
            child: context.materialLocalizations.cancelButtonLabel.asText(),
            onPressed: () {
              context.pop();
            },
          ),
          TextButton(
            child: context.materialLocalizations.okButtonLabel.asText(),
            onPressed: () {
              kwiqConfig.accentColor = selectedColor;
              kwiqConfig.currentColor = selectedColor;
              context.pop();
              Get.forceAppUpdate();
            },
          ),
        ],
      );
    },
  );
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text(loc.settings),
            onTap: () {
              DeviceApps.openApp("com.android.settings");
            },
          ),
          ListTile(
            title: Text(loc.wallpaper),
            onTap: () {
              inn.to(() => const MyWallpapersScreen());
            },
          ),
          ListTile(
            title: Text(loc.mainColor),
            onTap: () async {
              await showColorPicker(context);
              await Get.forceAppUpdate();
            },
          ),
          SwitchListTile(
            value: kwiqConfig.themeFollowWallpaper,
            onChanged: (v) {
              setState(() {
                kwiqConfig.themeFollowWallpaper = v;
              });
              Get.forceAppUpdate();
            },
            title: Text("${loc.color} ${loc.follow} ${loc.wallpaper}"),
          ),
          ListTile(
            subtitle: Text(switch (kwiqConfig.themeMode) { ThemeMode.light => loc.lightMode, ThemeMode.dark => loc.darkMode, ThemeMode.system => loc.defaultWord }),
            onTap: () async {
              await showDialog(
                context: context,
                builder: (context) => SimpleDialog(
                  title: Text(loc.themeMode),
                  children: [
                    SimpleDialogOption(
                      onPressed: () {
                        kwiqConfig.themeMode = ThemeMode.light;
                        Get.back();
                      },
                      child: Text(loc.lightMode),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        kwiqConfig.themeMode = ThemeMode.dark;
                        Get.back();
                      },
                      child: Text(loc.darkMode),
                    ),
                    SimpleDialogOption(
                      onPressed: () {
                        kwiqConfig.themeMode = ThemeMode.system;
                        Get.back();
                      },
                      child: Text(loc.defaultWord),
                    ),
                  ],
                ),
              );

              Get.changeThemeMode(kwiqConfig.themeMode);

              await Get.forceAppUpdate();
            },
            title: Text(loc.themeMode),
          ),
          ListTile(
            title: Text(loc.gridSize),
            subtitle: Slider(
              min: 1,
              max: 8,
              divisions: 8,
              value: kwiqConfig.portraitGridColumns.toDouble(),
              onChanged: (newValue) {
                setState(() {
                  kwiqConfig.portraitGridColumns = newValue.floor();
                });
                Get.forceAppUpdate();
              },
            ),
            trailing: CircleAvatar(
              backgroundColor: kwiqConfig.currentColor,
              child: Text('${kwiqConfig.gridColumns}'),
            ),
          ),
          ListTile(
            title: Text('${loc.wallpaperInterval} (${loc.seconds})'),
            subtitle: Slider(
              min: 10,
              max: 1000,
              value: kwiqConfig.wallpaperInterval.toPrecision(2),
              onChanged: (newValue) {
                setState(() {
                  kwiqConfig.wallpaperInterval = newValue.clamp(10, 1000).round();
                });
                Get.forceAppUpdate();
              },
            ),
            trailing: CircleAvatar(
              backgroundColor: kwiqConfig.currentColor,
              child: Text('${kwiqConfig.wallpaperInterval.toPrecision(2)}'),
            ),
          ),
          ListTile(
            title: Text('${loc.wallpaperFadeTime} (${loc.milliseconds})'),
            subtitle: Slider(
              min: 0,
              max: 1000,
              divisions: 240,
              value: kwiqConfig.wallpaperFadeDuration.toDouble(),
              onChanged: (newValue) {
                setState(() {
                  kwiqConfig.wallpaperFadeDuration = newValue.clamp(0, 1000).toInt();
                });
                Get.forceAppUpdate();
              },
            ),
            trailing: CircleAvatar(
              backgroundColor: kwiqConfig.currentColor,
              child: Text('${kwiqConfig.wallpaperFadeDuration}'),
            ),
          ),
          ListTile(
            title: Text(loc.overlayOpacity),
            subtitle: Slider(
              min: 0,
              max: 1,
              divisions: 50,
              value: kwiqConfig.overlayOpacity,
              onChanged: (newValue) {
                setState(() {
                  kwiqConfig.overlayOpacity = newValue.clamp(0, 1);
                });
                Get.forceAppUpdate();
              },
            ),
            trailing: CircleAvatar(
              backgroundColor: kwiqConfig.currentColor,
              child: Text('${kwiqConfig.overlayOpacity * 100}'),
            ),
          ),
          ListTile(
            title: Text(loc.dateTimeFormat),
            subtitle: TextFormField(
              maxLines: 2,
              initialValue: kwiqConfig.dateTimeFormat,
              onChanged: (newValue) {
                setState(() {
                  kwiqConfig.dateTimeFormat = newValue;
                });
                Get.forceAppUpdate();
              },
            ),
          ),
          FutureAwaiter(
            future: () async => PackageInfo.fromPlatform(),
            builder: (info) => AboutListTile(
              applicationName: info.appName,
              applicationVersion: info.version,
              applicationIcon: Image.asset('assets/kwiq.png', width: 70, height: 70),
              applicationLegalese: '© ${now.year} Kaizonaro Apps',
            ),
          ),
        ],
      ),
    );
  }
}
