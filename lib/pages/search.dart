import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart' hide GetStringUtils;
import 'package:innerlibs/file_extensions.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/app_tile.dart';
import 'package:kwiq_launcher/components/contact_tile.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/file_manager.dart';
import 'package:kwiq_launcher/pages/home_page.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MyAppSearchDelegate extends SearchDelegate<String> {
  string preQuery = '';

  MyAppSearchDelegate([this.preQuery = '']);

  TextInputType inputType = TextInputType.text;

  @override
  TextInputType? get keyboardType => inputType;

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(inputType == TextInputType.number ? Icons.abc : Icons.numbers),
        onPressed: () {
          // Toggle between full keyboard and numeric keyboard
          if (keyboardType == TextInputType.text) {
            inputType = TextInputType.number;
          } else {
            inputType = TextInputType.text;
          }
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (query.isNotBlank) {
          query = '';
        } else {
          close(context, query);
        }
      },
    );
  }

  Future<List<Application>> get searchApps async {
    try {
      if (apps.isEmpty) {
        await loadApps();
      }

      return filteredApps
          .search(
            searchTerm: query.removeFirstEqual(":"),
            searchOn: (app) => [app.appName, app.packageName, app.category.name, ...getCategoriesOf(app.packageName)],
            levenshteinDistance: 2,
            allIfEmpty: true,
          )
          .toList();
    } catch (e) {
      consoleLog('Error: $e');
      return [];
    }
  }

  Future<List<Contact>> get searchContacts async {
    try {
      if (contacts.isEmpty) {
        contacts = (await FlutterContacts.getContacts(
          withAccounts: true,
          withGroups: true,
          deduplicateProperties: true,
          withPhoto: true,
          withThumbnail: true,
          withProperties: true,
          sorted: true,
        ))
            .toList();
      }

      return contacts
          .search(
            searchTerm: query.removeFirstEqual("@"),
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

  Future<bool> get checkWhatsapp async => await DeviceApps.isAppInstalled('com.whatsapp') || await DeviceApps.isAppInstalled('com.whatsapp.w4b');

  Future<List<Object>> get suggestionList async {
    if (query.isEmpty) {
      return [
        ListTile(
          title: Wrap(
            children: [
              TextButton.icon(icon: const Icon(Icons.apps), onPressed: () => query = ":", label: const Text(":Apps")),
              TextButton.icon(icon: const Icon(Icons.person), onPressed: () => query = "@", label: const Text("@Contacts")),
              TextButton.icon(icon: const Icon(Icons.category), onPressed: () => query = "#", label: const Text("#Categories")),
              TextButton.icon(icon: const Icon(Icons.file_copy), onPressed: () => query = ">", label: const Text(">Files")),
            ],
          ),
        ),
        ...recentSearches,
      ];
    }

    if (query.startsWith("@")) {
      return searchContacts;
    }

    if (query.startsWith(":")) {
      return searchApps;
    }

    if (query.startsWith("#")) {
      return categories;
    }

    if (query.startsWith(">")) {
      return searchFiles;
    }

    return [
      ...[
        ...recentSearches,
        ...(await query.fetchGoogleSuggestions(language: Get.locale?.languageCode ?? "")),
      ].distinctFlat(),
      ...(await searchContacts),
      ...(await searchApps),
      ...searchFiles,
    ].toList();
  }

  List<File> get searchFiles {
    final dir = Directory(fileController.controller.getCurrentDirectory.path);
    List<File> files = [];
    try {
      for (var file in dir.listSync(recursive: false).where((x) => x.path != '/storage/emulated/0/Android')) {
        if (file is Directory) {
          files.addAll(file.listSync(recursive: true).whereType<File>());
        } else {
          files.add(file as File);
        }
      }
    } catch (e) {
      consoleLog('Error: $e');
      return [];
    }
    return files.search(searchTerm: query, searchOn: (file) => [file.fileName ?? file.fileNameWithoutExtension ?? file.path], levenshteinDistance: 2).toList();
  }

  @override
  Widget buildResults(BuildContext context) {
    recentSearches = [...recentSearches, query].whereValid.distinct().toList();

    return baseWidgets();
  }

  @override
  Widget buildSuggestions(BuildContext context) => baseWidgets();

  Widget baseWidgets() {
    return StatefulBuilder(builder: (context, setState) {
      if (preQuery.isNotEmpty) {
        query = preQuery;
        preQuery = '';
      }
      return FutureAwaiter(
        future: () async {
          return (await suggestionList, await checkWhatsapp);
        },
        builder: (r) {
          var catApps = filteredAppsByCategory[query] ?? [];
          var items = r.$1;
          var whats = r.$2;

          return ListView(children: [
            if (catApps.isNotEmpty)
              for (var app in catApps)
                AppTile(
                  app: app,
                  gridColumns: 1,
                ),
            if (query.isNotBlank && !query.startsWithAny(tokens)) ...[
              if (query.isNumericOnly)
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text('Call "$query"'),
                  onTap: callNumber,
                ),
              if (query.isNumericOnly)
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text('Sms to "$query"'),
                  onTap: smsTo,
                ),
              if (query.isNumericOnly && whats)
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text('WhatsApp to "$query"'),
                  onTap: whatsAppTo,
                ),
              if (query.isUrl)
                ListTile(
                  leading: const Icon(Icons.link),
                  title: Text('Open URL "$query"'),
                  onTap: openUrl,
                ),
              if (query.isEmail)
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text('New message to "$query"'),
                  onTap: openMail,
                ),
              ListTile(
                leading: const Icon(Icons.search),
                title: Text('Google Search for "$query"'),
                onTap: googleSearch,
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: Text('Bing Search for "$query"'),
                onTap: bingSearch,
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: Text('YouTube Search for "$query"'),
                onTap: youtubeSearch,
              ),
              ListTile(
                leading: const Icon(Icons.store),
                title: Text('Play Store Search for "$query"'),
                onTap: playStoreSearch,
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: Text('Spotify Search for "$query"'),
                onTap: spotifySearch,
              ),
              ListTile(
                leading: const Icon(Icons.search),
                title: Text('YouTube Music Search for "$query"'),
                onTap: youtubeMusicSearch,
              ),
              ListTile(
                leading: const Icon(Icons.map),
                title: Text('Maps Search for "$query"'),
                onTap: mapSearch,
              ),
              const Divider(),
            ],
            if (apps.any((a) => a.packageName.flatEqual(query)))
              AppTile(
                app: apps.firstWhere((a) => a.packageName.flatEqual(query)),
                gridColumns: 1,
              ),
            if (catApps.isEmpty)
              for (var suggestion in items)
                if (suggestion is ApplicationWithIcon)
                  AppTile(
                    app: suggestion,
                    gridColumns: 1,
                  )
                else if (suggestion is Contact)
                  ContactTile(contact: suggestion, gridColumns: 1)
                else if (suggestion is File)
                  ListTile(
                      title: Text(suggestion.fileName ?? suggestion.fileNameWithoutExtension ?? suggestion.path),
                      leading: const Icon(Icons.file_copy),
                      onTap: () => OpenFile.open(suggestion.path),
                      onLongPress: () {
                        fileController.controller.openDirectory(suggestion.parent);
                        pageController.animateToPage(1, duration: 1.seconds, curve: Curves.easeInOut);
                        context.pop();
                      })
                else if (suggestion is string)
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
                              setState(() {});
                            })
                        : null,
                    onTap: () {
                      query = suggestion;
                      showResults(context);
                    },
                  )
                else
                  suggestion.forceWidget() ?? const SizedBox.shrink(),
          ]);
        },
      );
    });
  }

  void mapSearch() => launchUrl(Uri.https('www.google.com', '/maps/search/', {'q': query}), mode: LaunchMode.externalApplication);

  void googleSearch() => launchUrl(Uri.http('www.google.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

  void bingSearch() => launchUrl(Uri.http('www.bing.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

  void youtubeSearch() => launchUrl(Uri.http('www.youtube.com', '/results', {'search_query': query}), mode: LaunchMode.externalApplication);

  void playStoreSearch() => launchUrl(Uri.http('play.google.com', '/store/search', {'q': query}), mode: LaunchMode.externalApplication);

  void spotifySearch() => launchUrl(Uri.http('open.spotify.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

  void youtubeMusicSearch() => launchUrl(Uri.http('music.youtube.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

  void callNumber() => launchUrlString('tel: $query');

  void openUrl() => launchUrlString(query);
  void openMail() => launchUrlString('mailto: $query');
  void smsTo() => launchUrlString('sms: $query');
  void whatsAppTo() => launchUrlString('whatsapp://send?phone= $query');
}
