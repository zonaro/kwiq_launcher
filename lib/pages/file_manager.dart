// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/constants.dart';
import 'package:kwiq_launcher/components/file_controller.dart';
import 'package:kwiq_launcher/components/widgets.dart';
import 'package:kwiq_launcher/models/kwiq_config.dart';
import 'package:open_file/open_file.dart';

class FilePage extends StatefulWidget {
  const FilePage({super.key});

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  var gotPermission = false;
  var isMoving = false;
  var hideDetails = false;

  final FilesController fileController = Get.put(FilesController());
  late FileSystemEntity selectedFile;

  AppBar appBar(BuildContext context) {
    return AppBar(
      actions: [
        Visibility(
            visible: isMoving,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () {
                  selectedFile.rename("${fileController.controller.getCurrentPath}/${FileManager.basename(selectedFile)}");
                  setState(() {
                    isMoving = false;
                  });
                },
                child: const Row(
                  children: [
                    Text("Move here ", style: TextStyle(fontWeight: FontWeight.w500)),
                    Icon(Icons.paste),
                  ],
                ),
              ),
            )),
        Visibility(
          visible: !isMoving,
          child: PopupMenuButton(
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry>[
                  PopupMenuItem(
                    value: 'button1',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.file_present,
                          color: orage2,
                        ),
                        const Text("New File     "),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'button2',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.folder_open, color: kwiqConfig.currentColor),
                        const Text("New Folder"),
                      ],
                    ),
                  ),
                ];
              },
              onSelected: (value) {
                switch (value) {
                  case 'button1':
                    fileController.createFile(context, fileController.controller.getCurrentPath);

                    break;
                  case 'button2':
                    fileController.createFolder(context);

                    break;
                }
              },
              child: const Icon(Icons.create_new_folder_outlined)),
        ),
        Visibility(
          visible: !isMoving,
          child: IconButton(
            onPressed: () => fileController.sort(context),
            icon: const Icon(Icons.sort_rounded),
          ),
        ),
      ],
      title: const Text("File Manager", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          await fileController.controller.goToParentDirectory().then((value) {
            if (fileController.controller.getCurrentPath == "/storage/emulated/0") {
              hideDetails = false;
              setState(() {});
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ControlBackButton(
      controller: fileController.controller,
      child: PopScope(
        onPopInvokedWithResult: (d, r) async {
          if (await fileController.controller.isRootDirectory()) {
            context.pop();
          }
        },
        child: Scaffold(
          body: FileManager(
            controller: fileController.controller,
            builder: (context, snapshot) {
              fileController.calculateSize(snapshot);

              final List<FileSystemEntity> entities = snapshot.where((element) => element.path != '/storage/emulated/0/Android').toList();
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Visibility(
                        visible: !hideDetails,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                              child: storagePercentWidget(fileController.deviceTotalSize.toInt(), fileController.deviceAvailableSize.toInt()),
                            ),
                            SizedBox(
                              height: 20,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                children: [
                                  if (fileController.documentSize > 0) fileTypeWidget("Document", "${fileController.documentSize.toStringAsFixed(2)} MB", Icons.folder),
                                  if (fileController.videoSize > 0) fileTypeWidget("Videos", "${fileController.videoSize.toStringAsFixed(2)} MB", Icons.video_camera_front),
                                  if (fileController.imageSize > 0) fileTypeWidget("Images", "${fileController.imageSize.toStringAsFixed(2)} MB", Icons.image),
                                  if (fileController.soundSize > 0) fileTypeWidget("Music", "${fileController.soundSize.toStringAsFixed(2)} MB", Icons.library_music),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Recent Files",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      )),
                                  InkWell(
                                    onTap: () {
                                      hideDetails = true;
                                      setState(() {});
                                    },
                                    child: const Text(
                                      "See All",
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ],
                        )),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 0),
                        itemCount: entities.length,
                        itemBuilder: (context, index) {
                          FileSystemEntity entity = entities[index];
                          return fileTile(entity, context);
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Ink fileTile(FileSystemEntity entity, BuildContext context) {
    return Ink(
      color: Colors.transparent,
      child: ListTile(
        trailing: PopupMenuButton(
            itemBuilder: (BuildContext context) {
              return <PopupMenuEntry>[
                PopupMenuItem(
                  value: 'button0',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.play_arrow, color: kwiqConfig.currentColor),
                      const Text("Open"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'button1',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.delete, color: kwiqConfig.currentColor),
                      const Text("Delete"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'button2',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.rotate_left_sharp, color: kwiqConfig.currentColor),
                      const Text("Rename"),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'button3',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.move_down_rounded, color: black),
                      const Text("Move"),
                    ],
                  ),
                )
              ];
            },
            onSelected: (value) async {
              switch (value) {
                case 'button0':
                  await openEntity(entity, context);

                  break;
                case 'button1':
                  if (FileManager.isDirectory(entity)) {
                    await entity.delete(recursive: true).then((value) {
                      setState(() {});
                    });
                  } else {
                    await entity.delete().then((value) {
                      setState(() {});
                    });
                  }

                  break;
                case 'button2':
                  showDialog(
                    context: context,
                    builder: (context) {
                      TextEditingController renameController = TextEditingController();
                      return AlertDialog(
                        title: Text("Rename ${FileManager.basename(entity)}"),
                        content: TextField(
                          controller: renameController,
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () async {
                              await entity
                                  .rename(
                                "${fileController.controller.getCurrentPath}/${renameController.text.trim()}",
                              )
                                  .then((value) {
                                Navigator.pop(context);
                                setState(() {});
                              });
                            },
                            child: const Text("Rename"),
                          ),
                        ],
                      );
                    },
                  );

                  break;
                case 'button3':
                  selectedFile = entity;
                  setState(() {
                    isMoving = true;
                  });
                  break;
              }
            },
            child: const Icon(Icons.more_vert)),
        leading: FileManager.isFile(entity)
            ? Card(
                color: kwiqConfig.currentColor,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icons.copy.asIcon(),
                ),
              )
            : Card(
                color: kwiqConfig.currentColor,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icons.folder.asIcon(),
                ),
              ),
        title: Text(
          FileManager.basename(
            entity,
            showFileExtension: true,
          ),
          style: const TextStyle(
            fontStyle: FontStyle.italic,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: entity.asText(),
        onTap: () async => await openEntity(entity, context),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> openEntity(FileSystemEntity entity, BuildContext context) async {
    if (FileManager.isDirectory(entity)) {
      try {
        fileController.controller.openDirectory(entity);
      } catch (e) {
        fileController.alert(context, "Enable to open this folder");
      }
    } else {
      await context.showTaskLoader(
        loadingText: "Opening ${FileManager.basename(entity)}",
        task: () async {
          await Future.delayed(1.seconds);
          return await OpenFile.open(entity.path);
        },
        onError: (e) => fileController.alert(context, "Enable to open this file"),
      );
    }
  }
}
