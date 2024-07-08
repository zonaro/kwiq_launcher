import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:system_theme/system_theme.dart';

import 'main_app.dart';

late GetStorage prefs;

int get gridColumns => prefs.read('gridColumns') ?? 4;
set gridColumns(int value) => prefs.write('gridColumns', value);

int get limitSearch => prefs.read('limitSearch') ?? 20;
set limitSearch(int value) => prefs.write('limitSearch', value);

Color get mainColor => prefs.read<string>('mainColor')?.asColor ?? SystemTheme.fallbackColor;
set mainColor(Color value) => prefs.write('mainColor', value.hexadecimal);

List<string> get recentSearches => (prefs.read<List<string>>('recentSearches') ?? []).where((x) => x.isNotEmpty && !x.flatEqualAny(hiddenApps) && !x.flatEqualAny(apps.value?.map((m) => m.appName) ?? [])).toList();
set recentSearches(List<String> value) => prefs.write('recentSearches', value.distinctFlat());

List<string> get hiddenApps => prefs.read<List<string>>('hiddenApps') ?? [];
set hiddenApps(List<String> value) => prefs.write('hiddenApps', value.distinctFlat());

List<string> get dockedApps => prefs.read<List<string>>('dockedApps') ?? [];
set dockedApps(List<String> value) => prefs.write('dockedApps', value.distinctFlat());

List<string> getCategoriesOf(string packageName) => <string>[...(prefs.read<strings>('categories::$packageName') ?? []), apps.value?.where((app) => app.packageName == packageName).firstOrNull?.category.name ?? ""].distinctFlat().orderBy((x) => x).map((x) => x.toTitleCase).toList();
setCategoriesOf(string packageName, strings categories) => prefs.write('categories::$packageName', categories);

final AwaiterData<List<Application>> apps = AwaiterData<List<Application>>();

Map<string, List<Application>> get filteredAppsByCategory => Map.fromEntries(categories.map((category) => MapEntry(category, filteredApps.where((app) => getCategoriesOf(app.packageName).contains(category)).toList())));
List<Application> get filteredApps => apps.value?.where((app) => !hiddenApps.contains(app.packageName)).orderBy((x) => x.appName).toList() ?? [];

List<Application> get dockedAppsList => filteredApps.where((app) => dockedApps.contains(app.packageName) && !hiddenApps.contains(app.packageName)).toList();

strings get categories => apps.value?.selectMany((app, i) => getCategoriesOf(app.packageName)).orderBy((x) => x).map((x) => x.toTitleCase).distinct().toList() ?? [];

List<Contact> contacts = [];

List<Contact> get starredContacts => contacts.where((contact) => contact.isStarred).toList();

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
  };
  return category.getUniqueWords.whereValid.map((x) => categoryIcons[x.toLowerCase()]).mostFrequent ?? Icons.category;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  prefs = GetStorage();
  SystemTheme.fallbackColor = "#f6373f".asColor;
  await SystemTheme.accentColor.load();
  mainColor = SystemTheme.accentColor.accent;

  await Permission.photos.request();
  await Permission.videos.request();
  await Permission.calendarFullAccess.request();
  await Permission.location.request();
  await Permission.manageExternalStorage.request();

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
