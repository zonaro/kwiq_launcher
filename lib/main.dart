import 'dart:async';
import 'dart:io';

import 'package:access_wallpaper/access_wallpaper.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/models/kwiq_config.dart';
import 'package:kwiq_launcher/pages/home.dart';
import 'package:kwiq_launcher/pages/my_wallpapers.dart';
import 'package:new_device_apps/device_apps.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:pixabay_picker/pixabay_picker.dart';
import 'package:system_theme/system_theme.dart';
import 'package:wikipedia/wikipedia.dart';

void main() async {
  await innerLibsInit();

  loadApps().then((_) {
    Get.forceAppUpdate();
  });
  loadContacts().then((_) {
    Get.forceAppUpdate();
  });
  loadFiles().then((_) {
    Get.forceAppUpdate();
  });

  DeviceApps.listenToAppsChanges().listen((event) async {
    await loadApps();
    Get.forceAppUpdate();
  });

  FlutterContacts.addListener(() async {
    await loadContacts();
    Get.forceAppUpdate();
  });

  appDir = Directory("${(await ExternalPath.getExternalStorageDirectories()).firstOrNull ?? ((await getApplicationDocumentsDirectory()).path)}/KWIQ/".fixPath);

  await appDir.create(recursive: true);

  wallpaperDir = Directory("${await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_PICTURES)}/wallpapers/".fixPath);

  await wallpaperDir.create(recursive: true);

  if (wallpaperDir.listFilesSync.isEmpty) {
    saveLocalWallpaper();
  }

  SystemTheme.fallbackColor = kwiqConfig.currentColor;
  await SystemTheme.accentColor.load();

  runApp(const MainApp());
}

final AccessWallpaper accessWallpaper = AccessWallpaper();

late Directory appDir;

Set<ApplicationWithIcon> apps = {};

Set<Contact> contacts = {};

final DeviceCalendarPlugin deviceCalendarPlugin = DeviceCalendarPlugin();

List<File> files = [];

final loc = Get.context!.innerLibsLocalizations;

PixabayPicker pixabayClient = PixabayPicker(apiKey: "12247800-fcc1dd179273bc4b87782e68e");

late Directory wallpaperDir;

final Wikipedia wikipedia = Wikipedia();

Iterable<string> get categories => apps.expand((app) => kwiqConfig.getCategoriesOfApp(app)).orderBy((x) => x).map((x) => x.toTitleCase()).distinct();

Iterable<ApplicationWithIcon> get dockedApps => kwiqConfig.dockedApps.map((x) => apps.firstWhereOrNull((y) => x.packageName.flatEqual(y.packageName))).whereNotNull().orderBy((x) => x.appName);

Iterable<ApplicationWithIcon> get favoriteApps => kwiqConfig.favoriteApps.map((x) => apps.firstWhereOrNull((y) => x.packageName.flatEqual(y.packageName))).whereNotNull().orderBy((x) => x.appName);

Directory get gamesDir => Directory("${appDir.path}/Games/".fixPath);

Directory get gamesWallDir => Directory("${appDir.path}/Scrap/Games/".fixPath);

bool get hasSpotify => apps.map((x) => x.packageName).containsAny(['com.spotify.music', 'com.spotify.lite', "com.spotify.tv.android"]);
bool get hasWhatsapp => apps.map((x) => x.packageName).containsAny(['com.whatsapp', 'com.whatsapp.w4b']);

Iterable<ApplicationWithIcon> get hiddenApps => kwiqConfig.hiddenApps.map((x) => apps.firstWhereOrNull((y) => x.packageName.flatEqual(y.packageName))).whereNotNull().orderBy((x) => x.appName);

Directory get musicWallDir => Directory("${appDir.path}/Scrap/Music/".fixPath);

Iterable<Contact> get starredContacts => contacts.where((contact) => contact.isStarred);

Iterable<string> get tokenList => tokens.keys;

Map<string, string> get tokens => {
      ':': loc.apps,
      '@': loc.contacts,
      '#': loc.categories,
      '>': loc.commands,
      '=': loc.calculate,
      '/': loc.files,
    };

