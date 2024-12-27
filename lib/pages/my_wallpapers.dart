import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:kwiq_launcher/models/kwiq_config.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wallhaven_cc/wallhaven_client.dart';

class AnimatedImageList extends StatefulWidget {
  final List<ImageProvider<Object>> images;
  final Duration duration;
  final Duration fade;
  final Function(ImageProvider<Object>) onChange;

  const AnimatedImageList({
    super.key,
    required this.images,
    this.duration = const Duration(seconds: 3),
    this.fade = const Duration(milliseconds: 500),
    required this.onChange,
  });

  @override
  State<AnimatedImageList> createState() => _AnimatedImageListState();
}

class MyWallpapersScreen extends StatefulWidget {
  const MyWallpapersScreen({super.key});

  @override
  State<MyWallpapersScreen> createState() => _MyWallpapersScreenState();
}

class WallhavenWallpapersScreen extends StatefulWidget {
  const WallhavenWallpapersScreen({super.key});

  @override
  State<WallhavenWallpapersScreen> createState() => _WallhavenWallpapersScreenState();
}

class WallpaperPreviewScreen extends StatefulWidget {
  final WallpaperConfig imageConfig;

  const WallpaperPreviewScreen({super.key, required this.imageConfig});

  @override
  State<WallpaperPreviewScreen> createState() => _WallpaperPreviewScreenState();
}

class _AnimatedImageListState extends State<AnimatedImageList> {
  int currentIndex = 0;
  Timer? timer;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: context.width,
      height: context.height,
      child: AnimatedSwitcher(
        duration: widget.fade,
        child: Image(
          key: ValueKey(currentIndex),
          image: widget.images[currentIndex],
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(widget.duration, (timer) {
      setState(() {
        currentIndex = (currentIndex + 1) % widget.images.length;
      });
      widget.onChange(widget.images[currentIndex]);
    });
  }
}

class _MyWallpapersScreenState extends State<MyWallpapersScreen> {
  AwaiterData<List<File>> walls = AwaiterData();
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final aspectRatio = size.width / size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.wallpaper),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {});
              Get.forceAppUpdate();
            },
          ),
          IconButton(
              onPressed: () {
                Get.to(() => const WallhavenWallpapersScreen());
              },
              icon: const Icon(FontAwesome.download_solid)),
          IconButton(
              onPressed: () async {
                final files = await FilePicker.platform.pickFiles(allowMultiple: true, type: FileType.image, withData: true, withReadStream: true);
                if (files != null) {
                  for (var file in files.files) {
                    var oldFile = File(file.path!);
                    if (await oldFile.exists()) {
                      final newFile = File('${wallpaperDir.path}/${file.name}'.fixPath);
                      await newFile.parent.create(recursive: true);
                      await oldFile.copy(newFile.path);
                    }
                  }
                }
                setState(() {});
                Get.forceAppUpdate();
              },
              icon: const Icon(Icons.download)),
        ],
      ),
      body: FutureAwaiter(
        future: () async => (await wallpaperFiles).toList(),
        data: walls,
        builder: (images) => GridView.builder(
          padding: const EdgeInsets.all(8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: aspectRatio,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: images.length,
          itemBuilder: (context, index) => LayoutBuilder(builder: (context, cs) {
            var file = images[index];
            var cfg = kwiqConfig.getWallpaperConfig(file.name);
            return GestureDetector(
              onTap: () async {
                await Get.to(() => WallpaperPreviewScreen(imageConfig: cfg));
                setState(() {
                  walls.expired = true;
                });
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image(
                    image: cfg.image,
                    fit: BoxFit.cover,
                    alignment: cfg.alignment,
                  ),
                  if (cfg.landscapeDarkMode || cfg.landscapeLightMode)
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Wrap(
                            children: [
                              if (cfg.landscapeDarkMode) const Icon(Icons.dark_mode),
                              if (cfg.landscapeLightMode) const Icon(Icons.light_mode),
                            ],
                          ),
                        ),
                      ),
                    )
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _WallhavenWallpapersScreenState extends State<WallhavenWallpapersScreen> {
  List<Wallpaper> wallpapers = [];
  bool isLoading = true;

  List<File> files = [];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final aspectRatio = size.width / size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.wallpaper),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWallpapers,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: aspectRatio,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: wallpapers.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _downloadWallpaper(wallpapers[index]),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        wallpapers[index].path,
                        fit: BoxFit.cover,
                      ),
                    ],
                  ),
                ).wrapIf(
                    files.any((x) => x.name.flatEqual(wallpapers[index].fileName)),
                    (x) => Badge(
                          label: loc.downloaded.asText(),
                          child: x,
                        ));
              },
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadWallpapers();
  }

  Future<void> _downloadWallpaper(Wallpaper image) async {
    await context.showTaskLoader(
      task: () async {
        var bytes = await image.download();
        var f = await File("${wallpaperDir.path}/${image.fileName}".fixPath).writeAsBytes(bytes);
        var wall = await WallpaperConfig.fromFile(f);
        wall!.colors = image.getColors().map((x) => WallpaperColor()..color = x).toList();
        kwiqConfig.save();
      },
      loadingText: loc.downloading,
    );
    setState(() {});
  }

  Future<void> _loadWallpapers([string query = ""]) async {
    final results = await WallhavenClient.searchWallpapers(query);
    files = (await wallpaperFiles).toList();
    setState(() {
      wallpapers = results.data;
      isLoading = false;
    });
  }
}

