import 'package:flutter/material.dart';
import 'package:kwiq_launcher/main.dart';

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
              // TODO: Implement wallpaper settings
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
          ),
          const AboutListTile(),
        ],
      ),
    );
  }
}
