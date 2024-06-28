import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/app_tile.dart';
import 'package:kwiq_launcher/components/contact_tile.dart';
import 'package:kwiq_launcher/main.dart';
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
        } else {}
        close(context, query);
      },
    );
  }

  List<Application> get searchApps => filteredApps
      .search(
        searchTerm: query,
        searchOn: (app) => [app.appName, app.packageName, app.category.name, ...getCategoriesOf(app.packageName)],
        levenshteinDistance: 2,
        allIfEmpty: true,
      )
      .toList();

  List<Contact> get searchContacts => contacts
      .search(
        searchTerm: query,
        searchOn: (contact) => [
          contact.name.first,
          contact.name.last,
          contact.name.nickname,
          contact.displayName,
          ...contact.emails.map((e) => e.address),
          ...contact.phones.map((e) => e.number),
        ],
        levenshteinDistance: 3,
      )
      .toList();

  List<Widget> searchOn() {
    if (query.isNotEmpty) {
      return [
        FutureAwaiter(
            future: () async => query.fetchGoogleSuggestions(),
            builder: (sugestions) {
              return ExpansionTile(
                leading: const Icon(Icons.search),
                title: "Google".asText(),
                initiallyExpanded: true,
                children: [
                  for (var suggestion in sugestions)
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
          leading: const Icon(Icons.web),
          title: Text('Google Search for "$query"'),
          onTap: googleSearch,
        ),
        ListTile(
          leading: const Icon(Icons.web),
          title: Text('Bing Search for "$query"'),
          onTap: bingSearch,
        ),
        ListTile(
          leading: const Icon(Icons.map),
          title: Text('Maps Search for "$query"'),
          onTap: mapSearch,
        ),
        if (apps.value?.map((a) => a.packageName).toList().flatContains(query) ?? false)
          Builder(builder: (context) {
            var app = apps.value!.firstWhere((a) => a.packageName.flatContains(query)) as ApplicationWithIcon;
            return ListTile(
              leading: Image.memory(
                app.icon,
              ),
              title: Text('Open "${app.appName}"'),
              onTap: () => DeviceApps.openApp(app.packageName),
            );
          }),
      ];
    } else {
      return [];
    }
  }

  List<Object> get suggestionList => query.isEmpty
      ? recentSearches
      : [
          ...searchContacts,
          ...searchApps,
        ].toList();

  @override
  Widget buildResults(BuildContext context) {
    recentSearches = [...recentSearches, query].whereValid.toList();
    return baseWidgets();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return baseWidgets();
  }

  Widget baseWidgets() {
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
          ...searchOn(),
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
              ),
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
}