class _WallpaperPreviewScreenState extends State<WallpaperPreviewScreen> {
  WallpaperConfig get imageConfig => widget.imageConfig;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: context.theme.copyWith(
        primaryColor: imageConfig.accentColor,
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: context.colorScheme.surface.withValues(alpha: 0.5),
          title: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(loc.wallpaper),
              Text(imageConfig.portraitX.toString()).fontSize(10),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () {
                Share.shareXFiles([XFile(imageConfig.file.path)]);
              },
            ),
            IconButton(
              onPressed: () async {
                if (await context.confirm(loc.confirmDelete(loc.wallpaper))) {
                  imageConfig.delete();
                  kwiqConfig.save();
                  Get.back();
                }
              },
              icon: const Icon(Icons.delete),
            ),
          ],
        ),
        extendBody: true,
        extendBodyBehindAppBar: true,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {});
            kwiqConfig.save();
          },
          child: const Icon(FontAwesome.palette_solid),
        ),
        bottomNavigationBar: BottomAppBar(
          child: SizedBox(
            height: context.height * 0.1,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.light_mode),
                  onPressed: () {
                    setState(() {
                      imageConfig.landscapeLightMode = !imageConfig.landscapeLightMode;
                    });
                    kwiqConfig.save();
                  },
                  color: imageConfig.landscapeLightMode ? kwiqConfig.currentColor : null,
                ),
                IconButton(
                  icon: const Icon(Icons.dark_mode),
                  onPressed: () {
                    setState(() {
                      imageConfig.landscapeDarkMode = !imageConfig.landscapeDarkMode;
                    });
                    kwiqConfig.save();
                  },
                  color: imageConfig.landscapeDarkMode ? kwiqConfig.currentColor : null,
                ),
                IconButton(
                  icon: const Icon(Icons.rotate_left),
                  onPressed: () {
                    setState(() {
                      imageConfig.portraitX = 0;
                      imageConfig.portraitY = 0;
                    });
                    kwiqConfig.save();
                  },
                ),
              ],
            ),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image(
              image: imageConfig.image,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              alignment: imageConfig.alignment,
            ),
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (context.isLandscape)
                    SizedBox(
                      width: context.width,
                      child: Slider(
                        activeColor: kwiqConfig.currentColor,
                        value: imageConfig.portraitY,
                        min: -1.0,
                        max: 1.0,
                        onChanged: (value) {
                          setState(() {
                            imageConfig.portraitY = value;
                          });
                          kwiqConfig.save();
                        },
                      ),
                    )
                  else
                    SizedBox(
                      width: context.width,
                      child: Slider(
                        activeColor: kwiqConfig.currentColor,
                        value: imageConfig.portraitX,
                        min: -1.0,
                        max: 1.0,
                        onChanged: (value) {
                          setState(() {
                            imageConfig.portraitX = value;
                          });
                          kwiqConfig.save();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }
}
