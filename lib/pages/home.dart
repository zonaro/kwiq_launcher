// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:innerlibs/image_provider_extensions.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/app_menu.dart';
import 'package:kwiq_launcher/components/app_tile.dart';
import 'package:kwiq_launcher/components/contact_tile.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/models/kwiq_config.dart';
import 'package:kwiq_launcher/pages/file_manager.dart';
import 'package:kwiq_launcher/pages/game_dashboard.dart';
import 'package:kwiq_launcher/pages/my_wallpapers.dart';
import 'package:kwiq_launcher/pages/settings.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:new_device_apps/device_apps.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FocusNode queryFocusNode = FocusNode();
  TextInputType inputType = TextInputType.text;
  final loc = Get.context!.innerLibsLocalizations;

  bool isSearching = false;

  Timer? _debounce;

  final TextEditingController queryController = TextEditingController();

  bool searchChanged = true;

  string query = "";

  Map<string, Function()> get commands => {
        "todo": () {
          var todo = getCommandArgs.join(" ").trimAll;
          var exist = kwiqConfig.todoList.firstWhereOrNull((x) => x.title.flatEqual(todo));
          if (exist != null) {
            if (exist.done) {
              kwiqConfig.removeTodo(exist);
            } else {
              exist.doneDate = now;
            }
          } else {
            kwiqConfig.addTodoString(todo);
          }
          Get.forceAppUpdate();
          queryController.clear();
        },
        "clearsearch": () {
          kwiqConfig.recentSearches = [];
        },
        "reload": () {
          loadApps();
          loadFiles();
          loadContacts();
          Get.forceAppUpdate();
        },
        "gosettings": () {
          Get.to(() => const SettingsScreen());
        },
        "gowallpaper": () {
          Get.to(() => const MyWallpapersScreen());
        },
        "setcolor": () {
          kwiqConfig.accentColor = getCommandArgs.map((x) => x.trimAll.asColor).reduce((a, b) => a + b);
          Get.forceAppUpdate();
        },
        "setdarktheme": () {
          kwiqConfig.themeMode = ThemeMode.dark;
          Get.changeThemeMode(kwiqConfig.themeMode);
          Get.forceAppUpdate();
        },
        "setsystemtheme": () {
          kwiqConfig.themeMode = ThemeMode.system;
          Get.changeThemeMode(kwiqConfig.themeMode);
          Get.forceAppUpdate();
        },
        "setlighttheme": () {
          kwiqConfig.themeMode = ThemeMode.light;
          Get.changeThemeMode(kwiqConfig.themeMode);
          Get.forceAppUpdate();
        },
      };

  string get dynamicTitle {
    if (query.startsWithAny(tokenList)) {
      return tokens[query.first()]!;
    }
    return loc.search;
  }

  string get getCommand {
    if (query.startsWith(">")) return query.removeFirstAny(tokenList).splitArguments.first;
    return "";
  }

  Iterable<string> get getCommandArgs {
    if (query.startsWith(">")) return query.removeFirstAny(tokenList).splitArguments.skip(1);
    return [];
  }

  bool get isEmptySearch => searchApps.isEmpty && searchContacts.isEmpty && searchFiles.isEmpty && searchCategories.isEmpty;

  Iterable<string> get parseMath {
    List<string> exps = query.removeFirstEqual("=").split(";");
    return exps.whereNotBlank.map((mathExp) {
      Parser p = Parser();
      try {
        return changeTo(p.parse(mathExp).evaluate(EvaluationType.REAL, ContextModel()));
      } catch (e) {
        consoleLog(e);
        return "Error: $e";
      }
    });
  }

  Iterable<AppInfo> get searchApps {
    try {
      if (apps.isEmpty) {
        loadApps();
      }

      return visibleApps
          .search(
            searchTerms: query.removeFirstEqual(":"),
            searchOn: (app) => [app.appName, app.packageName, ...kwiqConfig.getCategoriesOfApp(app)],
            levenshteinDistance: 2,
            allIfEmpty: true,
            keyCharSearches: {"#": (search, keyword, item) => kwiqConfig.getCategoriesOfApp(item).contains(search)},
            minChars: kwiqConfig.minChars,
            maxResults: kwiqConfig.maxResults,
          )
          .toList();
    } catch (e) {
      consoleLog('Error: $e');
      return [];
    }
  }

  Iterable<string> get searchCategories => categories
      .search(
        searchTerms: query.removeFirstEqual("#"),
        levenshteinDistance: 2,
        searchOn: (x) => [x],
      )
      .toList();

  Iterable<Contact> get searchContacts {
    try {
      if (contacts.isEmpty) {
        loadContacts();
      }

      return contacts
          .search(
            searchTerms: query.removeFirstEqual("@"),
            searchOn: (contact) => [
              contact.name.first,
              contact.name.last,
              contact.name.nickname,
              contact.displayName,
              ...contact.emails.map((e) => e.address),
              ...contact.phones.map((e) => e.number),
            ],
            levenshteinDistance: 2,
            minChars: kwiqConfig.minChars,
            maxResults: kwiqConfig.maxResults,
          )
          .toList();
    } catch (e) {
      consoleLog('Error: $e');
      return [];
    }
  }

  Iterable<File> get searchFiles {
    try {
      if (files.isEmpty) {
        loadFiles();
      }

      return files
          .search(
            searchTerms: query.removeFirstEqual("/"),
            searchOn: (file) => [
              file.name,
              file.lastModifiedSync().format(),
              file.lastAccessedSync().format(),
            ],
            levenshteinDistance: 2,
            minChars: kwiqConfig.minChars,
            maxResults: kwiqConfig.maxResults,
            useWildcards: query.containsAny(["*", "?"]),
          )
          .toList();
    } catch (e) {
      consoleLog('Error: $e');
      return [];
    }
  }

  void bingSearch() {
    kwiqConfig.addRecentSearch(query);
    launchUrl(Uri.http('www.bing.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);
  }

  @override
  build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        isSearching = !isSearching;
        setState(() {});
      },
      child: kwiqConfig.isGameDashboardEnabled
          ? const XboxScreen()
          : KeyboardListener(
              focusNode: FocusNode(),
              autofocus: true,
              onKeyEvent: (event) {
                if (event is KeyDownEvent) {
                  if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
                    isSearching = false;
                    context.unfocus();
                    setState(() {});
                    return;
                  } else if (event.isControl(LogicalKeyboardKey.keyF) || event.isKeyPressed(LogicalKeyboardKey.f2) || event.isMeta(LogicalKeyboardKey.space)) {
                    isSearching = !isSearching;
                    setState(() {});
                    if (isSearching) queryFocusNode.requestFocus();
                    return;
                  } else if (event.isControl(LogicalKeyboardKey.semicolon) || event.isControl(LogicalKeyboardKey.keyQ)) {
                    isSearching = true;
                    query = ":";
                    setState(() {});
                    queryFocusNode.requestFocus();
                    return;
                  } else if (event.isControl(LogicalKeyboardKey.at) || event.isControl(LogicalKeyboardKey.keyP)) {
                    isSearching = true;
                    query = "@";
                    setState(() {});
                    queryFocusNode.requestFocus();
                    return;
                  } else if (event.isControl(LogicalKeyboardKey.keyB) || event.isKeyPressed(LogicalKeyboardKey.launchWebBrowser) || event.isKeyPressed(LogicalKeyboardKey.browserSearch)) {
                    isSearching = true;
                    query = "http://";
                    queryFocusNode.requestFocus();
                    setState(() {});
                    return;
                  } else if (event.isControl(LogicalKeyboardKey.add) || event.isControl(LogicalKeyboardKey.keyM)) {
                    isSearching = true;
                    query = "=";
                    queryFocusNode.requestFocus();
                    setState(() {});
                    return;
                  } else if (event.isKeyPressed(LogicalKeyboardKey.f12)) {
                    Get.to(() => const SettingsScreen());
                    setState(() {});
                    return;
                  } else if (event.isControl(LogicalKeyboardKey.keyG)) {
                    isSearching = true;
                    query = "#";
                    setState(() {});
                    return;
                  } else if (event.isControlAlt(LogicalKeyboardKey.keyF)) {
                    isSearching = true;
                    query = "/"; // Files
                    setState(() {});
                    return;
                  }
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (kwiqConfig.currentWallpapers.isNotEmpty)
                    AnimatedImageList(
                      images: kwiqConfig.currentWallpapers.map((x) => x.image).toList(),
                      fade: kwiqConfig.wallpaperFadeDuration.milliseconds,
                      duration: kwiqConfig.wallpaperInterval.seconds,
                      onChange: (p0) {
                        if (kwiqConfig.themeFollowWallpaper) {
                          p0.colorScheme(brightness: Get.theme.brightness).then((scheme) {
                            kwiqConfig.currentColor = scheme.primary;
                            setState(() {});
                            Get.forceAppUpdate();
                          });
                        }
                      },
                    ),
                  if (isSearching)
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                      child: Container(
                        color: context.primaryColor.withOpacity((kwiqConfig.overlayOpacity + .2).clampMax(1)),
                      ),
                    )
                  else
                    Container(
                      color: context.surfaceColor.withOpacity(kwiqConfig.overlayOpacity),
                    ),
                  SafeArea(
                    child: Scaffold(
                      backgroundColor: Colors.transparent,
                      appBar: AppBar(
                        toolbarHeight: isSearching ? 70 : null,
                        backgroundColor: Colors.transparent,
                        title: isSearching
                            ? TextFormField(
                                key: ValueKey(inputType.hashCode),
                                autofocus: true,
                                focusNode: queryFocusNode,
                                controller: queryController,
                                onFieldSubmitted: (s) {
                                  submitQuery(s);

                                  if (s.isBlank) {
                                    queryController.text = kwiqConfig.recentSearches.lastOrNull ?? "";
                                    if (s.isBlank) {
                                      isSearching = false;
                                      context.unfocus();
                                      setState(() {});
                                    }
                                    return;
                                  }

                                  if (query.isPhoneNumber) {
                                    callNumber();
                                    return;
                                  }
                                  if (query.isURL) {
                                    openUrl();
                                    return;
                                  }
                                  if (getCommand.isNotBlank) {
                                    var f = commands[getCommand];
                                    if (f != null) {
                                      f();
                                      context.unfocus();
                                      query = "";
                                      isSearching = false;
                                    }
                                    return;
                                  }
                                  if (apps.any((a) => a.packageName.flatEqual(query))) {
                                    DeviceApps.openApp(query);
                                    return;
                                  }

                                  if (queryIsSingleApplication(query)) {
                                    DeviceApps.openApp(searchApps.first.packageName);
                                    return;
                                  }
                                  if (queryIsSingleContact(query)) {
                                    FlutterContacts.openExternalView(searchContacts.first.id);
                                    return;
                                  }
                                  if (query.startsWith("=")) {
                                    query = "=${parseMath.first}";
                                    setState(() {});
                                    return;
                                  }
                                  if (searchChanged == false) {
                                    googleSearch();
                                  } else {
                                    searchChanged = false;
                                  }
                                  setState(() {});
                                },
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  label: dynamicTitle.asText(),
                                  hintStyle: TextStyle(color: context.colorScheme.onSurface.withOpacity(.5)),
                                  hintText: kwiqConfig.recentSearches.lastOrNull ?? '${loc.search}...',
                                ),
                                keyboardType: inputType,
                                textInputAction: TextInputAction.search,
                              )
                            : DigitalClock(
                                format: kwiqConfig.dateTimeFormat.nullIfBlank,
                                locale: Get.locale?.languageCode,
                                alignment: Alignment.centerLeft,
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                )),
                        actions: [
                          if (!isSearching) ...[
                            IconButton(
                              onPressed: () {
                                kwiqConfig.enableGameDashboard = !kwiqConfig.enableGameDashboard;
                                setState(() {});
                              },
                              icon: Icon(Icons.videogame_asset, color: kwiqConfig.enableGameDashboard ? kwiqConfig.currentColor : null),
                            ),
                            IconButton(onPressed: () => Get.to(() => const FilePage()), icon: const Icon(Icons.folder)),
                            IconButton(
                              icon: const Icon(Icons.settings),
                              onPressed: () => Get.to(() => const SettingsScreen()),
                            ),
                          ]
                        ],
                      ),
                      floatingActionButtonLocation: dockedApps.isNotEmpty && !isSearching ? FloatingActionButtonLocation.endDocked : FloatingActionButtonLocation.endFloat,
                      bottomNavigationBar: dockedApps.isNotEmpty && !isSearching
                          ? SizedBox(
                              height: 70,
                              child: ListView(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                children: [
                                  for (var app in dockedApps)
                                    GestureDetector(
                                      onTap: () => DeviceApps.openApp(app.packageName),
                                      onLongPress: () => Get.to(() => MyAppMenuScreen(packageName: app.packageName)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Image.memory(
                                          app.icon,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    ),
                                  const Gap(100)
                                ],
                              ),
                            )
                          : null,
                      resizeToAvoidBottomInset: true,
                      floatingActionButton: SizedBox(
                        width: context.width,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            if (isSearching)
                              FloatingActionButton.small(
                                child: Icon((inputType == TextInputType.number ? Icons.numbers : Icons.abc)),
                                onPressed: () async {
                                  // Toggle between full keyboard and numeric keyboard
                                  if (inputType == TextInputType.text) {
                                    inputType = TextInputType.number;
                                  } else {
                                    inputType = TextInputType.text;
                                  }
                                  context.unfocus();
                                  await Get.forceAppUpdate();
                                  setState(() {});
                                  queryFocusNode.requestFocus();
                                },
                              ),
                            const Gap(10),
                            FloatingActionButton(
                              onPressed: () {
                                if (!isSearching) {
                                  isSearching = true;
                                  submitQuery("");
                                  queryFocusNode.requestFocus();
                                  Get.forceAppUpdate();
                                  return;
                                }

                                if (query.isBlank) {
                                  context.unfocus();
                                  isSearching = false;
                                  setState(() {});
                                  Get.forceAppUpdate();
                                  return;
                                }

                                if (query.startsWithAny(tokenList)) {
                                  query = query.flatEqualAny(tokenList) ? "" : query.first();
                                } else {
                                  query = "";
                                }
                                submitQuery(query);
                                queryFocusNode.requestFocus();
                              },
                              child: Icon(isSearching ? (query.isNotBlank ? Icons.clear_all : Icons.close) : Icons.search),
                            ),
                          ],
                        ),
                      ),
                      body: !isSearching
                          ? PageView(
                              children: [
                                ResponsiveRow.withColumns(
                                  xxs: kwiqConfig.gridColumns.toDouble(),
                                  children: [
                                    for (var contact in starredContacts)
                                      ContactTile(
                                        contact: contact,
                                        gridColumns: kwiqConfig.gridColumns,
                                      ),
                                    for (var app in favoriteApps)
                                      AppTile(
                                        app: app,
                                        gridColumns: kwiqConfig.gridColumns,
                                      ),
                                    for (var todo in kwiqConfig.todoList)
                                      ResponsiveColumn.full(
                                        child: CheckboxListTile(
                                            title: todo.title.asText(),
                                            subtitle: todo.description.asText(),
                                            value: todo.done,
                                            onChanged: (b) {
                                              todo.toggle();
                                              setState(() {});
                                              Get.forceAppUpdate();
                                            }).onLongPress(() {
                                          kwiqConfig.removeTodo(todo);
                                          setState(() {});
                                          Get.forceAppUpdate();
                                        })!,
                                      ),
                                    for (var search in kwiqConfig.recentSearches)
                                      ResponsiveColumn.full(
                                        child: ListTile(
                                          title: Text(search),
                                          leading: const Icon(Icons.search),
                                          trailing: IconButton(
                                            icon: const Icon(Icons.delete_forever),
                                            onPressed: () {
                                              kwiqConfig.removeSearch(search);
                                              setState(() {});
                                              Get.forceAppUpdate();
                                            },
                                          ),
                                          onTap: () {
                                            isSearching = true;

                                            submitQuery(search);
                                            queryFocusNode.requestFocus();
                                          },
                                        ),
                                      ),
                                    Gap(context.height * .12),
                                  ],
                                ),
                                for (var cat in categories)
                                  Stack(
                                    fit: StackFit.expand,
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(15),
                                        child: FittedBox(
                                            child: Column(
                                          children: [
                                            Icon(
                                              categoryIcon(cat),
                                              size: context.width,
                                              color: context.primaryColor,
                                            ),
                                            const Gap(10),
                                            Text(cat).bold().fontSize(context.width).textColor(context.primaryColor),
                                          ],
                                        )),
                                      ).setOpacity(opacity: kwiqConfig.overlayOpacity - .2),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: kwiqConfig.currentColor.withOpacity((kwiqConfig.overlayOpacity + .1).clamp(0, 1)),
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              kwiqConfig.currentColor.withOpacity((kwiqConfig.overlayOpacity + .5).clamp(0, 1)),
                                            ],
                                          ),
                                        ),
                                        child: ResponsiveRow.withColumns(
                                          xxs: kwiqConfig.gridColumns.toDouble(),
                                          children: [
                                            ResponsiveColumn.full(
                                              child: ListTile(title: Text(cat).bold().fontSize(20)),
                                              alignment: Alignment.center,
                                            ),
                                            for (ApplicationWithIcon app in visibleAppsByCategory[cat] ?? [])
                                              AppTile(
                                                app: app,
                                                gridColumns: kwiqConfig.gridColumns,
                                              ),
                                            Gap(context.height * .12),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            )
                          : ListView(
                              shrinkWrap: true,
                              children: [
                                for (var suggestion in kwiqConfig.recentSearches.search(
                                  searchTerms: query,
                                  searchOn: (x) => [x],
                                  levenshteinDistance: 2,
                                  allIfEmpty: true,
                                ))
                                  ListTile(
                                    title: Text(suggestion),
                                    onTap: () {
                                      query = suggestion;
                                      setState(() {});
                                    },
                                  ),
                                const Divider(),
                                if (query.startsWith("="))
                                  for (var result in parseMath)
                                    ListTile(
                                      title: Text(result).fontSize(35).bold(),
                                      leading: const Icon(Icons.calculate),
                                      onTap: () {
                                        submitQuery(result);
                                      },
                                    ),
                                if (apps.any((a) => a.packageName.flatEqual(query)))
                                  AppTile(
                                    app: apps.firstWhere((a) => a.packageName.flatEqual(query)),
                                    gridColumns: 1,
                                  ),
                                if (query.isNotBlank && !query.startsWithAny(tokenList) && !isEmptySearch)
                                  ResponsiveRow.withColumns(alignment: WrapAlignment.center, xxs: 8, children: [
                                    if (query.isPhoneNumber)
                                      IconButton(
                                        icon: const Icon(Icons.phone, size: 20),
                                        tooltip: loc.calltoItem(query.quote),
                                        onPressed: callNumber,
                                      ),
                                    if (query.isPhoneNumber)
                                      IconButton(
                                        icon: const Icon(Icons.message, size: 20),
                                        tooltip: loc.sendItemToItem("SMS", query.quote),
                                        onPressed: smsTo,
                                      ),
                                    if (query.isPhoneNumber && hasWhatsapp)
                                      IconButton(
                                        icon: Brand(Brands.whatsapp, size: 20),
                                        tooltip: loc.sendItemToItem("WhatsApp", query.quote),
                                        onPressed: whatsAppTo,
                                      ),
                                    if (query.isURL)
                                      IconButton(
                                        icon: const Icon(Icons.link, size: 20),
                                        tooltip: loc.openItem(query.quote),
                                        onPressed: openUrl,
                                      ),
                                    if (query.isEmail)
                                      IconButton(
                                        icon: const Icon(Icons.email, size: 20),
                                        tooltip: loc.newItemToItem("email", query.quote),
                                        onPressed: openMail,
                                      ),
                                    IconButton(
                                      icon: Brand(Brands.google, size: 20),
                                      tooltip: loc.searchForIn(query.quote, "Google"),
                                      onPressed: googleSearch,
                                    ),
                                    IconButton(
                                      icon: Brand(Brands.bing, size: 20),
                                      tooltip: loc.searchForIn(query.quote, "Bing"),
                                      onPressed: bingSearch,
                                    ),
                                    IconButton(
                                      icon: Brand(Brands.youtube, size: 20),
                                      tooltip: loc.searchForIn(query.quote, "YouTube"),
                                      onPressed: youtubeSearch,
                                    ),
                                    IconButton(
                                      icon: Brand(Brands.youtube_music, size: 20),
                                      tooltip: loc.searchForIn(query.quote, "YouTube Music"),
                                      onPressed: youtubeMusicSearch,
                                    ),
                                    if (hasSpotify)
                                      IconButton(
                                        icon: Brand(Brands.spotify, size: 20),
                                        tooltip: loc.searchForIn(query.quote, "Spotify"),
                                        onPressed: spotifySearch,
                                      ),
                                    IconButton(
                                      icon: Brand(Brands.google_play, size: 20),
                                      tooltip: loc.searchForIn(query.quote, "Play Store"),
                                      onPressed: playStoreSearch,
                                    ),
                                    IconButton(
                                      icon: Brand(Brands.google_maps, size: 20),
                                      tooltip: loc.searchForIn(query.quote, "Google Maps"),
                                      onPressed: mapSearch,
                                    ),
                                    IconButton(
                                      icon: Brand(Brands.instagram, size: 20),
                                      tooltip: loc.openItem("instagram/${query.toSnakeCase}"),
                                      onPressed: instagramOpen,
                                    ),
                                  ]),
                                if (query.isNotBlank && !query.startsWithAny(tokenList) && isEmptySearch) ...[
                                  if (query.isPhoneNumber)
                                    ListTile(
                                      leading: const Icon(Icons.phone),
                                      title: Text(loc.calltoItem(query.quote)),
                                      onTap: callNumber,
                                      dense: true,
                                    ),
                                  if (query.isPhoneNumber)
                                    ListTile(
                                      leading: const Icon(Icons.message),
                                      title: Text(loc.sendItemToItem("SMS", query.quote)),
                                      onTap: smsTo,
                                      dense: true,
                                    ),
                                  if (query.isPhoneNumber && hasWhatsapp)
                                    ListTile(
                                      leading: Brand(Brands.whatsapp),
                                      title: Text(loc.sendItemToItem("WhatsApp", query.quote)),
                                      onTap: whatsAppTo,
                                      dense: true,
                                    ),
                                  if (query.isURL)
                                    ListTile(
                                      leading: const Icon(Icons.link),
                                      title: Text('${loc.open} URL "$query"'),
                                      onTap: openUrl,
                                      dense: true,
                                    ),
                                  if (query.isEmail)
                                    ListTile(
                                      leading: const Icon(Icons.email),
                                      title: Text('${loc.newItem("email")} ${loc.to} "$query"'),
                                      onTap: openMail,
                                      dense: true,
                                    ),
                                  ListTile(
                                    leading: Brand(Brands.google),
                                    title: Text(loc.searchForIn(query.quote, "Google")),
                                    onTap: googleSearch,
                                    dense: true,
                                  ),
                                  ListTile(
                                    leading: Brand(Brands.bing),
                                    title: Text(loc.searchForIn(query.quote, "Bing")),
                                    onTap: bingSearch,
                                    dense: true,
                                  ),
                                  ListTile(
                                    leading: Brand(Brands.youtube),
                                    title: Text(loc.searchForIn(query.quote, "YouTube")),
                                    onTap: youtubeSearch,
                                    dense: true,
                                  ),
                                  ListTile(
                                    leading: Brand(Brands.youtube_music),
                                    title: Text(loc.searchForIn(query.quote, "YouTube Music")),
                                    onTap: youtubeMusicSearch,
                                    dense: true,
                                  ),
                                  if (hasSpotify)
                                    ListTile(
                                      leading: Brand(Brands.spotify),
                                      title: Text(loc.searchForIn(query.quote, "Spotify")),
                                      onTap: spotifySearch,
                                      dense: true,
                                    ),
                                  ListTile(
                                    leading: Brand(Brands.google_play),
                                    title: Text(loc.searchForIn(query.quote, "Play Store")),
                                    onTap: playStoreSearch,
                                    dense: true,
                                  ),
                                  ListTile(
                                    leading: Brand(Brands.google_maps),
                                    title: Text(loc.searchForIn(query.quote, "Google Maps")),
                                    onTap: mapSearch,
                                    dense: true,
                                  ),
                                  ListTile(
                                    leading: Brand(Brands.instagram),
                                    title: Text('${loc.open} "instagram/${query.toSnakeCase}"'),
                                    onTap: instagramOpen,
                                    dense: true,
                                  ),
                                  const Divider(),
                                ],
                                if (query.startsWith(">"))
                                  for (var command in commands.keys.search(
                                    searchTerms: query,
                                    searchOn: (x) => [x],
                                    levenshteinDistance: 2,
                                  ))
                                    ListTile(
                                      leading: const Icon(Icons.terminal),
                                      title: Text(command),
                                      onTap: () {
                                        query = ">$command ";
                                        setState(() {});
                                      },
                                    ),
                                if (query.toLowerCase().startsWith(">setcolor"))
                                  for (var color in NamedColors.values.orderBy((x) => x.name).search(searchTerms: query.split(" ").skip(1), searchOn: (x) => [x.name, x.hexadecimal], levenshteinDistance: 3))
                                    ListTile(
                                      leading: Icon(Icons.color_lens, color: color),
                                      title: Text(color.name),
                                      onTap: () {
                                        kwiqConfig.accentColor = color;
                                        setState(() {});

                                        //select only the color name in the controller
                                        queryController.text = ">setcolor ${color.name}";
                                        queryController.selection = TextSelection(baseOffset: query.indexOf(color.name), extentOffset: query.indexOf(color.name) + color.name.length);
                                        kwiqConfig.themeFollowWallpaper = false;
                                        Get.forceAppUpdate();
                                      },
                                    ),
                                if (query.startsWith(":") || !query.startsWithAny(tokenList))
                                  for (var app in searchApps)
                                    AppTile(
                                      app: app,
                                      gridColumns: 1,
                                    ),
                                if (query.startsWith("#"))
                                  for (var cat in searchCategories)
                                    ListTile(
                                      leading: Icon(categoryIcon(cat)),
                                      title: Text(cat),
                                      onTap: () {
                                        query = ":#$cat";
                                        setState(() {});
                                        context.unfocus();
                                      },
                                    ),
                                if (query.startsWith("@") || !query.startsWithAny(tokenList))
                                  for (var contact in searchContacts)
                                    ContactTile(
                                      contact: contact,
                                      gridColumns: 1,
                                    ),
                                if (query.startsWith("/") || !query.startsWithAny(tokenList))
                                  for (var file in searchFiles)
                                    ListTile(
                                      title: Text(file.name | file.fileNameWithoutExtension | file.path),
                                      leading: Icon(file.icon),
                                      onTap: () => OpenFile.open(file.path),
                                      onLongPress: () {
                                        Get.bottomSheet(
                                          backgroundColor: context.colorScheme.surface,
                                          Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                title: Text(loc.open),
                                                leading: const Icon(Icons.open_in_browser),
                                                onTap: () => OpenFile.open(file.path),
                                              ),
                                              ListTile(
                                                  title: Text(loc.share),
                                                  leading: const Icon(Icons.share),
                                                  onTap: () {
                                                    Share.shareXFiles([XFile(file.path)]);
                                                  }),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                Gap(context.height * .12)
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void callNumber() async => await FlutterPhoneDirectCaller.callNumber(query);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void googleSearch() {
    kwiqConfig.addRecentSearch(query);
    launchUrl(Uri.http('www.google.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);
  }

  @override
  void initState() {
    super.initState();

    queryController.addListener(() {
      searchChanged = true;
      if (kwiqConfig.debounceTime <= 0) {
        submitQuery(queryController.text);
      } else {
        _debounce = Timer(kwiqConfig.debounceTime.milliseconds, () {
          submitQuery(queryController.text);
        });
      }
    });
  }

  void instagramOpen() {
    kwiqConfig.addRecentSearch(query);
    launchUrl(Uri.http('instagram.com', '/${query.toSnakeCase}'), mode: LaunchMode.externalApplication);
  }

  void mapSearch() {
    kwiqConfig.addRecentSearch(query);
    launchUrl(
        Uri.https(
          'www.google.com',
          '/maps/search/$query',
        ),
        mode: LaunchMode.externalApplication);
  }

  void openMail() => launchUrlString('mailto:$query', mode: LaunchMode.externalApplication);

  void openUrl() {
    if (!query.startsWith("http")) {
      query = 'http://$query';
    }
    kwiqConfig.addRecentSearch(query);
    launchUrlString(query, mode: LaunchMode.externalApplication);
  }

  void playStoreSearch() {
    kwiqConfig.addRecentSearch(query);
    launchUrl(Uri.http('play.google.com', '/store/search', {'q': query}), mode: LaunchMode.externalApplication);
  }

  bool queryIsSingleApplication(string query) {
    return searchApps.length == 1 && query.isNotBlank && (query.startsWith(":") || (searchContacts.isEmpty && searchFiles.isEmpty && searchCategories.isEmpty));
  }

  bool queryIsSingleContact(string query) {
    return searchContacts.length == 1 && query.isNotBlank && (query.startsWith("@") || (searchApps.isEmpty && searchFiles.isEmpty && searchCategories.isEmpty));
  }

  Future<Iterable<string>> searchSuggestions() async {
    return [...kwiqConfig.recentSearches, ...(await query.fetchGoogleSuggestions(language: Get.locale?.languageCode ?? ""))].distinctFlat();
  }

  void smsTo() => launchUrlString('sms:$query');

  void spotifySearch() {
    kwiqConfig.addRecentSearch(query);
    launchUrl(Uri.https('open.spotify.com', '/search/$query'), mode: LaunchMode.externalApplication);
  }

  void submitQuery(string q) {
    _debounce?.isActive ?? false ? _debounce?.cancel() : null;
    setState(() {
      query = q;
      queryController.text = query;
    });
    Get.forceAppUpdate();
  }

  void whatsAppTo() => launchUrlString('whatsapp://send?phone=$query');

  void youtubeMusicSearch() {
    kwiqConfig.addRecentSearch(query);
    launchUrl(Uri.http('music.youtube.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);
  }

  void youtubeSearch() {
    kwiqConfig.addRecentSearch(query);
    launchUrl(Uri.http('www.youtube.com', '/results', {'search_query': query}), mode: LaunchMode.externalApplication);
  }
}
