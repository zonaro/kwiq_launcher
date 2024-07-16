import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:system_theme/system_theme.dart';

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
        title: const Text('App Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Wallpaper'),
            onTap: () {
              context.showSnackBar("Soon...");
            },
          ),
          ListTile(
            title: const Text('Main Color'),
            onTap: () {
              showColorPicker(context);
            },
          ),
          ListTile(
            title: const Text('Grid Size'),
            subtitle: Slider(
              min: 1,
              max: 8,
              divisions: 8,
              value: gridColumns.toDouble(),
              onChanged: (newValue) {
                setState(() {
                  gridColumns = newValue.floor();
                });
              },
            ),
            trailing: Text('$gridColumns'),
          ),
          FutureAwaiter(
            future: () async => PackageInfo.fromPlatform(),
            builder: (info) => AboutListTile(
              applicationName: info.appName,
              applicationVersion: info.version,
              applicationIcon: Image.asset('assets/kwiq.png', width: 60, height: 60),
              applicationLegalese: '© ${now.year} Kaizonaro Apps',
            ),
          ),
        ],
      ),
    );
  }
}

void showColorPicker(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      Color selectedColor = mainColor;
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
            },
            child: "Default".asText(),
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
              mainColor = selectedColor;

              Get.changeTheme(ThemeData.from(colorScheme: Get.isDarkMode ? ColorScheme.dark(primary: mainColor) : ColorScheme.light(primary: mainColor)));
            },
          ),
        ],
      );
    },
  );
}
