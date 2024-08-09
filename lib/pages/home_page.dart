// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/digital_clock.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/app_page.dart';
import 'package:kwiq_launcher/pages/file_manager.dart';
import 'package:kwiq_launcher/pages/search.dart';
import 'package:kwiq_launcher/pages/settings.dart';

final PageController pageController = PageController();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: InkWell(
        onLongPress: () async {
          if (categories.isNotEmpty) {
            await showModalBottomSheet(
              context: context,
              builder: (BuildContext context) {
                return ListView(
                  children: [
                    for (var category in categories)
                      ListTile(
                        leading: Icon(categoryIcon(category)),
                        trailing: Text(filteredAppsByCategory[category]?.length.toString() ?? "0"),
                        title: Text(category),
                        onTap: () async {
                          context.pop();
                          await showSearch(context: context, delegate: MyAppSearchDelegate(category));
                        },
                      ),
                  ],
                );
              },
            );
          }
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var token in tokens)
              FloatingActionButton.small(
                child: Text(token),
                onPressed: () async {
                  await showSearch(context: context, delegate: MyAppSearchDelegate(token));
                },
              ),
            FloatingActionButton(
              child: const Icon(Icons.search),
              onPressed: () async {
                await showSearch(context: context, delegate: MyAppSearchDelegate());
              },
            ),
          ].insertBetween(const Gap(10)),
        ),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Padding(
          padding: EdgeInsets.all(5.0),
          child: DigitalClock(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await context.push(const SettingsScreen());
            },
          ),
        ],
      ),
      body: PageView(
        controller: pageController,
        children: const [
          AppPage(),
          FilePage(),
        ],
      ),
    );
  }
}
