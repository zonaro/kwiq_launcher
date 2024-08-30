// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:installed_apps/app_info.dart';
import 'package:kwiq_launcher/components/contact_tile.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:sticky_grouped_list/sticky_grouped_list.dart';

import '../components/app_tile.dart';

class AppPage extends StatefulWidget {
  const AppPage({super.key});

  @override
  createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (p, r) async {},
        child: Column(
          children: [
            Expanded(child: gridColumns > 1 ? appGrid() : appList()),
            Gap(context.height * .12),
          ],
        ),
      ),
    );
  }

  Widget appGrid() => GridView.count(
        crossAxisCount: gridColumns,
        shrinkWrap: true,
        children: [
          for (var c in starredContacts)
            ContactTile(
              contact: c,
              gridColumns: gridColumns,
            ),
          for (var application in homeApps)
            AppTile(
              app: application,
              gridColumns: gridColumns,
            ),
        ],
      );

  string groupByMode(dynamic e, string mode) {
    if (mode == 'alpha') {
      return e is Contact ? (e).displayName.first() : (e as AppInfo).name.first();
    }
    if (mode == 'category') {
      return e is Contact ? "Contacts" : getCategoriesOf((e as AppInfo).packageName).firstOrNull ?? "Undefined";
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

  Widget appList() => ListView(
        shrinkWrap: true,
        children: [
          for (var c in starredContacts)
            ContactTile(
              contact: c,
              gridColumns: gridColumns,
            ),
          for (var application in homeApps)
            AppTile(
              app: application,
              gridColumns: 1,
            ),
        ],
      );
}
