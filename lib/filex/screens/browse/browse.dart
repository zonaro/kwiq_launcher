import 'dart:io';

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/filex/providers/core_provider.dart';
import 'package:kwiq_launcher/filex/screens/category.dart';
import 'package:kwiq_launcher/filex/screens/downloads.dart';
import 'package:kwiq_launcher/filex/screens/images.dart';
import 'package:kwiq_launcher/filex/screens/whatsapp_status.dart';
import 'package:kwiq_launcher/filex/utils/utils.dart';
import 'package:kwiq_launcher/filex/widgets/widgets.dart';
import 'package:provider/provider.dart';

class FilesPage extends StatelessWidget {
  const FilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => refresh(context),
      child: ListView(
        padding: const EdgeInsets.only(left: 20.0),
        children: <Widget>[
          const SizedBox(height: 20.0),
          _SectionTitle(context.translations.storageDevices),
          _StorageSection(),
          const Divider(),
          const SizedBox(height: 20.0),
          _SectionTitle(context.translations.categories),
          _CategoriesSection(),
          const Divider(),
          const SizedBox(height: 20.0),
          _SectionTitle(context.translations.recentItems(context.translations.files)),
          _RecentFiles(),
        ],
      ),
    );
  }

  refresh(BuildContext context) async {
    await Provider.of<CoreProvider>(context, listen: false).checkSpace();
  }
}

class _CategoriesSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: Constants.categories.length,
      itemBuilder: (BuildContext context, int index) {
        Map category = Constants.categories[index];

        return ListTile(
          onTap: () {
            if (index == Constants.categories.length - 1) {
              // Check if the user has whatsapp installed
              if (Directory(FileUtils.waPath).existsSync()) {
                Get.to(() => WhatsappStatus(title: '${category['title']}'));
              } else {
                context.showSnackBar('Please Install WhatsApp to use this feature');
              }
            } else if (index == 0) {
              Get.to(() => Downloads(title: '${category['title']}'));
            } else {
              Get.to(() => index == 1 || index == 2 ? Images(title: '${category['title']}') : Category(title: '${category['title']}'));
            }
          },
          contentPadding: const EdgeInsets.all(0),
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
            child: Icon(category['icon'], size: 18, color: category['color']),
          ),
          title: Text('${category['title']}'),
        );
      },
      separatorBuilder: (BuildContext context, int index) {
        return const Divider();
      },
    );
  }
}

class _RecentFiles extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CoreProvider>(
      builder: (BuildContext context, coreProvider, Widget? child) {
        if (coreProvider.recentLoading) {
          return const SizedBox(height: 150, child: CustomLoader());
        }
        return ListView.separated(
          padding: const EdgeInsets.only(right: 20),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: coreProvider.recentFiles.length > 5 ? 5 : coreProvider.recentFiles.length,
          itemBuilder: (BuildContext context, int index) {
            FileSystemEntity file = coreProvider.recentFiles[index];
            return file.existsSync() ? FileItem(file: file) : const SizedBox();
          },
          separatorBuilder: (BuildContext context, int index) {
            return Container(
              height: 1,
              color: Theme.of(context).dividerColor,
            );
          },
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12.0,
      ),
    );
  }
}

class _StorageSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CoreProvider>(
      builder: (BuildContext context, coreProvider, Widget? child) {
        if (coreProvider.storageLoading) {
          return const SizedBox(height: 100, child: CustomLoader());
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: coreProvider.availableStorage.length,
          itemBuilder: (BuildContext context, int index) {
            FileSystemEntity item = coreProvider.availableStorage[index];

            String path = item.path.split('Android')[0];
            double percent = 0;

            if (index == 0) {
              percent = calculatePercent(coreProvider.usedSpace, coreProvider.totalSpace);
            } else {
              percent = calculatePercent(coreProvider.usedSDSpace, coreProvider.totalSDSpace);
            }
            return StorageItem(
              percent: percent,
              path: path,
              title: index == 0 ? context.translations.device : context.translations.sdCard,
              icon: index == 0 ? Icons.smartphone : Icons.sd_storage,
              color: index == 0 ? Colors.lightBlue : Colors.orange,
              usedSpace: index == 0 ? coreProvider.usedSpace : coreProvider.usedSDSpace,
              totalSpace: index == 0 ? coreProvider.totalSpace : coreProvider.totalSDSpace,
            );
          },
          separatorBuilder: (BuildContext context, int index) => const Divider(),
        );
      },
    );
  }

  double calculatePercent(int usedSpace, int totalSpace) => usedSpace.percentOf(totalSpace);
}
