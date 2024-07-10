import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/app_tile.dart';
import 'package:kwiq_launcher/components/contact_tile.dart';
import 'package:kwiq_launcher/components/digital_clock.dart';
import 'package:kwiq_launcher/main.dart';

class Windows11MimicScreen extends StatefulWidget {
  const Windows11MimicScreen({super.key});

  @override
  createState() => _Windows11MimicScreenState();
}

class _Windows11MimicScreenState extends State<Windows11MimicScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            width: context.width,
            height: context.height - 50,
            child: FloatingArea(
              children: [
                for (var c in starredContacts)
                  ContactTile(
                    contact: c,
                    gridColumns: gridColumns,
                  ),
                for (var application in homeApps)
                  AppTile(
                    gridColumns: 1,
                    packageName: application,
                    onPop: () {},
                  ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.grey[900],
              height: 50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ícones à esquerda
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.wb_sunny),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  // Ícones no centro
                  Row(
                    children: [
                      PopupMenuButton(
                        position: PopupMenuPosition.over,
                        icon: const Icon(Icons.apps),
                        iconColor: mainColor,
                        itemBuilder: (BuildContext context) {
                          return [
                            for (var k in filteredAppsByCategory.keys)
                              PopupMenuItem(
                                child: PopupMenuButton(
                                    child: Row(
                                      children: [
                                        categoryIcon(k).asIcon(),
                                        Text(k.toTitleCase),
                                      ],
                                    ),
                                    itemBuilder: (BuildContext context) {
                                      return [
                                        for (var app in filteredAppsByCategory[k] ?? [])
                                          PopupMenuItem(
                                            value: app.appName,
                                            child: AppTile(
                                              onPop: () {},
                                              gridColumns: 1,
                                              packageName: app,
                                            ),
                                          )
                                      ];
                                    }),
                              ),
                          ];
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SizedBox(
                          height: 30,
                          width: 100,
                          child: TextFormField(
                            decoration: InputDecoration(
                              hintText: 'Pesquisar',
                              hintStyle: const TextStyle(color: Colors.white, fontSize: 12),
                              filled: true,
                              fillColor: Colors.grey[800],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(25),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.folder_open),
                        onPressed: () {},
                      ),
                      for (var app in homeApps)
                        AppTile(
                          onPop: () {},
                          gridColumns: 1,
                          packageName: app,
                        ),
                    ],
                  ),
                  // Ícones à direita
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.wifi, size: 12),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 12),
                        onPressed: () {},
                      ),
                      const DigitalClock(
                        format: 'HH:mm:ss',
                        textStyle: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.notifications, size: 12),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.android, size: 12),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
