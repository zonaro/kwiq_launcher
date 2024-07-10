// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/contact_tile.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/search.dart';

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
        onPopInvoked: (p) async {
          await showSearch(context: context, delegate: MyAppSearchDelegate());
          setState(() {});
        },
        child: gridColumns > 1 ? appGrid() : appList(),
      ),
    );
  }

  Widget appGrid() => SizedBox(
        height: context.height,
        width: context.width,
        child: GridView.count(
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
        ),
      );

  Widget appList() => SizedBox(
        height: context.height,
        width: context.width,
        child: ListView(
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
            SizedBox(
              height: context.height * .12,
            ),
          ],
        ),
      );
}
