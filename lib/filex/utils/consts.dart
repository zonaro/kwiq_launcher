import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';

class Constants {
  static List categories = [
    {'title': 'Downloads', 'icon': Icons.download, 'path': '', 'color': Colors.purple},
    {'title': 'Images', 'icon': Icons.image, 'path': '', 'color': Colors.blue},
    {'title': 'Videos', 'icon': FontAwesome.file_video, 'path': '', 'color': Colors.red},
    {'title': 'Audio', 'icon': Icons.headphones, 'path': '', 'color': Colors.teal},
    {'title': 'Documents & Others', 'icon': FontAwesome.file, 'path': '', 'color': Colors.pink},
    {'title': 'Whatsapp Statuses', 'icon': Bootstrap.whatsapp, 'path': '', 'color': Colors.green},
  ];

  static List sortList = [
    'File name (A to Z)',
    'File name (Z to A)',
    'Date (oldest first)',
    'Date (newest first)',
    'Size (largest first)',
    'Size (Smallest first)',
  ];

  static List<T> map<T>(List list, Function handler) {
    List<T> result = [];
    for (var i = 0; i < list.length; i++) {
      result.add(handler(i, list[i]));
    }

    return result;
  }
}
