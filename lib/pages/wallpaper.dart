import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';

class WallpaperApp extends StatefulWidget {
  const WallpaperApp({super.key});

  @override
  createState() => _WallpaperAppState();
}

class _WallpaperAppState extends State<WallpaperApp> {
  int _selectedIndex = 0;
  String _query = '';

  static const List<Widget> _screens = <Widget>[
    PixabayScreen(),
    UnsplashScreen(),
    WallpaperHavenScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onSearch(String query) {
    setState(() {
      _query = query;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search wallpapers...',
          ),
          onSubmitted: _onSearch,
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: 'Pixabay',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: 'Unsplash',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: 'WallpaperHaven',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

var conn = GetConnect();

class PixabayScreen extends StatelessWidget {
  const PixabayScreen({super.key});

  Future<List<String>> _fetchWallpapers(String query) async {
    final response = await conn.get<JsonMap>('https://pixabay.com/api/?key=YOUR_API_KEY&q=$query&image_type=photo');
    final data = response.body!;
    return (data['hits'] as List).map((hit) => hit['webformatURL'] as String).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _fetchWallpapers(''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final wallpapers = snapshot.data!;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemCount: wallpapers.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async {
                  final response = await conn.get(wallpapers[index]);
                  final bytes = (await response.bodyBytes?.toList())!.first;
                  final base64 = base64Encode(bytes);
                  //TODO: Handle the base64 string as needed
                },
                child: Image.network(wallpapers[index], fit: BoxFit.cover),
              );
            },
          );
        }
      },
    );
  }
}

class UnsplashScreen extends StatelessWidget {
  const UnsplashScreen({super.key});

  Future<List<String>> _fetchWallpapers(String query) async {
    final response = await conn.get<JsonMap>('https://api.unsplash.com/search/photos?query=$query&client_id=YOUR_API_KEY');
    final data = response.body!;
    return (data['results'] as List).map((result) => result['urls']['small'] as String).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _fetchWallpapers(''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final wallpapers = snapshot.data!;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemCount: wallpapers.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async {
                  final response = await conn.get(wallpapers[index]);
                  final bytes = (await response.bodyBytes?.toList())!.first;
                  final base64 = base64Encode(bytes);
                  //TODO: Handle the base64 string as needed
                },
                child: Image.network(wallpapers[index], fit: BoxFit.cover),
              );
            },
          );
        }
      },
    );
  }
}

class WallpaperHavenScreen extends StatelessWidget {
  const WallpaperHavenScreen({super.key});

  Future<List<String>> _fetchWallpapers(String query) async {
    final response = await conn.get<JsonMap>('https://wallpaperhaven.com/api/search?q=$query');
    final data = response.body!;
    return (data['wallpapers'] as List).map((wallpaper) => wallpaper['url'] as String).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _fetchWallpapers(''),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          final wallpapers = snapshot.data!;
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
            itemCount: wallpapers.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () async {
                  final response = await conn.get(wallpapers[index]);
                  final bytes = (await response.bodyBytes?.toList())!.first;
                  final base64 = base64Encode(bytes);
                  print(base64); // Handle the base64 string as needed
                },
                child: Image.network(wallpapers[index], fit: BoxFit.cover),
              );
            },
          );
        }
      },
    );
  }
}
