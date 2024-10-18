import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:innerlibs/innerlibs.dart';

Future<void> searchImages(String query) async {
  const pixabayApiKey = 'YOUR_PIXABAY_API_KEY';
  const unsplashAccessKey = 'YOUR_UNSPLASH_ACCESS_KEY';
  const wallpaperHavenApiKey = 'YOUR_WALLPAPERHAVEN_API_KEY';

  final pixabayUrl = 'https://pixabay.com/api/?key=$pixabayApiKey&q=$query';
  final unsplashUrl = 'https://api.unsplash.com/search/photos?query=$query&client_id=$unsplashAccessKey';
  final wallpaperHavenUrl = 'https://wallhaven.cc/api/v1/search?q=$query&apikey=$wallpaperHavenApiKey';

  final pixabayResponse = await http.get(Uri.parse(pixabayUrl));
  final unsplashResponse = await http.get(Uri.parse(unsplashUrl));
  final wallpaperHavenResponse = await http.get(Uri.parse(wallpaperHavenUrl));

  if (pixabayResponse.statusCode == 200) {
    final pixabayData = jsonDecode(pixabayResponse.body);
    consoleLog('Pixabay Results: ${pixabayData['hits']}');
  } else {
    consoleLog('Failed to load Pixabay images');
  }

  if (unsplashResponse.statusCode == 200) {
    final unsplashData = jsonDecode(unsplashResponse.body);
    consoleLog('Unsplash Results: ${unsplashData['results']}');
  } else {
    consoleLog('Failed to load Unsplash images');
  }

  if (wallpaperHavenResponse.statusCode == 200) {
    final wallpaperHavenData = jsonDecode(wallpaperHavenResponse.body);
    consoleLog('WallpaperHaven Results: ${wallpaperHavenData['data']}');
  } else {
    consoleLog('Failed to load WallpaperHaven images');
  }
}