Iterable<ApplicationWithIcon> get visibleApps => apps.whereNot((app) => hiddenApps.contains(app));

Map<string, Iterable<ApplicationWithIcon>> get visibleAppsByCategory => Map.fromEntries(categories.map((category) => MapEntry(category, visibleApps.where((app) => kwiqConfig.getCategoriesOfApp(app).contains(category)))));

Future<Iterable<File>> get wallpaperFiles async => (await wallpaperDir.listFilesRecursive).where((file) => file.fileExtensionWithoutDot.isIn(['jpg', 'jpeg', 'png']));

Future<Set<ApplicationWithIcon>> loadApps() async {
  apps = (await DeviceApps.getInstalledApplications(
    includeAppIcons: true,
    includeSystemApps: true,
    onlyAppsWithLaunchIntent: true,
  ))
      .whereType<ApplicationWithIcon>()
      .toSet();
  return apps;
}

Future<Set<Contact>> loadContacts() async {
  await FlutterContacts.requestPermission();

  contacts = (await FlutterContacts.getContacts(
    withProperties: true,
    withPhoto: true,
    withAccounts: true,
    withGroups: true,
    withThumbnail: true,
    deduplicateProperties: true,
    sorted: true,
  ))
      .toSet();
  return contacts;
}

Future<Iterable<File>> loadFiles([Directory? dir, bool showHidden = false]) async {
  PermissionStatus permissionResult = await Permission.manageExternalStorage.request();
  if (permissionResult == PermissionStatus.granted) {
    var paths = (await ExternalPath.getExternalStorageDirectories()).map((x) => Directory(x.fixPath));
    if (dir == null) {
      for (var path in paths) {
        try {
          files.addAll(await loadFiles(path, showHidden));
        } finally {}
      }
    } else {
      for (var entry in await dir.listAll) {
        try {
          if (showHidden == false && entry.path.split('/').last.startsWith('.')) {
            continue;
          }
          if (entry is File) {
            files.add(entry);
          } else if (entry is Directory) {
            if (entry.path.containsAny(paths.map((p) => '${p.path}/Android'))) {
              continue;
            }

            var subfiles = await loadFiles(entry, showHidden);
            try {
              files.addAll(subfiles);
            } finally {}
          }
        } catch (e) {
          if (e is FileSystemException) {
            consoleLog('Access denied: ${e.path}');
          } else {
            consoleLog(e);
          }
        }
      }
    }
  }
  files = files.distinctBy((x) => x.path).toList();
  return files;
}

void saveLocalWallpaper() async {
  Uint8List? wallpaperBytes = await accessWallpaper.getWallpaper(AccessWallpaper.homeScreenFlag);
  if (wallpaperBytes != null && wallpaperBytes.isNotEmpty) {
    wallpaperDir.createSync(recursive: true);

    var f = await File("${wallpaperDir.path}/default.jpg".fixPath).writeAsBytes(wallpaperBytes);

    var wall = await WallpaperConfig.fromFile(f);
    if (wall != null) {
      wall.landscapeLightMode = true;
      wall.landscapeDarkMode = true;
    }

    kwiqConfig.save();
  }
}

typedef AppInfo = ApplicationWithIcon;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => GetMaterialApp(
        themeMode: kwiqConfig.themeMode,
        theme: ThemeData.from(colorScheme: ColorScheme.light(primary: kwiqConfig.currentColor)),
        darkTheme: ThemeData.from(colorScheme: ColorScheme.dark(primary: kwiqConfig.currentColor)),
        locale: Get.deviceLocale,
        localizationsDelegates: InnerLibsLocalizations.localizationsDelegates,
        supportedLocales: InnerLibsLocalizations.supportedLocales,
        home: const HomePage(),
        getPages: [
          GetPage(name: '/', page: () => const HomePage()),
          GetPage(name: '/wallhaven', page: () => const WallhavenWallpapersScreen()),
        ],
      );
}
