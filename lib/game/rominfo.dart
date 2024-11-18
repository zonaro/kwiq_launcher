import 'dart:io';

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';

class RomInfo {
  String filePath;

  String platform;

  String? coverFile;

  RomInfo({required this.filePath, required this.platform});

  Image? get cover => coverFile != null && File(coverFile!).existsSync() ? Image.file(File(coverFile!)) : null;

  File get file => File(filePath);

  int get id => file.hashCode;

  String get initials => name.split(" ").map((e) => e.toUpperCase().first).join();

  String get name => file.nameWithoutExtension;
}
