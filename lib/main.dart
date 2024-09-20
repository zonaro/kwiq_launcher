import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:system_theme/system_theme.dart';

import 'main_app.dart';

const tokens = [':', '@', '#', '>'];

late SharedPreferences prefs;

int get gridColumns => prefs.getInt('gridColumns') ?? 4;
set gridColumns(int value) => prefs.setInt('gridColumns', value);

Color get mainColor => prefs.getString('mainColor')?.asColor ?? SystemTheme.fallbackColor;
set mainColor(Color value) => prefs.setString('mainColor', value.hexadecimal);

List<string> get recentSearches => prefs.getStringList('recentSearches')?.map((s) => s.toString()).where((x) => x.isNotEmpty && x.isNotIn(tokens) && !x.flatEqualAny(hiddenApps) && !x.flatEqualAny(apps.map((m) => m.name))).toList() ?? [];
set recentSearches(List<String> value) => prefs.setStringList('recentSearches', value.distinctFlat().toList());

List<string> get hiddenApps => prefs.getStringList('hiddenApps') ?? [];
set hiddenApps(List<String> value) => prefs.setStringList('hiddenApps', value.distinctFlat().toList());

List<string> get dockedApps => prefs.getStringList('dockedApps') ?? [];
set dockedApps(List<string> value) => prefs.setStringList('dockedApps', value.distinctFlat().toList());

Iterable<AppInfo> get homeApps => apps.where((app) => dockedApps.flatContains(app.packageName)).orderBy((x) => x.name);

List<string> getCategoriesOf(string packageName) => <string>[
      ...([...(prefs.getStringList('categories::$packageName') ?? [])]),
    ].distinctFlat().orderBy((x) => x).map((x) => x.toTitleCase).toList();
setCategoriesOf(string packageName, StringList categories) => prefs.setStringList('categories::$packageName', categories.distinctFlat().toList());
addCategory(string packageName, string category) => setCategoriesOf(packageName, getCategoriesOf(packageName) + [category]);
removeCategory(string packageName, string category) => setCategoriesOf(packageName, getCategoriesOf(packageName).where((e) => e.flatEqual(category) == false).toList());

List<AppInfo> apps = [];

Map<string, List<AppInfo>> get filteredAppsByCategory => Map.fromEntries(categories.map((category) => MapEntry(category, filteredApps.where((app) => getCategoriesOf(app.packageName).contains(category)).toList())));
List<AppInfo> get filteredApps => apps.where((app) => !hiddenApps.contains(app.packageName)).orderBy((x) => x.name).toList();

StringList get categories => apps.selectMany((app, i) => getCategoriesOf(app.packageName)).orderBy((x) => x).map((x) => x.toTitleCase).distinct().toList();

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
  apps = (await InstalledApps.getInstalledApps(false, true));
  return apps;
}

IconData categoryIcon(String category) {
  final Map<String, IconData> categoryIcons = {
    "audio": Icons.audiotrack,
    "books": Icons.book,
    "book": Icons.book,
    "business": Icons.business,
    "communication": Icons.chat,
    "message": Icons.chat,
    "messages": Icons.chat,
    "education": Icons.school,
    "entertainment": Icons.movie,
    "finance": Icons.monetization_on,
    "food": Icons.fastfood,
    "drink": Icons.fastfood,
    "games": Icons.games,
    "game": Icons.games,
    "health": Icons.fitness_center,
    "fitness": Icons.fitness_center,
    "house": Icons.home,
    "home": Icons.home,
    "images": Icons.image,
    "image": Icons.image,
    "picture": Icons.image,
    "pictures": Icons.image,
    "lifestyle": Icons.favorite,
    "navigation": Icons.map,
    "medical": Icons.local_hospital,
    "music": Icons.music_note,
    "magazines": Icons.article,
    "news": Icons.article,
    "personalization": Icons.palette,
    "photography": Icons.camera,
    "productivity": Icons.work,
    "shopping": Icons.shopping_cart,
    "social": Icons.people,
    "sports": Icons.sports,
    "tools": Icons.build,
    "travel": Icons.airplanemode_active,
    "video": Icons.video_library,
    "weather": Icons.wb_sunny,
    "map": Icons.map,
    "local": Icons.map,
    "maps": Icons.map,
    "work": Icons.work,
    "utilities": Icons.settings,
  };
  return category.getUniqueWords.whereValid.map((x) => categoryIcons[x.toLowerCase()]).mostFrequent ?? Icons.category;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  prefs = await SharedPreferences.getInstance();
  SystemTheme.fallbackColor = "#f6373f".asColor;

  await loadApps();
  await loadContacts();

  runApp(const MainApp());
}
