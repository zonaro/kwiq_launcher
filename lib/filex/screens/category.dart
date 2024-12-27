import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/filex/providers/category_provider.dart';
import 'package:kwiq_launcher/filex/utils/utils.dart';
import 'package:kwiq_launcher/filex/widgets/widgets.dart';
import 'package:provider/provider.dart';

class Category extends StatefulWidget {
  final String title;

  const Category({
    super.key,
    required this.title,
  });

  @override
  createState() => _CategoryState();
}

class _CategoryState extends State<Category> {
  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, CategoryProvider provider, Widget? child) {
        return provider.loading
            ? const Scaffold(body: CustomLoader())
            : DefaultTabController(
                length: provider.fileTabs.length,
                child: Scaffold(
                  appBar: AppBar(
                    title: Text(widget.title),
                    bottom: TabBar(
                      indicatorColor: Theme.of(context).colorScheme.secondary,
                      labelColor: Theme.of(context).colorScheme.secondary,
                      unselectedLabelColor: Theme.of(context).textTheme.bodySmall!.color,
                      isScrollable: provider.fileTabs.length < 3 ? false : true,
                      tabs: Constants.map<Widget>(
                        provider.fileTabs,
                        (index, label) {
                          return Tab(text: '$label');
                        },
                      ),
                    ),
                  ),
                  body: provider.file.isEmpty
                      ? Center(child: Text(context.translations.couldNotFindItem(context.translations.files)))
                      : TabBarView(
                          children: Constants.map<Widget>(
                            provider.fileTabs,
                            (index, label) {
                              List list = [];
                              List items = provider.file;
                              for (var file in items) {
                                if ('${file.path.split('/')[file.path.split('/').length - 2]}' == label) {
                                  list.add(file);
                                }
                              }
                              // print(label);
                              return ListView.separated(
                                padding: const EdgeInsets.only(left: 20),
                                itemCount: index == 0 ? provider.file.length : list.length,
                                itemBuilder: (BuildContext context, int index2) {
                                  FileSystemEntity file = index == 0 ? provider.file[index2] : list[index2];
                                  return FileItem(file: file);
                                },
                                separatorBuilder: (BuildContext context, int index) => const Divider(),
                              );
                            },
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
      switch (widget.title.toLowerCase()) {
        case 'audio':
          Provider.of<CategoryProvider>(context, listen: false).getFiles('audio');
          break;
        case 'documents & others':
          Provider.of<CategoryProvider>(context, listen: false).getFiles('text');
      }
    });
  }
}
