import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:installed_apps/app_info.dart';
import 'package:kwiq_launcher/components/app_tile.dart';
import 'package:kwiq_launcher/components/contact_tile.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/file_manager.dart';
import 'package:kwiq_launcher/pages/home_page.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SearchPage extends StatefulWidget {
  final string query;

  const SearchPage({super.key, this.query = ''});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  string get query => searchController.text;
  set query(string value) => searchController.text = value;

  TextInputType inputType = TextInputType.text;

  Future<List<AppInfo>> get searchApps async {
    try {
      if (apps.isEmpty) {
        await loadApps();
      }

      return filteredApps
          .search(
            searchTerms: query.removeFirstEqual(":"),
            searchOn: (app) => [app.name, app.packageName, ...getCategoriesOf(app.packageName)],
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

  @override
  void initState() {
    super.initState();
    if (widget.query.isNotEmpty) {
      query = widget.query;
    }
  }

  TextEditingController searchController = TextEditingController();

  @override
  build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            flex: 10,
            child: ListView(shrinkWrap: true, children: [
              if (query.isBlank) ...suggestionTile(recentSearches),
              if (query.isBlank) ...[
                for (var app in homeApps)
                  AppTile(
                    app: app,
                    gridColumns: 1,
                  ),
                for (var contact in starredContacts)
                  ContactTile(
                    contact: contact,
                    gridColumns: 1,
                  ),
              ],
              if (apps.any((a) => a.packageName.flatEqual(query)))
                AppTile(
                  app: apps.firstWhere((a) => a.packageName.flatEqual(query)),
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
                if (query.isURL)
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
                FutureAwaiter(
                    future: () async => (await query.fetchGoogleSuggestions(language: Get.locale?.languageCode ?? "")),
                    loading: SizedBox(height: 100, child: Shimmer.fromColors(baseColor: Get.context!.colorScheme.surfaceBright, highlightColor: Get.context!.primaryColor, child: const Text("..."))),
                    builder: (suggestions) {
                      return ListView(shrinkWrap: true, children: [...suggestionTile(suggestions)]);
                    }),
                if (query.startsWith(":") || query.startsWithAny(tokens) == false)
                  FutureAwaiter(
                      future: () async => await searchApps,
                      loading: SizedBox(height: 100, child: Shimmer.fromColors(baseColor: Get.context!.colorScheme.surfaceBright, highlightColor: Get.context!.primaryColor, child: const Text("Searching Apps..."))),
                      builder: (apps) {
                        return ListView(
                          shrinkWrap: true,
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
                      loading: SizedBox(height: 100, child: Shimmer.fromColors(baseColor: Get.context!.colorScheme.surfaceBright, highlightColor: Get.context!.primaryColor, child: const Text("Searching Contacts..."))),
                      builder: (contacts) {
                        return ListView(
                          shrinkWrap: true,
                          children: [for (var contact in contacts) ContactTile(contact: contact, gridColumns: 1)],
                        );
                      }),
                if (query.startsWith(">") || query.startsWithAny(tokens) == false)
                  FutureAwaiter(
                      future: () async => searchFiles,
                      loading: SizedBox(height: 100, child: Shimmer.fromColors(baseColor: Get.context!.colorScheme.surfaceBright, highlightColor: Get.context!.primaryColor, child: const Text("Searching Files..."))),
                      builder: (files) {
                        return ListView(
                          shrinkWrap: true,
                          children: [
                            for (var file in files)
                              ListTile(
                                  title: Text(file.name | file.fileNameWithoutExtension | file.path),
                                  leading: const Icon(Icons.file_copy),
                                  onTap: () => OpenFile.open(file.path),
                                  onLongPress: () {
                                    fileController.controller.openDirectory(file.parent);
                                    pageController.animateToPage(1, duration: 1.seconds, curve: Curves.easeInOut);
                                    Get.back();
                                  })
                          ],
                        );
                      }),
              ]
            ]),
          ),
          StringField(
            label: 'Search',
            autofocus: true,
            controller: searchController,
            onChanged: (value) {
              query = value ?? "";
              setState(() {});
            },
            keyboardType: inputType,
            icon: query.isBlank ? (inputType == TextInputType.number ? Icons.numbers : Icons.abc) : Icons.clear,
            onIconTap: () {
              if (query.isBlank) {
                // Toggle between full keyboard and numeric keyboard
                if (inputType == TextInputType.text) {
                  inputType = TextInputType.number;
                } else {
                  inputType = TextInputType.text;
                }
              } else {
                query = '';
              }
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  void bingSearch() => launchUrl(Uri.http('www.bing.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

  void callNumber() => launchUrlString('tel: $query');

  void googleSearch() => launchUrl(Uri.http('www.google.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

  void instagramOpen() => launchUrl(Uri.http('www.instagram.com', '/$query'), mode: LaunchMode.externalApplication);

  void mapSearch() => launchUrl(Uri.https('www.google.com', '/maps/search/', {'q': query}), mode: LaunchMode.externalApplication);

  void openMail() => launchUrlString('mailto: $query');

  void openUrl() => launchUrlString(query);

  void playStoreSearch() => launchUrl(Uri.http('play.google.com', '/store/search', {'q': query}), mode: LaunchMode.externalApplication);

  void smsTo() => launchUrlString('sms: $query');

  void spotifySearch() => launchUrl(Uri.http('open.spotify.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

  Iterable<Widget> suggestionTile(List<String> suggestions) {
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
          },
        ),
    ];
  }

  void whatsAppTo() => launchUrlString('whatsapp://send?phone= $query');

  void youtubeMusicSearch() => launchUrl(Uri.http('music.youtube.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

  void youtubeSearch() => launchUrl(Uri.http('www.youtube.com', '/results', {'search_query': query}), mode: LaunchMode.externalApplication);
}
