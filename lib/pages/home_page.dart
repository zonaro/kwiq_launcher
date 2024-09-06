// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/pages/file_manager.dart';
import 'package:kwiq_launcher/pages/search.dart';
import 'package:kwiq_launcher/pages/settings.dart';

final PageController pageController = PageController();

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

PageTabController? indexController;

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
 

    return PopScope(canPop: false, child: PageTabScaffold(indexController: indexController!,items: [
      PageEntry(
        showAppBar: false,
        icon: Icons.home,
        title: 'Home',
        tabs: [
          TabEntry(
            icon: Icons.star,
            child: const SearchPage(),
          ),
          TabEntry(
            icon: Icons.file_copy,
            title: 'Files',
            child: const FilePage(),
          )
        ],
      ),
      PageEntry(
        icon: Icons.settings,
        title: 'Settings',
        tabs: [
          TabEntry(
            child: const SettingsScreen(),
          )
        ],
      ),
    ],));
  }
}
