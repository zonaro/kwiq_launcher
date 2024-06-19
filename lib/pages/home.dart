import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/contact_tile.dart';
import 'package:kwiq_launcher/components/digital_clock.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/search.dart';
import 'package:kwiq_launcher/pages/settings.dart';

import '../components/app_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RestartWidget(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const DigitalClock(),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                await context.push(const SettingsScreen());
                setState(() {});
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.search),
          onPressed: () => showSearch(context: context, delegate: MyAppSearchDelegate()),
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
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                    ]
                  ],
                ),
              ),
        body: PopScope(
          canPop: false,
          onPopInvoked: (p) {
            showSearch(context: context, delegate: MyAppSearchDelegate());
          },
          child: FutureAwaiter(
            data: apps,
            future: () async => await DeviceApps.getInstalledApplications(
              includeAppIcons: true,
              includeSystemApps: true,
              onlyAppsWithLaunchIntent: true,
            ),
            builder: (_) => gridColumns > 1 ? appGrid() : appList(),
          ),
        ),
      ),
    );
  }

  Widget appGrid() => SizedBox(
        height: context.height * .98,
        width: context.width,
        child: GridView.count(
          crossAxisCount: gridColumns,
          shrinkWrap: true,
          children: [
            for (var c in starredContacts)
              ContactTile(
                contact: c,
                gridColumns: gridColumns,
              ),
            for (var application in filteredApps)
              AppTile(
                application: application as ApplicationWithIcon,
                gridColumns: gridColumns,
              ),
          ],
        ),
      );

  Widget appList() => SizedBox(
        height: context.height,
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var c in starredContacts)
              ContactTile(
                contact: c,
                gridColumns: gridColumns,
              ),
            for (var application in filteredApps)
              AppTile(
                application: application as ApplicationWithIcon,
                gridColumns: 1,
              ),
            SizedBox(
              height: context.height * .12,
            ),
          ],
        ),
      );
}
