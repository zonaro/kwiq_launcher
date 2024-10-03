// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/pages/search.dart';
import 'package:kwiq_launcher/pages/settings.dart';

final PageController pageController = PageController();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

PageTabController indexController = PageTabController();

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: PageTabScaffold(
          indexController: indexController,
          iconColor: context.onSurfaceColor,
          activeIconColor: mainColor,
          titleColor: mainColor,
          items: [
            PageEntry(
              showAppBar: false,
              icon: Icons.home,
              title: 'Home',
              tabs: [
                TabEntry(
                  builder: (_) => const SearchPage(),
                ),
              ],
            ),
            PageEntry(
              icon: Icons.settings,
              title: 'Settings',
              tabs: [
                TabEntry(
                  builder: (_) => const SettingsScreen(),
                )
              ],
            ),
          ],
        ));
  }
}
