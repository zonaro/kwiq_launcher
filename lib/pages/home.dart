import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/contact_tile.dart';
import 'package:kwiq_launcher/components/digital_clock.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/file_manager.dart';
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

  IconData categoryIcon(string category) {
    switch (category.toTitleCase) {
      case "Audio":
        return Icons.audiotrack;
      case "Books":
        return Icons.book;
      case "Business":
        return Icons.business;
      case "Communication":
        return Icons.chat;
      case "Education":
        return Icons.school;
      case "Entertainment":
        return Icons.movie;
      case "Finance":
        return Icons.monetization_on;
      case "Food & Drink":
        return Icons.fastfood;
      case "Games":
      case "Game":
        return Icons.games;
      case "Health & Fitness":
        return Icons.fitness_center;
      case "House & Home":
      case "House":
      case "Home":
        return Icons.home;
      case "Image":
        return Icons.image;
      case "Lifestyle":
        return Icons.favorite;
      case "Maps & Navigation":
        return Icons.map;
      case "Medical":
        return Icons.local_hospital;
      case "Music":
      case "Music & Audio":
        return Icons.music_note;
      case "News & Magazines":
        return Icons.article;
      case "Personalization":
        return Icons.palette;
      case "Photography":
        return Icons.camera;
      case "Productivity":
        return Icons.work;
      case "Shopping":
        return Icons.shopping_cart;
      case "Social":
        return Icons.people;
      case "Sports":
        return Icons.sports;
      case "Tools":
        return Icons.build;
      case "Travel & Local":
        return Icons.airplanemode_active;
      case "Video":
      case "Video Players & Editors":
        return Icons.video_library;
      case "Weather":
        return Icons.wb_sunny;
      case "Map":
      case "Maps":
        return Icons.map;
      default:
        return Icons.category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RestartWidget(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const DigitalClock(),
          actions: [
            IconButton(
              icon: const Icon(Icons.folder),
              onPressed: () async {
                await context.push(FilePage());

                setState(() {});
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () async {
                await context.push(const SettingsScreen());
                setState(() {});
              },
            ),
          ],
        ),
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
                            setState(() {});
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
              setState(() {});
            },
          ),
        ),
        floatingActionButtonLocation: dockedAppsList.isNotEmpty ? FloatingActionButtonLocation.endContained : null,
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
                        onPop: () => setState(() {}),
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
          onPopInvoked: (p) async {
            await showSearch(context: context, delegate: MyAppSearchDelegate());
            setState(() {});
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
                onPop: () => setState(() {}),
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
                onPop: () => setState(() {}),
              ),
            SizedBox(
              height: context.height * .12,
            ),
          ],
        ),
      );
}
