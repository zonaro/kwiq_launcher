import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:system_theme/system_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

final loc = Get.context!.innerLibsLocalizations;

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
            title: Text(loc.wallpaper),
            onTap: () {
              context.showSnackBar("Soon...");
            },
          ),
          ListTile(
            title: Text('${loc.main} ${loc.color}'),
            onTap: () async {
              await showColorPicker(context);
              await Get.forceAppUpdate();
            },
          ),
          ListTile(
            title: Text(loc.gridSize),
            subtitle: Slider(
              min: 1,
              max: 8,
              divisions: 8,
              value: gridColumns.toDouble(),
              onChanged: (newValue) {
                setState(() {
                  gridColumns = newValue.floor();
                });
                Get.forceAppUpdate();
              },
            ),
            trailing: CircleAvatar(
              backgroundColor: mainColor,
              child: Text('$gridColumns'),
            ),
          ),
          FutureAwaiter(
            future: () async => PackageInfo.fromPlatform(),
            builder: (info) => AboutListTile(
              applicationName: info.appName,
              applicationVersion: info.version,
              applicationIcon: Image.asset('assets/kwiq.png', width: 80, height: 80),
              applicationLegalese: '© ${now.year} Kaizonaro Apps',
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showColorPicker(BuildContext context) async {
  await showDialog(
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
              mainColor = selectedColor;
              Get.changeTheme(ThemeData.from(colorScheme: Get.isDarkMode ? ColorScheme.dark(primary: mainColor) : ColorScheme.light(primary: mainColor)));
              context.pop();
              Get.forceAppUpdate();
            },
          ),
        ],
      );
    },
  );
}
