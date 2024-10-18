import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> searchImages(String query) async {
  final pixabayApiKey = 'YOUR_PIXABAY_API_KEY';
  final unsplashAccessKey = 'YOUR_UNSPLASH_ACCESS_KEY';
  final wallpaperHavenApiKey = 'YOUR_WALLPAPERHAVEN_API_KEY';

  final pixabayUrl = 'https://pixabay.com/api/?key=$pixabayApiKey&q=$query';
  final unsplashUrl = 'https://api.unsplash.com/search/photos?query=$query&client_id=$unsplashAccessKey';
  final wallpaperHavenUrl = 'https://wallhaven.cc/api/v1/search?q=$query&apikey=$wallpaperHavenApiKey';

  final pixabayResponse = await http.get(Uri.parse(pixabayUrl));
  final unsplashResponse = await http.get(Uri.parse(unsplashUrl));
  final wallpaperHavenResponse = await http.get(Uri.parse(wallpaperHavenUrl));

  if (pixabayResponse.statusCode == 200) {
    final pixabayData = jsonDecode(pixabayResponse.body);
    print('Pixabay Results: ${pixabayData['hits']}');
  } else {
    print('Failed to load Pixabay images');
  }

  if (unsplashResponse.statusCode == 200) {
    final unsplashData = jsonDecode(unsplashResponse.body);
    print('Unsplash Results: ${unsplashData['results']}');
  } else {
    print('Failed to load Unsplash images');
  }

  if (wallpaperHavenResponse.statusCode == 200) {
    final wallpaperHavenData = jsonDecode(wallpaperHavenResponse.body);
    print('WallpaperHaven Results: ${wallpaperHavenData['data']}');
  } else {
    print('Failed to load WallpaperHaven images');
  }
}
