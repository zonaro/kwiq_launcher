import 'dart:typed_data';

import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/app_tile.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';

class MyAppSearchDelegate extends SearchDelegate<String> {
  MyAppSearchDelegate();

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
          },
        )
      else
        StatefulBuilder(builder: (context, setState) {
          return IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: () {
              recentSearches = [];
              setState(() {});
            },
          );
        }),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  List<Application> get searchResults => filteredApps.where((app) {
        var q = [app.appName, app.category.name, app.packageName, ...getCategoriesOf(app.packageName)].map((x) => x.asFlat);
        if (q.any((x) => x.flatContains(query))) {
          return true;
        } else {
          return q.map((x) => x.getWords.any((y) => y.getLevenshtein(query, false) < 4)).any((x) => x);
        }
      }).toList();

  @override
  Widget buildResults(BuildContext context) {
    recentSearches = [...recentSearches, query];

    return ListView(
      children: [
        if (query.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.search),
            title: Text('Google Search for "$query"'),
            onTap: googleSearch,
          ),
        if (query.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.map),
            title: Text('Maps Search for "$query"'),
            onTap: mapSearch,
          ),
        const Divider(),
        if (hiddenApps.flatContains(query))
          FutureAwaiter(
            future: () async => await DeviceApps.getApp(hiddenApps.where((x) => x.flatEqual(query)).first, true),
            builder: (a) {
              return AppTile(
                application: a!,
                gridColumns: 1,
              );
            },
          ),
        for (var app in searchResults)
          AppTile(
            application: app,
            gridColumns: 1,
          )
      ]
          .defaultIfEmpty(
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0) + 20.fromTop,
                child: const Text('No results found'),
              ),
            ),
          )
          .toList(),
    );
  }

  Uint8List img(string s) => (apps.value!.where((x) => x.appName.flatEqual(s)).firstOrNull as ApplicationWithIcon?)?.icon ?? Uint8List(0);

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty ? recentSearches : searchResults.map((x) => x.appName).toList();

    return StatefulBuilder(builder: (context, setState) {
      return ListView(children: [
        if (query.isNumericOnly)
          ListTile(
            leading: const Icon(Icons.phone),
            title: Text('Call "$query"'),
            onTap: callNumber,
          ),
        if (query.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.search),
            title: Text('Google Search for "$query"'),
            onTap: googleSearch,
          ),
        if (query.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.map),
            title: Text('Maps Search for "$query"'),
            onTap: mapSearch,
          ),
        const Divider(),
        for (var suggestion in suggestionList)
          ListTile(
            title: Text(suggestion),
            leading: img(suggestion).isEmpty ? null : CircleAvatar(backgroundImage: MemoryImage(img(suggestion))),
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
      ]);
    });
  }

  void mapSearch() => launchUrl(Uri.https('www.google.com', '/maps/search/', {'q': query}), mode: LaunchMode.externalApplication);

  void googleSearch() => launchUrl(Uri.http('www.google.com', '/search', {'q': query}), mode: LaunchMode.externalApplication);

  void callNumber() {
    launchUrlString('tel: $query');
  }
}
