import 'dart:io';

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/filex/utils/utils.dart';
import 'package:kwiq_launcher/filex/widgets/video_thumbnail.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart';

// ignore: must_be_immutable
class WhatsappStatus extends StatelessWidget {
  final String title;

  List<FileSystemEntity> files = Directory(FileUtils.waPath).listSync()..removeWhere((f) => f.isHidden);
  WhatsappStatus({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          SliverPadding(
            padding: const EdgeInsets.all(10.0),
            sliver: SliverGrid.count(
              crossAxisSpacing: 5.0,
              mainAxisSpacing: 5.0,
              crossAxisCount: 2,
              children: Constants.map(
                files,
                (index, item) {
                  FileSystemEntity f = files[index];
                  String path = f.path;
                  File file = File(path);
                  String? mimeType = file.mimeType;
                  return mimeType.isNotBlank
                      ? const SizedBox()
                      : _WhatsAppItem(
                          file: file,
                          path: path,
                          mimeType: mimeType,
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhatsAppItem extends StatelessWidget {
  final File file;
  final String path;
  final String mimeType;

  const _WhatsAppItem({
    required this.file,
    required this.path,
    required this.mimeType,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => OpenFile.open(file.path),
      child: GridTile(
        header: Container(
          height: 50.0,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black54, Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    onPressed: () => saveMedia(),
                    icon: const Icon(
                      Icons.download,
                      color: Colors.white,
                      size: 16.0,
                    ),
                  ),
                  mimeType.split('/')[0] == 'video'
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              file.shortSize,
                              style: const TextStyle(fontSize: 12.0, color: Colors.white),
                            ),
                            const SizedBox(width: 5.0),
                            const Icon(
                              Icons.play_circle_filled,
                              color: Colors.white,
                              size: 16.0,
                            ),
                          ],
                        )
                      : Text(
                          file.shortSize,
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: Colors.white,
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
        child: mimeType.split('/')[0] == 'video'
            ? VideoThumbnail(path: path)
            : Image(
                fit: BoxFit.cover,
                errorBuilder: (b, o, c) {
                  return const Icon(Icons.image);
                },
                image: ResizeImage(
                  FileImage(File(file.path)),
                  width: 150,
                  height: 150,
                ),
              ),
      ),
    );
  }

  saveMedia() async {
    var d = await Directory('${appDir.path}/Whatsapp Status').create();
    await file.copy('${d.path}/${basename(path)}');
    Get.context!.showSnackBar(Get.context!.translations.saved);
  }
}
