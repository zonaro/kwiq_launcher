import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/game/platform_map.dart';
import 'package:kwiq_launcher/main.dart';

Widget getWiki(String q) {
  return FutureAwaiter(
    future: () => wikipedia.searchQuery(searchQuery: q, limit: 1),
    emptyChild: Padding(
      padding: const EdgeInsets.all(20.0),
      child: AutoSizeText(platformName(q), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    ),
    builder: (result) => Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          AutoSizeText(platformName(q), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          AutoSizeText(result?.query?.search?.firstOrNull?.snippet ?? ""),
        ],
      ),
    ),
  );
}
