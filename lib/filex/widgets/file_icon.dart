import 'dart:io';

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/filex/widgets/video_thumbnail.dart';

class FileIcon extends StatelessWidget {
  final FileSystemEntity file;

  const FileIcon({
    super.key,
    required this.file,
  });

  @override
  Widget build(BuildContext context) {
    File f = File(file.path);
    String extension = f.fileExtension.toLowerCase();
    String mimeType = f.mimeType.toLowerCase();
    String type = mimeType.isEmpty ? '' : mimeType.split('/')[0];
    if (extension == '.apk') {
      return const Icon(Icons.android, color: Colors.green);
    } else if (extension == '.crdownload') {
      return const Icon(Icons.download, color: Colors.lightBlue);
    } else if (extension == '.zip' || extension.contains('tar')) {
      return const Icon(Icons.archive);
    } else if (extension == '.epub' || extension == '.pdf' || extension == '.mobi') {
      return const Icon(FontAwesome.file_code, color: Colors.orangeAccent);
    } else {
      switch (type) {
        case 'image':
          return SizedBox(
            width: 50,
            height: 50,
            child: Image(
              errorBuilder: (b, o, c) {
                return const Icon(Icons.image);
              },
              image: ResizeImage(FileImage(File(file.path)), width: 50, height: 50),
            ),
          );
        case 'video':
          return SizedBox(
            height: 40,
            width: 40,
            child: VideoThumbnail(
              path: file.path,
            ),
          );
        case 'audio':
          return const Icon(FontAwesome.file_audio, color: Colors.blue);
        case 'text':
          return const Icon(FontAwesome.file_code, color: Colors.orangeAccent);
        default:
          return const Icon(FontAwesome.file);
      }
    }
  }
}
