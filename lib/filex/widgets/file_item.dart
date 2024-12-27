import 'dart:io';

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/filex/widgets/file_icon.dart';
import 'package:kwiq_launcher/filex/widgets/file_popup.dart';
import 'package:open_file/open_file.dart';

class FileItem extends StatelessWidget {
  final FileSystemEntity file;
  final Function? popTap;

  const FileItem({
    super.key,
    required this.file,
    this.popTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => OpenFile.open(file.path),
      contentPadding: const EdgeInsets.all(0),
      leading: FileIcon(file: file),
      title: Text(
        file.name,
        style: const TextStyle(fontSize: 14),
        maxLines: 2,
      ),
      subtitle: Text(
        '${file.shortSize},'
        ' ${file.lastModified.format()}',
      ),
      trailing: popTap == null ? null : FilePopup(path: file.path, popTap: popTap!),
    );
  }
}
