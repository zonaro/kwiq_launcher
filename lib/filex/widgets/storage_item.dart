import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/filex/screens/folder/folder.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class StorageItem extends StatelessWidget {
  final double percent;
  final String title;
  final String path;
  final Color color;
  final IconData icon;
  final int usedSpace;
  final int totalSpace;

  const StorageItem({
    super.key,
    required this.percent,
    required this.title,
    required this.path,
    required this.color,
    required this.icon,
    required this.usedSpace,
    required this.totalSpace,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Get.to(() => Folder(title: title, path: path));
      },
      contentPadding: const EdgeInsets.only(right: 20),
      leading: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).dividerColor,
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(icon, color: color),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(title),
          Text(
            '${context.translations.storageUsed}: ${usedSpace.formatFileSize} '
            '/${totalSpace.formatFileSize}',
            style: TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 14.0,
              color: Theme.of(context).textTheme.displayLarge!.color,
            ),
          ),
        ],
      ),
      subtitle: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: LinearPercentIndicator(
          padding: const EdgeInsets.all(0),
          backgroundColor: Colors.grey[300],
          percent: percent,
          progressColor: color,
        ),
      ),
    );
  }
}
