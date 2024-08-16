import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:icons_plus/icons_plus.dart';
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

  TextInputType inputType = TextInputType.text;

  MyAppSearchDelegate([this.preQuery = '']);

  @override
  TextInputType? get keyboardType => inputType;

  Future<List<ApplicationWithIcon>> get searchApps async {
    try {
      if (apps.isEmpty) {
        await loadApps();
      }

      return filteredApps
          .search(
            searchTerms: query.removeFirstEqual(":"),
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
    return files.search(searchTerms: query, searchOn: (file) => [file.name, file.fileNameWithoutExtension, file.path], levenshteinDistance: 2).toList();
  }

  Widget baseWidgets() {
    return StatefulBuilder(builder: (context, setState) {
      if (preQuery.isNotEmpty) {
        query = preQuery;
        preQuery = '';
      }

      return ListView(children: [
        // if (catApps.isNotEmpty)
        //   for (var app in catgoryApps)
        //     AppTile(
        //       app: app,
        //       gridColumns: 1,
        //     ),
        if (query.isBlank) suggestionTile(recentSearches, setState, context),
        if (query.isBlank)
          for (var app in homeApps)
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
              leading: const Icon(Icons.message),
              title: Text('New message to "$query"'),
              onTap: smsTo,
            ),
          if ((Brasil.validarTelefone(query) || query.isNumericOnly) && hasWhatsapp)
            ListTile(
              leading: Brand(Brands.whatsapp),
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
              title: Text('New email to "$query"'),
              onTap: openMail,
            ),
          ListTile(
            leading: Brand(Brands.google),
            title: Text('Google Search for "$query"'),
            onTap: googleSearch,
          ),
          ListTile(
            leading: Brand(Brands.bing),
            title: Text('Bing Search for "$query"'),
            onTap: bingSearch,
          ),
          ListTile(
            leading: Brand(Brands.youtube),
            title: Text('YouTube Search for "$query"'),
            onTap: youtubeSearch,
          ),
          ListTile(
            leading: Brand(Brands.youtube_music),
            title: Text('YouTube Music Search for "$query"'),
            onTap: youtubeMusicSearch,
          ),
          ListTile(
            leading: Brand(Brands.spotify),
            title: Text('Spotify Search for "$query"'),
            onTap: spotifySearch,
          ),
          ListTile(
            leading: Brand(Brands.google_play),
            title: Text('Play Store Search for "$query"'),
            onTap: playStoreSearch,
          ),
          ListTile(
            leading: Brand(Brands.google_maps),
            title: Text('Google Maps Search for "$query"'),
            onTap: mapSearch,
          ),
          ListTile(
            leading: Brand(Brands.instagram),
            title: Text('Open "/$query" profile on Instagram'),
            onTap: instagramOpen,
          ),
          const Divider(),
        ],
        if (apps.any((a) => a.packageName.flatEqual(query)))
          AppTile(
            app: apps.firstWhere((a) => a.packageName.flatEqual(query)),
            gridColumns: 1,
          ),
        ...[
          FutureAwaiter(
              future: () async => (await query.fetchGoogleSuggestions(language: Get.locale?.languageCode ?? "")),
              loading: Shimmer.fromColors(baseColor: context.colorScheme.surfaceBright, highlightColor: context.primaryColor, child: const Text("...")),
              builder: (suggestions) {
                return suggestionTile(suggestions, setState, context);
              }),
          if (query.startsWith(":") || query.startsWithAny(tokens) == false)
            FutureAwaiter(
                future: () async => await searchApps,
                loading: Shimmer.fromColors(baseColor: context.colorScheme.surfaceBright, highlightColor: context.primaryColor, child: const Text("Searching Apps...")),
                builder: (apps) {
                  return ListView(
                    children: [
                      for (var app in apps)
                        AppTile(
                          app: app,
                          gridColumns: 1,
                        ),
                    ],
                  );
                }),
          if (query.startsWith("@") || query.startsWithAny(tokens) == false)
            FutureAwaiter(
                future: () async => await searchContacts,
                loading: Shimmer.fromColors(baseColor: context.colorScheme.surfaceBright, highlightColor: context.primaryColor, child: const Text("Searching Contacts...")),
                builder: (contacts) {
                  return ListView(
                    children: [for (var contact in contacts) ContactTile(contact: contact, gridColumns: 1)],
                  );
                }),
          if (query.startsWith(">") || query.startsWithAny(tokens) == false)
            FutureAwaiter(
                future: () async => searchFiles,
                loading: Shimmer.fromColors(baseColor: context.colorScheme.surfaceBright, highlightColor: context.primaryColor, child: const Text("Searching Files...")),
                builder: (files) {
                  return ListView(
                    children: [
                      for (var file in files)
                        ListTile(
                            title: Text(file.name | file.fileNameWithoutExtension | file.path),
                            leading: const Icon(Icons.file_copy),
                            onTap: () => OpenFile.open(file.path),
                            onLongPress: () {
                              fileController.controller.openDirectory(file.parent);
                              pageController.animateToPage(1, duration: 1.seconds, curve: Curves.easeInOut);
                              context.pop();
                            })
                    ],
                  );
                }),
        ]
      ]);
    });
  }

  void bingSearch() => launchUrl(Uri.http('www.bing.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

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

  @override
  Widget buildResults(BuildContext context) {
    recentSearches = [...recentSearches, query].whereValid.distinct().toList();

    return baseWidgets();
  }

  @override
  Widget buildSuggestions(BuildContext context) => baseWidgets();

  void callNumber() => launchUrlString('tel: $query');

  void googleSearch() => launchUrl(Uri.http('www.google.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

  void instagramOpen() => launchUrl(Uri.http('www.instagram.com', '/$query'), mode: LaunchMode.externalApplication);

  void mapSearch() => launchUrl(Uri.https('www.google.com', '/maps/search/', {'q': query}), mode: LaunchMode.externalApplication);

  void openMail() => launchUrlString('mailto: $query');

  void openUrl() => launchUrlString(query);

  void playStoreSearch() => launchUrl(Uri.http('play.google.com', '/store/search', {'q': query}), mode: LaunchMode.externalApplication);

  void smsTo() => launchUrlString('sms: $query');

  void spotifySearch() => launchUrl(Uri.http('open.spotify.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

  ListView suggestionTile(List<String> suggestions, StateSetter setState, BuildContext context) {
    return ListView(
      children: [
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
                      setState(() {});
                    })
                : null,
            onTap: () {
              query = suggestion;
              showResults(context);
            },
          ),
      ],
    );
  }

  void whatsAppTo() => launchUrlString('whatsapp://send?phone= $query');
  void youtubeMusicSearch() => launchUrl(Uri.http('music.youtube.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);
  void youtubeSearch() => launchUrl(Uri.http('www.youtube.com', '/results', {'search_query': query}), mode: LaunchMode.externalApplication);
}
