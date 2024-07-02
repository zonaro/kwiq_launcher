// ignore_for_file: use_build_context_synchronously

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/app_tile.dart';
import 'package:kwiq_launcher/components/digital_clock.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/app_page.dart';
import 'package:kwiq_launcher/pages/file_manager.dart';
import 'package:kwiq_launcher/pages/search.dart';
import 'package:kwiq_launcher/pages/settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final PageController controller = PageController();
    return RestartWidget(
      child: Sizer(
        builder: (context, orientation, deviceType) => GetMaterialApp(
          themeMode: ThemeMode.system,
          theme: ThemeData.light().copyWith(primaryColor: mainColor),
          darkTheme: ThemeData.dark().copyWith(primaryColor: mainColor),
          home: Scaffold(
            floatingActionButton: GestureDetector(
              onLongPress: () async {
                if (categories.isNotEmpty) {
                  await showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return ListView(
                        children: [
                          for (var category in categories)
                            ListTile(
                              leading: Icon(categoryIcon(category)),
                              trailing: Text(filteredAppsByCategory[category]?.length.toString() ?? "0"),
                              title: Text(category),
                              onTap: () async {
                                context.pop();
                                await showSearch(context: context, delegate: MyAppSearchDelegate(category));
                              },
                            ),
                        ],
                      );
                    },
                  );
                }
              },
              child: FloatingActionButton(
                child: const Icon(Icons.search),
                onPressed: () async {
                  await showSearch(context: context, delegate: MyAppSearchDelegate());
                },
              ),
            ),
            floatingActionButtonLocation: dockedAppsList.isNotEmpty ? FloatingActionButtonLocation.endContained : null,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const DigitalClock(),
              actions: [
                IconButton(
                  icon: const Icon(Icons.folder),
                  onPressed: () async {
                    await [
                      Permission.storage,
                      Permission.manageExternalStorage,
                    ].request();
                    if (await Permission.storage.isGranted || await Permission.manageExternalStorage.isGranted) {}
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () async {
                    await context.push(const SettingsScreen());
                    context.restartApp();
                  },
                ),
              ],
            ),
            bottomNavigationBar: dockedAppsList.isEmpty
                ? null
                : BottomAppBar(
                    child: ListView(
                      shrinkWrap: true,
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (var docked in dockedAppsList) ...[
                          AppTile(
                            application: docked as ApplicationWithIcon,
                            gridColumns: gridColumns.lockMin(3),
                            showLabel: false,
                            onPop: () {},
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                        ]
                      ],
                    ),
                  ),
            body: PageView(
              controller: controller,
              children: const [
                AppPage(),
                FilePage(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
