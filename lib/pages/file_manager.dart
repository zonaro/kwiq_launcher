// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/components/constants.dart';
import 'package:kwiq_launcher/components/file_controller.dart';
import 'package:kwiq_launcher/components/widgets.dart';
import 'package:kwiq_launcher/main.dart';
import 'package:open_file/open_file.dart';
import 'package:sizer/sizer.dart';

final FilesController fileController = Get.put(FilesController());

class FilePage extends StatefulWidget {
  const FilePage({super.key});

  @override
  State<FilePage> createState() => _FilePageState();
}

class _FilePageState extends State<FilePage> {
  String searchQuery = '';
  var gotPermission = false;
  var isMoving = false;
  var fullScreen = false;
  var isSearching = false;
  late FileSystemEntity selectedFile;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ControlBackButton(
      controller: fileController.controller,
      child: PopScope(
        onPopInvoked: (d) async {
          if (await fileController.controller.isRootDirectory()) {
            context.pop();
          }
        },
        child: FileManager(
          controller: fileController.controller,
          builder: (context, snapshot) {
            fileController.calculateSize(snapshot);

            final List<FileSystemEntity> entities = isSearching ? snapshot.where((element) => element.path.flatContains(searchQuery)).toList() : snapshot.where((element) => element.path != '/storage/emulated/0/Android').toList();
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Visibility(
                      visible: !fullScreen,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: SizedBox(
                              height: 7.5.h,
                              child: TextField(
                                onChanged: (value) {
                                  setState(() {
                                    isSearching = true;
                                    searchQuery = value;
                                    if (searchQuery.isBlank) {
                                      isSearching = false;
                                    }
                                  });
                                },
                                decoration: InputDecoration(
                                  suffixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.grey[200],
                                  hintText: 'Search Files',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16.0),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 20.h,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                fileTypeWidget("Document", "${fileController.documentSize.toStringAsFixed(2)} MB", Icons.folder, orange),
                                fileTypeWidget("Videos", "${fileController.videoSize.toStringAsFixed(2)} MB", Icons.video_camera_front, mainColor),
                                fileTypeWidget("Images", "${fileController.imageSize.toStringAsFixed(2)} MB", Icons.image, black),
                                fileTypeWidget("Music", "${fileController.soundSize.toStringAsFixed(2)} MB", Icons.library_music, orange),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                            child: storagePercentWidget(fileController.deviceTotalSize.toInt(), fileController.deviceAvailableSize.toInt()),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Recent Files",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    )),
                                InkWell(
                                  onTap: () {
                                    fullScreen = true;
                                    setState(() {});
                                  },
                                  child: Text(
                                    "See All",
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10.sp,
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
                                          Icon(Icons.play_arrow, color: orange),
                                          const Text("Open"),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'button1',
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.delete, color: orange),
                                          const Text("Delete"),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'button2',
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(Icons.rotate_left_sharp, color: mainColor),
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
                                      if (FileManager.isDirectory(entity)) {
                                        try {
                                          fileController.controller.openDirectory(entity);
                                        } catch (e) {
                                          fileController.alert(context, "Enable to open this folder");
                                        }
                                      } else {
                                        try {
                                          await OpenFile.open(entity.path);
                                        } catch (e) {
                                          fileController.alert(context, "Enable to open this file");
                                        }
                                      }

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
                                    color: mainColor,
                                    elevation: 0,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Icons.copy.asIcon(),
                                    ),
                                  )
                                : Card(
                                    color: orange,
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
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: entity.asText(),
                            onTap: () async {
                              if (FileManager.isDirectory(entity)) {
                                try {
                                  fileController.controller.openDirectory(entity);
                                } catch (e) {
                                  fileController.alert(context, "Enable to open this folder");
                                }
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

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
                        Icon(Icons.folder_open, color: orange),
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
              fullScreen = false;
              setState(() {});
            }
          });
        },
      ),
    );
  }
}
