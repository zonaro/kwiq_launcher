import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:new_device_apps/device_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_theme/system_theme.dart';

import 'main_app.dart';

typedef AppInfo = ApplicationWithIcon;

const tokens = [':', '@', '#', '>'];

late SharedPreferences prefs;

int get gridColumns => prefs.getInt('gridColumns') ?? 4;
set gridColumns(int value) => prefs.setInt('gridColumns', value);

Color get mainColor => prefs.getString('mainColor')?.asColor ?? SystemTheme.accentColor.accent;
set mainColor(Color value) => prefs.setString('mainColor', value.hexadecimal);

List<string> get recentSearches => prefs.getStringList('recentSearches')?.map((s) => s.toString()).where((x) => x.isNotEmpty && x.isNotIn(tokens) && !x.flatEqualAny(hiddenApps) && !x.flatEqualAny(apps.map((m) => m.appName))).distinctFlat().toList() ?? [];
set recentSearches(List<String> value) => prefs.setStringList('recentSearches', value.distinctFlat().toList());

List<string> addRecentSearch(String value) {
  recentSearches = [...recentSearches, value].where((x) => x.isNotEmpty && x.isNotIn(tokens) && !x.flatEqualAny(hiddenApps) && !x.flatEqualAny(apps.map((m) => m.appName))).distinctFlat().toList();
  return recentSearches;
}

List<string> get hiddenApps => prefs.getStringList('hiddenApps') ?? [];
set hiddenApps(List<String> value) => prefs.setStringList('hiddenApps', value.distinctFlat().toList());

List<string> get dockedApps => prefs.getStringList('dockedApps') ?? [];
set dockedApps(List<string> value) => prefs.setStringList('dockedApps', value.distinctFlat().toList());

Iterable<AppInfo> get homeApps => apps.where((app) => dockedApps.flatContains(app.packageName)).orderBy((x) => x.appName);

List<string> getCategoriesOf(AppInfo app) => <string>[
      app.category.name,
      ...?prefs.getStringList('categories::${app.packageName}'),
    ].distinctFlat().orderBy((x) => x).map((x) => x.toTitleCase).toList();

setCategoriesOf(AppInfo app, StringList categories) => prefs.setStringList('categories::${app.packageName}', categories.distinctFlat().toList());
addCategory(AppInfo app, string category) => setCategoriesOf(app, getCategoriesOf(app) + [category]);
removeCategory(AppInfo app, string category) => setCategoriesOf(app, getCategoriesOf(app).where((e) => e.flatEqual(category) == false).toList());

List<AppInfo> apps = [];

Map<string, List<AppInfo>> get filteredAppsByCategory => Map.fromEntries(categories.map((category) => MapEntry(category, filteredApps.where((app) => getCategoriesOf(app).contains(category)).toList())));
List<AppInfo> get filteredApps => apps.where((app) => !hiddenApps.contains(app.packageName)).orderBy((x) => x.appName).toList();

StringList get categories => apps.selectMany((app, i) => getCategoriesOf(app)).orderBy((x) => x).map((x) => x.toTitleCase).distinct().toList();

List<Contact> contacts = [];

List<Contact> get starredContacts => contacts.where((contact) => contact.isStarred).toList();

bool hasWhatsapp = false;

Future<List<Contact>> loadContacts() async {
  await FlutterContacts.requestPermission();

  contacts = await FlutterContacts.getContacts(
    withProperties: true,
    withPhoto: true,
    withAccounts: true,
    withGroups: true,
    withThumbnail: true,
    deduplicateProperties: true,
    sorted: true,
  );
  return contacts;
}

Future<List<AppInfo>> loadApps() async {
  apps = (await DeviceApps.getInstalledApplications(
    includeAppIcons: true,
    includeSystemApps: true,
    onlyAppsWithLaunchIntent: true,
  ))
      .whereType<AppInfo>()
      .toList();
  return apps;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  prefs = await SharedPreferences.getInstance();
  SystemTheme.fallbackColor = "#f6373f".asColor;

  await loadApps();
  await loadContacts();

  runApp(const MainApp());
}
