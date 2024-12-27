import 'package:flutter/material.dart';

class FilePopup extends StatelessWidget {
  final String path;
  final Function popTap;

  const FilePopup({
    super.key,
    required this.path,
    required this.popTap,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: (val) => popTap(val),
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0, child: Text('Rename')),
        const PopupMenuItem(value: 1, child: Text('Delete')),
      ],
      icon: Icon(
        Icons.arrow_drop_down,
        color: Theme.of(context).textTheme.titleLarge!.color,
      ),
      color: Theme.of(context).scaffoldBackgroundColor,
      offset: const Offset(0, 30),
    );
  }
}
