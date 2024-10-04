import 'dart:async';
import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:new_device_apps/device_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_theme/system_theme.dart';

import 'main_app.dart';

typedef AppInfo = ApplicationWithIcon;

Iterable<string> get tokenList => tokens.keys;

final loc = Get.context!.innerLibsLocalizations;

Map<string, string> get tokens => {
      ':': loc.apps,
      '@': loc.contacts,
      '#': loc.categories,
      '>': loc.files,
    };

late SharedPreferences prefs;

int get gridColumns => prefs.getInt('gridColumns') ?? 4;
set gridColumns(int value) => prefs.setInt('gridColumns', value);

Color get mainColor => prefs.getString('mainColor')?.asColor ?? SystemTheme.accentColor.accent;
set mainColor(Color value) => prefs.setString('mainColor', value.hexadecimal);

Iterable<string> get recentSearches => prefs.getStringList('recentSearches')?.map((s) => s.toString()).where((x) => x.isNotEmpty && x.isNotIn(tokenList) && !x.flatEqualAny(hiddenApps) && !x.flatEqualAny(apps.map((m) => m.appName))).distinctFlat().toList() ?? [];
set recentSearches(Iterable<String> value) => prefs.setStringList('recentSearches', value.distinctFlat().toList());

Iterable<string> addRecentSearch(String value) {
  recentSearches = [...recentSearches, value].where((x) => x.isNotEmpty && x.isNotIn(tokenList) && !x.flatEqualAny(hiddenApps) && !x.flatEqualAny(apps.map((m) => m.appName))).distinctFlat();
  return recentSearches;
}

List<string> get hiddenApps => prefs.getStringList('hiddenApps') ?? [];
set hiddenApps(List<String> value) => prefs.setStringList('hiddenApps', value.distinctFlat().toList());

List<string> get dockedApps => prefs.getStringList('dockedApps') ?? [];
set dockedApps(List<string> value) => prefs.setStringList('dockedApps', value.distinctFlat().toList());

Iterable<AppInfo> get homeApps => apps.where((app) => dockedApps.flatContains(app.packageName)).orderBy((x) => x.appName);

Iterable<string> getCategoriesOf(AppInfo app) => <string>[
      app.category.name,
      ...?prefs.getStringList('categories::${app.packageName}'),
    ].distinctFlat().orderBy((x) => x).map((x) => x.toTitleCase);

setCategoriesOf(AppInfo app, StringList categories) => prefs.setStringList('categories::${app.packageName}', categories.distinctFlat().toList());
addCategory(AppInfo app, string category) => setCategoriesOf(app, [...getCategoriesOf(app), category]);
removeCategory(AppInfo app, string category) => setCategoriesOf(app, getCategoriesOf(app).where((e) => e.flatEqual(category) == false).toList());

Set<AppInfo> apps = {};
Set<File> files = {};
Set<Contact> contacts = {};

Map<string, Iterable<AppInfo>> get visibleAppsByCategory => Map.fromEntries(categories.map((category) => MapEntry(category, visibleApps.where((app) => getCategoriesOf(app).contains(category)))));
Iterable<AppInfo> get visibleApps => apps.where((app) => !hiddenApps.contains(app.packageName)).orderBy((x) => x.appName);

StringList get categories => apps.selectMany((app, i) => getCategoriesOf(app)).orderBy((x) => x).map((x) => x.toTitleCase).distinct().toList();

Iterable<Contact> get starredContacts => contacts.where((contact) => contact.isStarred);

bool get hasWhatsapp => apps.map((x) => x.packageName).containsAny(['com.whatsapp', 'com.whatsapp.w4b']);

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

Future<Set<AppInfo>> loadApps() async {
  apps = (await DeviceApps.getInstalledApplications(
    includeAppIcons: true,
    includeSystemApps: true,
    onlyAppsWithLaunchIntent: true,
  ))
      .whereType<AppInfo>()
      .toSet();
  return apps;
}

Future<Set<File>> loadFiles() async {
// get the path of internal memory and sd card
  var paths = await ExternalPath.getExternalStorageDirectories();

  for (var path in paths) {
    var dir = Directory(path);

    if (await dir.exists()) {
      for (var f in await dir.listFiles) {
        files.add(f);
      }

      for (var f in await dir.listDirectories) {
        try {
          files.addAll(await f.listFilesRecursive);
        } catch (e) {
          consoleLog(e);
        }
      }
    }
  }
  return files;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDateFormatting();

  prefs = await SharedPreferences.getInstance();
  SystemTheme.fallbackColor = NamedColors.redColor;
  SystemTheme.onChange.listen((event) {
    mainColor = event.accent;
  });

  await loadApps();
  await loadContacts();
  await loadFiles();

  Timer.periodic(const Duration(seconds: 30), (timer) async {
    await loadApps();
    await loadContacts();
    await loadFiles();
  });

  runApp(const MainApp());
}
