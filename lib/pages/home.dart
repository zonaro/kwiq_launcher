import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/app_tile.dart';
import 'package:kwiq_launcher/components/contact_tile.dart';
import 'package:kwiq_launcher/components/digital_clock.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/file_manager.dart';
import 'package:kwiq_launcher/pages/game_dashboard.dart';
import 'package:kwiq_launcher/pages/settings.dart';
import 'package:kwiq_launcher/pages/wallpaper.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:new_device_apps/device_apps.dart';
import 'package:open_file/open_file.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController queryController = TextEditingController();
  FocusNode queryFocusNode = FocusNode();
  TextInputType inputType = TextInputType.text;
  final loc = Get.context!.innerLibsLocalizations;

  bool isSearching = false;

  Map<string, Function()> get commands => {
        "todo": () {
          //add todo to recent searches
          var todo = getCommandArgs.join(" ");
          if (todoList.contains(todo)) {
            addTodo(todo);
          }
          removeTodo(todo);
        },
        "clearsearch": () {
          recentSearches = [];
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
          Get.to(() => const WallpaperApp());
        },
        "setcolor": () {
          mainColor = getCommandArgs.map((x) => x.asColor).reduce((a, b) => a + b);
          Get.forceAppUpdate();
        },
        "setdarktheme": () {
          themeMode = ThemeMode.dark;
          Get.changeThemeMode(themeMode);
          Get.forceAppUpdate();
        },
        "setsystemtheme": () {
          themeMode = ThemeMode.system;

          Get.changeThemeMode(themeMode);

          Get.forceAppUpdate();
        },
        "setlighttheme": () {
          themeMode = ThemeMode.light;
          Get.changeThemeMode(themeMode);
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

  Iterable<string> get parseMath {
    var mathExp = query.removeFirstEqual("=");
    try {
      Parser p = Parser();
      // Parse an expression
      Expression exp = p.parse(mathExp);
      // Bind variables (if any)
      ContextModel cm = ContextModel();
      // Evaluate the expression
      string result = changeTo(exp.evaluate(EvaluationType.REAL, cm));
      return [result];
    } catch (e) {
      consoleLog(e);
      return [];
    }
  }

  string get query => queryController.text;

  set query(string value) => queryController.text = value;

  Iterable<AppInfo> get searchApps {
    try {
      if (apps.isEmpty) {
        loadApps();
      }

      return visibleApps
          .search(
            searchTerms: query.removeFirstEqual(":"),
            searchOn: (app) => [app.appName, app.packageName, ...getCategoriesOf(app)],
            levenshteinDistance: 2,
            allIfEmpty: true,
          )
          .toList();
    } catch (e) {
      consoleLog('Error: $e');
      return [];
    }
  }

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
          )
          .toList();
    } catch (e) {
      consoleLog('Error: $e');
      return [];
    }
  }

  bool get showAutocomplete => prefs.getBool("showAutocomplete") ?? false;

  set showAutocomplete(bool value) => prefs.setBool("showAutocomplete", value);

  void bingSearch() {
    addRecentSearch(query);
    launchUrl(Uri.http('www.bing.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);
  }

  @override
  build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, or) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          isSearching = !isSearching;
          setState(() {});
        },
        child: or == Orientation.landscape
            ? const XboxScreen()
            : Scaffold(
                appBar: AppBar(
                  toolbarHeight: isSearching ? 70 : null,
                  title: isSearching
                      ? Autocomplete<string>(
                          initialValue: queryController.value,
                          onSelected: (value) {
                            query = value;
                            setState(() {});
                            context.unfocus();
                          },
                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                            queryController = controller;
                            queryFocusNode = focusNode;
                            return TextFormField(
                              key: ValueKey(inputType),
                              autofocus: true,
                              focusNode: focusNode,
                              controller: controller,
                              onFieldSubmitted: (s) {
                                onFieldSubmitted();
                                if (s.isBlank) {
                                  context.unfocus();
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

                                googleSearch();
                              },
                              onChanged: (value) {
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(),
                                label: dynamicTitle.asText(),
                                hintStyle: TextStyle(color: context.colorScheme.onSurface.makeDarker(.8)),
                                hintText: recentSearches.lastOrNull ?? '${loc.search}...',
                                suffixIcon: IconButton(
                                  icon: const Icon(
                                    Icons.auto_awesome,
                                  ).setOpacity(opacity: showAutocomplete ? 1 : .3),
                                  onPressed: () {
                                    setState(() {
                                      showAutocomplete = !showAutocomplete;
                                    });
                                    context.unfocus();
                                    focusNode.requestFocus();
                                  },
                                ),
                              ),
                              keyboardType: inputType,
                              textInputAction: TextInputAction.search,
                            );
                          },
                          optionsBuilder: (TextEditingValue textEditingValue) => showAutocomplete ? searchSuggestions() : [],
                        )
                      : const DigitalClock(),
                  actions: [
                    if (!isSearching) ...[
                      IconButton(onPressed: () => Get.to(() => const FilePage()), icon: const Icon(Icons.folder)),
                      IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: () => Get.to(() => const SettingsScreen()),
                      ),
                    ]
                  ],
                ),
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
                          if (isSearching) {
                            if (query.isNotBlank) {
                              if (query.startsWithAny(tokenList)) {
                                if (query.flatEqualAny(tokenList)) {
                                  query = "";
                                } else {
                                  query = query.first();
                                }
                              } else {
                                query = "";
                              }
                              queryFocusNode.requestFocus();
                            } else {
                              context.unfocus();
                              isSearching = false;
                            }
                          } else {
                            isSearching = true;
                            queryFocusNode.requestFocus();
                          }
                          setState(() {});
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
                            xxs: gridColumns.toDouble(),
                            children: [
                              for (var contact in starredContacts)
                                ContactTile(
                                  contact: contact,
                                  gridColumns: gridColumns,
                                ),
                              for (var app in homeApps)
                                AppTile(
                                  app: app,
                                  gridColumns: gridColumns,
                                ),
                              for (var todo in todoList)
                                ResponsiveColumn.full(
                                  child: CheckboxListTile(
                                      title: Text(todo.removeFirstAny(["[x]", "[ ]"])),
                                      value: todo.startsWith("[x]"),
                                      onChanged: (b) {
                                        setTodo(todo, b);
                                        setState(() {});
                                        Get.forceAppUpdate();
                                      }).onLongPress(() {
                                    removeTodo(todo);
                                    setState(() {});
                                    Get.forceAppUpdate();
                                  })!,
                                ),
                              for (var search in recentSearches)
                                ResponsiveColumn.full(
                                  child: ListTile(
                                    title: Text(search),
                                    leading: const Icon(Icons.search),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_forever),
                                      onPressed: () {
                                        recentSearches = recentSearches.where((x) => x != search).toList();
                                        setState(() {});
                                        Get.forceAppUpdate();
                                      },
                                    ),
                                    onTap: () {
                                      isSearching = true;
                                      query = search;
                                      setState(() {});
                                      Get.forceAppUpdate();
                                    },
                                  ),
                                ),
                              Gap(context.height * .12),
                            ],
                          ),
                          for (var cat in categories)
                            Stack(
                              fit: StackFit.expand,
                              children: [
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(15),
                                    child: FittedBox(
                                        child: Column(
                                      children: [
                                        Icon(categoryIcon(cat), size: context.width),
                                        const Gap(10),
                                        Text(cat).bold().fontSize(context.width),
                                      ],
                                    )),
                                  ),
                                ).setOpacity(opacity: .01),
                                Container(
                                  color: mainColor.withOpacity(.03),
                                  child: ResponsiveRow.withColumns(
                                    xxs: gridColumns.toDouble(),
                                    children: [
                                      ResponsiveColumn.full(
                                        child: ListTile(title: Text(cat).bold().fontSize(20)),
                                        alignment: Alignment.center,
                                      ),
                                      for (ApplicationWithIcon app in visibleAppsByCategory[cat] ?? [])
                                        AppTile(
                                          app: app,
                                          gridColumns: gridColumns,
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
                              if (query.startsWith("="))
                                for (var result in parseMath)
                                  ListTile(
                                    title: Text(result).fontSize(35).bold(),
                                    leading: const Icon(Icons.calculate),
                                    onTap: () {
                                      query = result;
                                      setState(() {});
                                    },
                                  ),
                              if (apps.any((a) => a.packageName.flatEqual(query)))
                                AppTile(
                                  app: apps.firstWhere((a) => a.packageName.flatEqual(query)),
                                  gridColumns: 1,
                                ),
                              if (query.isNotBlank && !query.startsWithAny(tokenList)) ...[
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
                                for (var command in commands.keys.search(searchTerms: query, searchOn: (x) => [x], levenshteinDistance: 2))
                                  ListTile(
                                    leading: const Icon(Icons.terminal),
                                    title: Text(command),
                                    onTap: () {
                                      query = ">$command ";
                                      setState(() {});
                                    },
                                  ),
                              if (query.startsWith(":") || !query.startsWithAny(tokenList))
                                for (var app in searchApps)
                                  AppTile(
                                    app: app,
                                    gridColumns: 1,
                                  ),
                              if (query.startsWith("#"))
                                for (var cat in categories)
                                  ListTile(
                                    leading: Icon(categoryIcon(cat)),
                                    title: Text(cat),
                                    onTap: () {
                                      query = cat;
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
                                    leading: const Icon(Icons.file_copy),
                                    onTap: () => OpenFile.open(file.path),
                                  ),
                            ]
                                .defaultIfEmpty(Center(
                                  child: EmptyWidget(
                                    title: loc.search,
                                    subTitle: loc.itemNotFoundIn(query, dynamicTitle),
                                  ),
                                ))
                                .toList() +
                            [Gap(context.height * .12)],
                      ),
              ),
      ),
    );
  }

  void callNumber() async => await FlutterPhoneDirectCaller.callNumber(query);

  void googleSearch() {
    addRecentSearch(query);
    launchUrl(Uri.http('www.google.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);
  }

  string groupByMode(dynamic e, string mode) {
    if (mode == 'alpha') {
      return e is Contact ? (e).displayName.first() : (e as AppInfo).appName.first();
    }
    if (mode == 'category') {
      return e is Contact ? "Contacts" : getCategoriesOf((e as AppInfo)).firstOrNull ?? "Undefined";
    }

    return "All";
  }

  StickyGroupedListView groupedListView() => StickyGroupedListView<dynamic, String>(
        elements: [...starredContacts, ...homeApps],
        groupBy: (e) => groupByMode(e, "category"),
        groupSeparatorBuilder: (e) => ListTile(
          title: Text(groupByMode(e, "category")),
        ),
        itemBuilder: (context, element) {
          if (element is Contact) {
            return ContactTile(
              contact: element,
              gridColumns: 1,
            );
          } else {
            return AppTile(
              app: element,
              gridColumns: 1,
            );
          }
        },
        itemScrollController: GroupedItemScrollController(),
        order: StickyGroupedListOrder.ASC,
      );

  @override
  void initState() {
    super.initState();

    HardwareKeyboard.instance.addHandler((event) {
      if (event is KeyDownEvent) {
        if (event.isKeyPressed(LogicalKeyboardKey.escape)) {
          isSearching = false;
          context.unfocus();
          setState(() {});
          return true;
        } else if (event.isControl(LogicalKeyboardKey.keyF) || event.isKeyPressed(LogicalKeyboardKey.f2) || event.isMeta(LogicalKeyboardKey.space)) {
          isSearching = !isSearching;
          setState(() {});
          if (isSearching) queryFocusNode.requestFocus();
          return true;
        } else if (event.isControl(LogicalKeyboardKey.semicolon) || event.isControl(LogicalKeyboardKey.keyQ)) {
          isSearching = true;
          query = ":";
          setState(() {});
          queryFocusNode.requestFocus();
          return true;
        } else if (event.isControl(LogicalKeyboardKey.at) || event.isControl(LogicalKeyboardKey.keyP)) {
          isSearching = true;
          query = "@";
          setState(() {});
          queryFocusNode.requestFocus();
          return true;
        } else if (event.isControl(LogicalKeyboardKey.keyB) || event.isKeyPressed(LogicalKeyboardKey.launchWebBrowser) || event.isKeyPressed(LogicalKeyboardKey.browserSearch)) {
          isSearching = true;
          query = "http://";
          queryFocusNode.requestFocus();
          setState(() {});
          return true;
        } else if (event.isControl(LogicalKeyboardKey.add) || event.isControl(LogicalKeyboardKey.keyM)) {
          isSearching = true;
          query = "=";
          queryFocusNode.requestFocus();
          setState(() {});
          return true;
        } else if (event.isKeyPressed(LogicalKeyboardKey.f12)) {
          Get.to(() => const SettingsScreen());
          setState(() {});
          return true;
        } else if (event.isControl(LogicalKeyboardKey.keyG)) {
          isSearching = true;
          query = "#";
          setState(() {});
          return true;
        } else if (event.isControlAlt(LogicalKeyboardKey.keyF)) {
          isSearching = true;
          query = "/"; // Files
          setState(() {});
          return true;
        } else if (event.isControl(LogicalKeyboardKey.keyI)) {
          showAutocomplete = !showAutocomplete;
          setState(() {});
          return true;
        }
      }

      return false;
    });
  }

  void instagramOpen() => launchUrl(Uri.http('instagram.com', '/${query.toSnakeCase}'), mode: LaunchMode.externalApplication);

  void mapSearch() {
    addRecentSearch(query);
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
    addRecentSearch(query);
    launchUrlString(query, mode: LaunchMode.externalApplication);
  }

  void playStoreSearch() {
    addRecentSearch(query);
    launchUrl(Uri.http('play.google.com', '/store/search', {'q': query}), mode: LaunchMode.externalApplication);
  }

  bool queryIsSingleApplication(string query) {
    return searchApps.length == 1 && query.isNotBlank && (query.startsWith(":") || (searchContacts.isEmpty && searchFiles.isEmpty));
  }

  bool queryIsSingleContact(string query) {
    return searchContacts.length == 1 && query.isNotBlank && (query.startsWith("@") || (searchApps.isEmpty && searchFiles.isEmpty));
  }

  Future<Iterable<string>> searchSuggestions() async {
    return [...recentSearches, ...(await query.fetchGoogleSuggestions(language: Get.locale?.languageCode ?? ""))].distinctFlat();
  }

  void smsTo() => launchUrlString('sms:$query');

  void spotifySearch() {
    addRecentSearch(query);
    launchUrl(Uri.https('open.spotify.com', '/search/$query'), mode: LaunchMode.externalApplication);
  }

  void whatsAppTo() => launchUrlString('whatsapp://send?phone=$query');

  void youtubeMusicSearch() {
    addRecentSearch(query);
    launchUrl(Uri.http('music.youtube.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);
  }

  void youtubeSearch() {
    addRecentSearch(query);
    launchUrl(Uri.http('www.youtube.com', '/results', {'search_query': query}), mode: LaunchMode.externalApplication);
  }
}
