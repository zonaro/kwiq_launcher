import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kwiq_launcher/filex/widgets/dir_popup.dart';
import 'package:path/path.dart';

class DirectoryItem extends StatelessWidget {
  final FileSystemEntity file;
  final Function tap;
  final Function? popTap;

  const DirectoryItem({
    super.key,
    required this.file,
    required this.tap,
    this.popTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => tap(),
      contentPadding: const EdgeInsets.all(0),
      leading: const SizedBox(
        height: 40,
        width: 40,
        child: Center(
          child: Icon(
            Icons.folder,
          ),
        ),
      ),
      title: Text(
        basename(file.path),
        style: const TextStyle(
          fontSize: 14,
        ),
        maxLines: 2,
      ),
      trailing: popTap == null
          ? null
          : DirPopup(
              path: file.path,
              popTap: popTap,
            ),
    );
  }
}
