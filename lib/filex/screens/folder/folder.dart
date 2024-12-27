import 'dart:io';

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/filex/providers/category_provider.dart';
import 'package:kwiq_launcher/filex/screens/folder/widgets/widgets.dart';
import 'package:kwiq_launcher/filex/utils/utils.dart';
import 'package:kwiq_launcher/filex/widgets/widgets.dart';
import 'package:path/path.dart' as pathlib;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class Folder extends StatefulWidget {
  final String title;
  final String path;

  const Folder({
    super.key,
    required this.title,
    required this.path,
  });

  @override
  createState() => _FolderState();
}

class _FolderState extends State<Folder> with WidgetsBindingObserver {
  late String path;
  List<String> paths = <String>[];

  List<FileSystemEntity> files = <FileSystemEntity>[];
  bool showHidden = false;

  addDialog(BuildContext context, String path) async {
    await showDialog(
      context: context,
      builder: (context) => AddFileDialog(path: path),
    );
    getFiles();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: paths.length > 1,
      onPopInvokedWithResult: (didPop, result) async {
        if (paths.length != 1) {
          paths.removeLast();
          setState(() {
            path = paths.last;
          });
          getFiles();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (paths.length == 1) {
                Navigator.pop(context);
              } else {
                navigateBack();
              }
            },
          ),
          elevation: 4,
          title: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(widget.title),
              Text(
                path,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          bottom: PathBar(
            paths: paths,
            icon: widget.path.toString().contains('emulated') ? Icons.smartphone : Icons.sd_card,
            onChanged: (index) {
              path = paths[index];
              paths.removeRange(index + 1, paths.length);
              setState(() {});
              getFiles();
            },
          ),
          actions: <Widget>[
            IconButton(
              onPressed: () async {
                await showModalBottomSheet(
                  context: context,
                  builder: (context) => const SortSheet(),
                );
                getFiles();
              },
              tooltip: 'Sort by',
              icon: const Icon(Icons.sort),
            ),
          ],
        ),
        body: Visibility(
          replacement: const Center(child: Text('There\'s nothing here')),
          visible: files.isNotEmpty,
          child: ListView.separated(
            padding: const EdgeInsets.only(left: 20),
            itemCount: files.length,
            itemBuilder: (BuildContext context, int index) {
              FileSystemEntity file = files[index];
              if (file.toString().split(':')[0] == 'Directory') {
                return DirectoryItem(
                  popTap: (v) async {
                    if (v == 0) {
                      renameDialog(context, file.path, 'dir');
                    } else if (v == 1) {
                      deleteFile(true, file);
                    }
                  },
                  file: file,
                  tap: () {
                    paths.add(file.path);
                    path = file.path;
                    setState(() {});
                    getFiles();
                  },
                );
              }
              return FileItem(
                file: file,
                popTap: (v) async {
                  if (v == 0) {
                    renameDialog(context, file.path, 'file');
                  } else if (v == 1) {
                    deleteFile(false, file);
                  } else if (v == 2) {                
                    
                    Share.shareXFiles([XFile(file.path)]);
                    
                  }
                },
              );
            },
            separatorBuilder: (BuildContext context, int index) {
              return const Divider();
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => addDialog(context, path),
          tooltip: context.translations.addNewItem(context.translations.folder),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  deleteFile(bool directory, var file) async {
    try {
      if (directory) {
        await Directory(file.path).delete(recursive: true);
      } else {
        await File(file.path).delete(recursive: true);
      }
      context.showSnackBar(context.translations);
    } catch (e) {
      if (e.toString().contains('Permission denied')) {
        context.showSnackBar('Cannot write to this Storage device!');
      }
    }
    getFiles();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getFiles();
    }
  }

  @override
  void dispose() {
    super.dispose();
    WidgetsBinding.instance.removeObserver(this);
  }

  getFiles() async {
    try {
      var provider = Provider.of<CategoryProvider>(context, listen: false);
      Directory dir = Directory(path);
      List<FileSystemEntity> dirFiles = dir.listSync();
      files.clear();
      showHidden = provider.showHidden;
      setState(() {});
      for (FileSystemEntity file in dirFiles) {
        if (!showHidden) {
          if (!pathlib.basename(file.path).startsWith('.')) {
            files.add(file);
            setState(() {});
          }
        } else {
          files.add(file);
          setState(() {});
        }
      }

      files = FileUtils.sortList(files, provider.sort);
    } catch (e) {
      if (e.toString().contains('Permission denied')) {
        context.showSnackBar('Permission Denied! cannot access this Directory!');
        navigateBack();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    path = widget.path;
    getFiles();
    paths.add(widget.path);
    WidgetsBinding.instance.addObserver(this);
  }

  navigateBack() {
    paths.removeLast();
    path = paths.last;
    setState(() {});
    getFiles();
  }

  renameDialog(BuildContext context, String path, String type) async {
    await showDialog(
      context: context,
      builder: (context) => RenameFileDialog(path: path, type: type),
    );
    getFiles();
  }
}
