import 'dart:io';

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/filex/providers/category_provider.dart';
import 'package:kwiq_launcher/filex/screens/folder/folder.dart';
import 'package:kwiq_launcher/filex/utils/utils.dart';
import 'package:kwiq_launcher/filex/widgets/dir_item.dart';
import 'package:kwiq_launcher/filex/widgets/file_item.dart';
import 'package:provider/provider.dart';

class Search extends SearchDelegate {
  final ThemeData themeData;

  Search({
    Key? key,
    required this.themeData,
  });

  @override
  ThemeData appBarTheme(BuildContext context) {
    final ThemeData theme = themeData;
    return theme.copyWith(
      primaryTextTheme: theme.primaryTextTheme,
      textTheme: theme.textTheme.copyWith(
        displayLarge: theme.textTheme.displayLarge!.copyWith(
          color: theme.primaryTextTheme.titleLarge!.color,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(
          color: theme.primaryTextTheme.titleLarge!.color,
        ),
      ),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<FileSystemEntity>>(
      future: FileUtils.searchFiles(query, showHidden: Provider.of<CategoryProvider>(context, listen: false).showHidden),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isEmpty) {
            return const Center(child: Text('No file match your query!'));
          } else {
            return ListView.separated(
              padding: const EdgeInsets.only(left: 20),
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                FileSystemEntity file = snapshot.data[index];
                if (file.toString().split(':')[0] == 'Directory') {
                  return DirectoryItem(
                    popTap: null,
                    file: file,
                    tap: () {
                      Get.to(() => Folder(title: 'Storage', path: file.path));
                    },
                  );
                }
                return FileItem(file: file, popTap: null);
              },
              separatorBuilder: (BuildContext context, int index) {
                return Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        height: 1,
                        color: Theme.of(context).dividerColor,
                        width: MediaQuery.of(context).size.width - 70,
                      ),
                    ),
                  ],
                );
              },
            );
          }
        } else {
          return const SizedBox();
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    var provider = Provider.of<CategoryProvider>(context, listen: false);
    return FutureBuilder<List<FileSystemEntity>>(
      future: FileUtils.searchFiles(query, showHidden: provider.showHidden),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          if (snapshot.data.isEmpty) {
            return const Center(child: Text('No file match your query!'));
          } else {
            return ListView.separated(
              padding: const EdgeInsets.only(left: 20),
              itemCount: snapshot.data.length,
              itemBuilder: (BuildContext context, int index) {
                FileSystemEntity file = snapshot.data[index];
                if (file.toString().split(':')[0] == 'Directory') {
                  return DirectoryItem(
                    popTap: null,
                    file: file,
                    tap: () {
                      Get.to(
                        () => Folder(title: 'Storage', path: file.path),
                      );
                    },
                  );
                }
                return FileItem(file: file, popTap: null);
              },
              separatorBuilder: (BuildContext context, int index) {
                return Stack(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        height: 1,
                        color: Theme.of(context).dividerColor,
                        width: MediaQuery.of(context).size.width - 70,
                      ),
                    ),
                  ],
                );
              },
            );
          }
        } else {
          return const SizedBox();
        }
      },
    );
  }
}
