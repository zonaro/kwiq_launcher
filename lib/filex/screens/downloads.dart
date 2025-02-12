import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/filex/providers/category_provider.dart';
import 'package:kwiq_launcher/filex/utils/utils.dart';
import 'package:kwiq_launcher/filex/widgets/file_item.dart';
import 'package:provider/provider.dart';

class Downloads extends StatefulWidget {
  final String title;

  const Downloads({
    super.key,
    required this.title,
  });

  @override
  createState() => _DownloadsState();
}

class _DownloadsState extends State<Downloads> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, CategoryProvider provider, Widget? child) {
        return DefaultTabController(
          length: provider.downloadTabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(widget.title),
              bottom: TabBar(
                indicatorColor: Theme.of(context).colorScheme.secondary,
                labelColor: Theme.of(context).colorScheme.secondary,
                unselectedLabelColor: Theme.of(context).textTheme.bodySmall!.color,
                isScrollable: false,
                tabs: Constants.map<Widget>(
                  provider.downloadTabs,
                  (index, label) {
                    return Tab(text: '$label');
                  },
                ),
              ),
            ),
            body: Visibility(
              visible: provider.downloads.isNotEmpty,
              replacement: Center(child: Text(context.translations.itemNotFound(context.translations.files))),
              child: TabBarView(
                children: Constants.map<Widget>(
                  provider.downloadTabs,
                  (index, label) {
                    return ListView.separated(
                      padding: const EdgeInsets.only(left: 20),
                      itemCount: provider.downloads.length,
                      itemBuilder: (BuildContext context, int index) {
                        return FileItem(file: provider.downloads[index]);
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return const Divider();
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).getDownloads();
    });
  }
}
