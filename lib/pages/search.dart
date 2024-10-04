import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/app_tile.dart';
import 'package:kwiq_launcher/components/contact_tile.dart';
import 'package:kwiq_launcher/components/digital_clock.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/settings.dart';
import 'package:open_file/open_file.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SearchPage extends StatefulWidget {
  final string query;

  const SearchPage({super.key, this.query = ''});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  string get query => queryController.text;
  set query(string value) => queryController.text = value;
  TextEditingController queryController = TextEditingController();
  FocusNode queryFocusNode = FocusNode();

  TextInputType inputType = TextInputType.url;

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
    final dir = Directory('/storage/emulated/0/');
    Set<File> files = {};
    for (var file in dir.listSync(recursive: false).where((x) => !x.path.startsWith('/storage/emulated/0/Android'))) {
      try {
        if (file is Directory) {
          files.addAll(file.listSync(recursive: true).whereType<File>());
        } else {
          files.add(file as File);
        }
      } catch (e) {
        consoleLog('Error: $e');
      }
    }
    return files.search(searchTerms: query.removeFirstEqual(">"), searchOn: (file) => [file.name, file.fileNameWithoutExtension, file.path], levenshteinDistance: 2);
  }

  Future<Iterable<string>> searchSuggestions() async {
    return (recentSearches + (await query.fetchGoogleSuggestions(language: Get.locale?.languageCode ?? ""))).distinctFlat();
  }

  @override
  void initState() {
    super.initState();
    if (widget.query.isNotEmpty) {
      query = widget.query;
    }
  }

  final loc = Get.context!.innerLibsLocalizations;

  bool isSearching = false;

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

  bool get showAutocomplete => prefs.getBool("showAutocomplete") ?? false;
  set showAutocomplete(bool value) => prefs.setBool("showAutocomplete", value);

  @override
  build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 100,
        title: isSearching
            ? Autocomplete<string>(
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
                    inputFormatters: [inputType == TextInputType.number ? FilteringTextInputFormatter.digitsOnly : FilteringTextInputFormatter.singleLineFormatter],
                    keyboardType: inputType,
                    textInputAction: TextInputAction.search,
                  );
                },
                optionsBuilder: (TextEditingValue textEditingValue) => showAutocomplete ? searchSuggestions() : [],
              )
            : const DigitalClock(),
        actions: [
          if (!isSearching)
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Get.to(() => const SettingsScreen());
              },
            ),
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
                  if (inputType == TextInputType.url) {
                    inputType = TextInputType.number;
                    query = query.onlyNumbers;
                  } else {
                    inputType = TextInputType.url;
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
                    query = '';
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
      body: query.isBlank
          ? GridView.count(
              crossAxisCount: gridColumns,
              shrinkWrap: true,
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
              ],
            )
          : ListView(
              shrinkWrap: true,
              children: [
                if (apps.any((a) => a.packageName.flatEqual(query)))
                  AppTile(
                    app: apps.firstWhere((a) => a.packageName.flatEqual(query)),
                    gridColumns: 1,
                  ),
                if (!query.startsWithAny(tokenList)) ...[
                  if (query.isPhoneNumber)
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(loc.calltoItem(query.quote)),
                      onTap: callNumber,
                    ),
                  if (query.isPhoneNumber)
                    ListTile(
                      leading: const Icon(Icons.message),
                      title: Text(loc.sendItemToItem("SMS", query.quote)),
                      onTap: smsTo,
                    ),
                  if (query.isPhoneNumber && hasWhatsapp)
                    ListTile(
                      leading: Brand(Brands.whatsapp),
                      title: Text(loc.sendItemToItem("WhatsApp", query.quote)),
                      onTap: whatsAppTo,
                    ),
                  if (query.isURL)
                    ListTile(
                      leading: const Icon(Icons.link),
                      title: Text('${loc.open} URL "$query"'),
                      onTap: openUrl,
                    ),
                  if (query.isEmail)
                    ListTile(
                      leading: const Icon(Icons.email),
                      title: Text('${loc.newItem("email")} ${loc.to} "$query"'),
                      onTap: openMail,
                    ),
                  ListTile(
                    leading: Brand(Brands.google),
                    title: Text(loc.searchForIn(query.quote, "Google")),
                    onTap: googleSearch,
                  ),
                  ListTile(
                    leading: Brand(Brands.bing),
                    title: Text(loc.searchForIn(query.quote, "Bing")),
                    onTap: bingSearch,
                  ),
                  ListTile(
                    leading: Brand(Brands.youtube),
                    title: Text(loc.searchForIn(query.quote, "YouTube")),
                    onTap: youtubeSearch,
                  ),
                  ListTile(
                    leading: Brand(Brands.youtube_music),
                    title: Text(loc.searchForIn(query.quote, "YouTube Music")),
                    onTap: youtubeMusicSearch,
                  ),
                  ListTile(
                    leading: Brand(Brands.spotify),
                    title: Text(loc.searchForIn(query.quote, "Spotify")),
                    onTap: spotifySearch,
                  ),
                  ListTile(
                    leading: Brand(Brands.google_play),
                    title: Text(loc.searchForIn(query.quote, "Play Store")),
                    onTap: playStoreSearch,
                  ),
                  ListTile(
                    leading: Brand(Brands.google_maps),
                    title: Text(loc.searchForIn(query.quote, "Google Maps")),
                    onTap: mapSearch,
                  ),
                  ListTile(
                    leading: Brand(Brands.instagram),
                    title: Text('${loc.open} "instagram/${query.toSnakeCase}"'),
                    onTap: instagramOpen,
                  ),
                  const Divider(),
                ],
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
                if (query.startsWith(">") || !query.startsWithAny(tokenList))
                  for (var file in searchFiles)
                    ListTile(
                      title: Text(file.name | file.fileNameWithoutExtension | file.path),
                      leading: const Icon(Icons.file_copy),
                      onTap: () => OpenFile.open(file.path),
                    )
              ],
            ),
    );
  }

  string get dynamicTitle {
    if (query.startsWithAny(tokenList)) {
      return tokens[query.first()]!;
    }
    return loc.search;
  }

  void bingSearch() {
    addRecentSearch(query);
    launchUrl(Uri.http('www.bing.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);
  }

  void callNumber() => launchUrlString('tel: $query');

  void googleSearch() {
    addRecentSearch(query);
    launchUrl(Uri.http('www.google.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);
  }

  void instagramOpen() => launchUrl(Uri.http('www.instagram.com', '/${query.toSnakeCase}'), mode: LaunchMode.externalApplication);

  void mapSearch() {
    addRecentSearch(query);
    launchUrl(Uri.https('www.google.com', '/maps/search/', {'q': query}), mode: LaunchMode.externalApplication);
  }

  void openMail() => launchUrlString('mailto:$query');

  void openUrl() => launchUrlString(query);

  void playStoreSearch() {
    addRecentSearch(query);
    launchUrl(Uri.http('play.google.com', '/store/search', {'q': query}), mode: LaunchMode.externalApplication);
  }

  void smsTo() => launchUrlString('sms:$query');

  void spotifySearch() {
    addRecentSearch(query);

    launchUrl(Uri.http('open.spotify.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);
  }

  List<Widget> suggestionTiles(Iterable<String> suggestions) {
    return [
      for (var suggestion in suggestions)
        ListTile(
          title: Text(suggestion),
          leading: const Icon(
            Icons.text_format,
          ),
          trailing: recentSearches.contains(suggestion)
              ? IconButton(
                  icon: const Icon(Icons.delete_forever),
                  onPressed: () {
                    recentSearches = recentSearches.where((x) => x != suggestion).toList();
                  })
              : null,
          onTap: () {
            query = suggestion;
            setState(() {});
            Get.forceAppUpdate();
          },
        ),
    ];
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
