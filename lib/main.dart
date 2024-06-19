import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_theme/system_theme.dart';

import 'main_app.dart';

late SharedPreferences prefs;

int get gridColumns => prefs.getInt('gridColumns') ?? 4;
set gridColumns(int value) => prefs.setInt('gridColumns', value);

Color get mainColor => prefs.getString('mainColor')?.asColor ?? SystemTheme.fallbackColor;
set mainColor(Color value) => prefs.setString('mainColor', value.hexadecimal);

List<string> get recentSearches => (prefs.getStringList('recentSearches') ?? []).where((x) => x.isNotEmpty && !x.flatEqualAny(hiddenApps) && !x.flatEqualAny(apps.value?.map((m) => m.appName) ?? [])).toList();
set recentSearches(List<String> value) => prefs.setStringList('recentSearches', value.distinctFlat());

List<string> get hiddenApps => prefs.getStringList('hiddenApps') ?? [];
set hiddenApps(List<String> value) => prefs.setStringList('hiddenApps', value.distinctFlat());

List<string> get dockedApps => prefs.getStringList('dockedApps') ?? [];
set dockedApps(List<String> value) => prefs.setStringList('dockedApps', value.distinctFlat());

List<string> getCategoriesOf(string packageName) => <string>[...(prefs.getStringList('categories::$packageName') ?? []), apps.value?.where((app) => app.packageName == packageName).firstOrNull?.category.name ?? ""].distinctFlat().orderBy((x) => x).map((x) => x.toTitleCase).toList();
setCategoriesOf(string packageName, strings categories) => prefs.setStringList('categories::$packageName', categories);

final AwaiterData<List<Application>> apps = AwaiterData<List<Application>>();

Map<string, List<Application>> get filteredAppsByCategory => Map.fromEntries(categories.map((category) => MapEntry(category, filteredApps.where((app) => getCategoriesOf(app.packageName).contains(category)).toList())));
List<Application> get filteredApps => apps.value?.where((app) => !hiddenApps.contains(app.packageName)).orderBy((x) => x.appName).toList() ?? [];

List<Application> get dockedAppsList => filteredApps.where((app) => dockedApps.contains(app.packageName) && !hiddenApps.contains(app.packageName)).toList();

strings get categories => apps.value?.selectMany((app, i) => getCategoriesOf(app.packageName)).orderBy((x) => x).map((x) => x.toTitleCase).distinct().toList() ?? [];

List<Contact> contacts = [];

List<Contact> get starredContacts => contacts.where((contact) => contact.isStarred).toList();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  SystemTheme.fallbackColor = "#f6373f".asColor;
  await SystemTheme.accentColor.load();
  mainColor = SystemTheme.accentColor.accent;
  if (await FlutterContacts.requestPermission()) {
    contacts = await FlutterContacts.getContacts(
      withProperties: true,
      withPhoto: true,
      withAccounts: true,
      withGroups: true,
      deduplicateProperties: true,
      sorted: true,
      withThumbnail: true,
    );
  }
  runApp(const MainApp());
}
