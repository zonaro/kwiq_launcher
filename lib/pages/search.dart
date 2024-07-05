import 'dart:io';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
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

  @override
  List<Widget> buildActions(BuildContext context) {
    return [];
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

  List<Application> get searchApps => filteredApps
      .search(
        searchTerm: query.removeFirstEqual(":"),
        searchOn: (app) => [app.appName, app.packageName, app.category.name, ...getCategoriesOf(app.packageName)],
        levenshteinDistance: 2,
        allIfEmpty: true,
      )
      .take(limitSearch)
      .toList();

  List<Contact> get searchContacts => contacts
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
      .take(limitSearch)
      .toList();

  List<Widget> searchOn(bool showGoogleSuggestions) {
    if (query.isNotEmpty) {
      return [
        if (showGoogleSuggestions)
          FutureAwaiter(
              future: () async => await query.fetchGoogleSuggestions(),
              builder: (sugestions) {
                return ExpansionTile(
                  leading: const Icon(Icons.text_fields),
                  title: sugestions.length.quantityText("Suggestions").asText(),
                  initiallyExpanded: (searchContacts.isEmpty && searchApps.isEmpty && searchFiles.isEmpty),
                  children: [
                    for (var suggestion in sugestions)
                      ListTile(
                        title: Text(suggestion),
                        leading: const Icon(
                          Icons.text_fields,
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
                          // showResults(context);
                        },
                      ),
                  ],
                );
              }),
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
        if (query.isNumericOnly && (apps.value?.map((a) => a.packageName).toList().flatContainsAny(['com.whatsapp', 'com.whatsapp.w4b']) ?? false))
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
          leading: const Icon(Icons.map),
          title: Text('Maps Search for "$query"'),
          onTap: mapSearch,
        ),
        if (apps.value?.map((a) => a.packageName).toList().flatContains(query) ?? false)
          AppTile(
            application: apps.value!.firstWhere((a) => a.packageName.flatContains(query)) as ApplicationWithIcon,
            gridColumns: 1,
            onPop: () => {},
          ),
      ];
    } else {
      return [];
    }
  }

  List<Object> get suggestionList {
    if (query.isEmpty) {
      return [
        ListTile(
          title: Wrap(
            children: [
              TextButton(onPressed: () => query = ":", child: const Text(": Apps")),
              TextButton(onPressed: () => query = "@", child: const Text("@ Contacts")),
              TextButton(onPressed: () => query = "#", child: const Text("# Categories")),
              TextButton(onPressed: () => query = ">", child: const Text("> Files")),
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
      recentSearches,
      ...searchContacts,
      ...searchApps,
      ...searchFiles,
    ].toList();
  }

  List<File> get searchFiles {
    try {
      final dir = Directory(fileController.controller.getCurrentDirectory.path);
      List<File> files = [];
      for (var file in dir.listSync(recursive: false).where((x) => x.path != '/storage/emulated/0/Android')) {
        if (file is Directory) {
          files.addAll(file.listSync(recursive: true).whereType<File>());
        } else {
          files.add(file as File);
        }
      }
      return files.search(searchTerm: query, searchOn: (file) => [file.fileName ?? file.fileNameWithoutExtension ?? file.path], levenshteinDistance: 2).take(limitSearch).toList();
    } catch (e) {
      consoleLog('Error: $e');
      return [];
    }
  }

  @override
  Widget buildResults(BuildContext context) {
    recentSearches = [...recentSearches, query].whereValid.distinct().toList();

    return baseWidgets(false);
  }

  @override
  Widget buildSuggestions(BuildContext context) => baseWidgets(true);

  Widget baseWidgets(bool showGoogleSuggestions) {
    return StatefulBuilder(builder: (context, setState) {
      if (preQuery.isNotEmpty) {
        query = preQuery;
        preQuery = '';
      }
      var catApps = filteredAppsByCategory[query] ?? [];
      if (catApps.isNotEmpty) {
        return ListView(
          children: <Widget>[
            for (var app in catApps)
              AppTile(
                application: app,
                gridColumns: 1,
                onPop: () => context.popUntilFirst(),
              )
          ],
        );
      } else {
        return ListView(children: [
          ...searchOn(showGoogleSuggestions),
          const Divider(),
          for (var suggestion in suggestionList)
            if (suggestion is ApplicationWithIcon)
              AppTile(
                application: suggestion,
                gridColumns: 1,
                onPop: () => context.popUntilFirst(),
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
                  // showResults(context);
                },
              )
            else if (suggestion is Widget)
              suggestion
            else
              const SizedBox.shrink()
        ]);
      }
    });
  }

  void mapSearch() => launchUrl(Uri.https('www.google.com', '/maps/search/', {'q': query}), mode: LaunchMode.externalApplication);

  void googleSearch() => launchUrl(Uri.http('www.google.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

  void bingSearch() => launchUrl(Uri.http('www.bing.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

  void callNumber() => launchUrlString('tel: $query');

  void openUrl() => launchUrlString(query);
  void openMail() => launchUrlString('mailto: $query');
  void smsTo() => launchUrlString('sms: $query');
  void whatsAppTo() => launchUrlString('whatsapp://send?phone= $query');
}
