import 'dart:async';
import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kwiq_launcher/pages/home.dart';
import 'package:new_device_apps/device_apps.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:system_theme/system_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting();

  prefs = await SharedPreferences.getInstance();
  SystemTheme.fallbackColor = NamedColor.redColor;

  loadApps().then((_) {
    Get.forceAppUpdate();
  });
  loadContacts().then((_) {
    Get.forceAppUpdate();
  });
  loadFiles().then((_) {
    Get.forceAppUpdate();
  });

  SystemTheme.onChange.listen((event) {
    mainColor = event.accent;
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

  runApp(const MainApp());
}

Set<ApplicationWithIcon> apps = {};

Set<Contact> contacts = {};

Set<File> files = {};

final loc = Get.context!.innerLibsLocalizations;

late SharedPreferences prefs;

StringList get categories => apps.selectMany((app, i) => getCategoriesOf(app)).orderBy((x) => x).map((x) => x.toTitleCase()).distinct().toList();
List<string> get dockedApps => prefs.getStringList('dockedApps') ?? [];

set dockedApps(List<string> value) => prefs.setStringList('dockedApps', value.distinctFlat().toList());
int get gridColumns => prefs.getInt('gridColumns') ?? 4;

set gridColumns(int value) => prefs.setInt('gridColumns', value);
bool get hasSpotify => apps.map((x) => x.packageName).containsAny(['com.spotify.music', 'com.spotify.lite', "com.spotify.tv.android"]);

bool get hasWhatsapp => apps.map((x) => x.packageName).containsAny(['com.whatsapp', 'com.whatsapp.w4b']);

List<string> get hiddenApps => prefs.getStringList('hiddenApps') ?? [];
set hiddenApps(List<String> value) => prefs.setStringList('hiddenApps', value.distinctFlat().toList());

Iterable<ApplicationWithIcon> get homeApps => apps.where((app) => dockedApps.flatContains(app.packageName)).orderBy((x) => x.appName);
Color get mainColor => prefs.getString('mainColor')?.asColor ?? SystemTheme.accentColor.accent;

set mainColor(Color value) => prefs.setString('mainColor', value.hexadecimal);

Iterable<string> get recentSearches =>
    prefs
        .getStringList('recentSearches')
        ?.map((s) => s.toString())
        .where((x) => x.isNotEmpty && x.isNotIn(tokenList) && !x.flatEqualAny(hiddenApps) && !x.flatEqualAny(apps.map((m) => m.appName)))
        .distinctFlat()
        .toList() ??
    [];

set recentSearches(Iterable<String> value) => prefs.setStringList('recentSearches', value.distinctFlat().toList());
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
Iterable<ApplicationWithIcon> get visibleApps => apps.where((app) => !hiddenApps.contains(app.packageName)).orderBy((x) => x.appName);

Map<string, Iterable<ApplicationWithIcon>> get visibleAppsByCategory =>
    Map.fromEntries(categories.map((category) => MapEntry(category, visibleApps.where((app) => getCategoriesOf(app).contains(category)))));

addCategory(ApplicationWithIcon app, string category) => setCategoriesOf(app, [...getCategoriesOf(app), category]);

Iterable<string> addRecentSearch(String value) {
  recentSearches = [...recentSearches, value].where((x) => x.isNotEmpty && x.isNotIn(tokenList) && !x.flatEqualAny(hiddenApps) && !x.flatEqualAny(apps.map((m) => m.appName))).distinctFlat();
  return recentSearches;
}

Iterable<string> getCategoriesOf(ApplicationWithIcon app) => <string>[
      app.category.name,
      ...?prefs.getStringList('categories::${app.packageName}'),
    ].distinctFlat().orderBy((x) => x).map((x) => x.toTitleCase());

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

Future<Set<File>> loadFiles([Directory? dir]) async {
  files = {};

  PermissionStatus permissionResult = await Permission.manageExternalStorage.request();
  if (permissionResult == PermissionStatus.granted) {
    // code of read or write file in external storage (SD card)

// get the path of internal memory and sd card
    var paths = (await ExternalPath.getExternalStorageDirectories()).map((x) => Directory(x.fixPath));
    if (dir == null) {
      for (var path in paths) {
        files.addAll(await loadFiles(path));
      }
      for (var entry in await dir!.listAll) {
        try {
          if (entry is File) {
            files.add(entry);
          } else if (entry is Directory) {
            if (entry.path.containsAny(paths.map((p) => '${p.path}/Android'))) {
              continue;
            }
            var subfiles = await loadFiles(entry);
            files.addAll(subfiles);
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
  return files;
}

removeCategory(ApplicationWithIcon app, string category) => setCategoriesOf(app, getCategoriesOf(app).where((x) => !x.flatEqual(category)));

void removeRecentSearch(String value) {
  recentSearches = recentSearches.where((x) => x != value).toList();
}

setCategoriesOf(ApplicationWithIcon app, Iterable<string> value) => prefs.setStringList('categories::${app.packageName}', value.distinctFlat().toList());

typedef AppInfo = ApplicationWithIcon;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => ResponsiveSizer(builder: (context, orientation, screenType) {
        return GetMaterialApp(
          themeMode: ThemeMode.system,
          theme: ThemeData.from(colorScheme: ColorScheme.light(primary: mainColor)),
          darkTheme: ThemeData.from(colorScheme: ColorScheme.dark(primary: mainColor)),
          locale: Get.deviceLocale,
          localizationsDelegates: InnerLibsLocalizations.localizationsDelegates,
          supportedLocales: InnerLibsLocalizations.supportedLocales,
          home: const HomePage(),
        );
      });
}
