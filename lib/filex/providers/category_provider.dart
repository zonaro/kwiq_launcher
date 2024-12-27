import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:isolate_handler/isolate_handler.dart';
import 'package:kwiq_launcher/filex/utils/utils.dart';
import 'package:kwiq_launcher/models/kwiq_config.dart';

class CategoryProvider extends ChangeNotifier {
  static List docExtensions = [
    '.pdf',
    '.epub',
    '.mobi',
    '.doc',
    '.docx',
    '.xls',
    '.xlsx',
    '.ppt',
    '.pptx',
    '.txt',
    '.rtf',
    '.odt',
    '.ods',
    '.odp',
    '.html',
    '.htm',
    '.xml',
    '.json',
    '.log',
    '.csv',
    '.sql',
    '.md',
  ];

  bool loading = false;
  List<FileSystemEntity> downloads = <FileSystemEntity>[];
  List<String> downloadTabs = <String>[];

  List<FileSystemEntity> images = <FileSystemEntity>[];
  List<String> imageTabs = <String>[];

  List<FileSystemEntity> file = <FileSystemEntity>[];
  List<String> fileTabs = <String>[];
  List<FileSystemEntity> currentFiles = [];

  bool showHidden = false;
  int sort = 0;
  final isolates = IsolateHandler();

  CategoryProvider() {
    getHidden();
  }

  getDownloads() async {
    setLoading(true);
    downloadTabs.clear();
    downloads.clear();
    downloadTabs.add('All');
    List<Directory> storages = await FileUtils.getStorageList();
    for (var dir in storages) {
      var downDir = Directory('${dir.path}//Download'.fixPath);
      if (downDir.existsSync()) {
        List<FileSystemEntity> files = downDir.listSync();
        consoleLog(files);
        for (var file in files) {
          if (FileSystemEntity.isFileSync(file.path)) {
            downloads.add(file);
            downloadTabs.add(file.path.split('/')[file.path.split('/').length - 2]);
            downloadTabs = downloadTabs.toSet().toList();
            notifyListeners();
          }
        }
      }
    }
    setLoading(false);
  }

  getFiles(String type) async {
    setLoading(true);
    fileTabs.clear();
    file.clear();
    fileTabs.add('All');
    String isolateName = type;
    isolates.spawn<String>(
      getAllFilesWithIsolate,
      name: isolateName,
      onReceive: (val) {
        isolates.kill(isolateName);
      },
      onInitialized: () => isolates.send('hey', to: isolateName),
    );
    ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, '${isolateName}_2');
    port.listen((files) async {
      List tabs = await compute(separateFiles, {'files': files, 'type': type});
      file = tabs[0];
      fileTabs = tabs[1];
      setLoading(false);
      port.close();
      IsolateNameServer.removePortNameMapping('${isolateName}_2');
    });
  }

  getHidden() async {
    bool h = kwiqConfig.showHidden;
    setHidden(h);
  }

  getImages(String type) async {
    setLoading(true);
    imageTabs.clear();
    images.clear();
    imageTabs.add('All');
    String isolateName = type;
    isolates.spawn<String>(
      getAllFilesWithIsolate,
      name: isolateName,
      onReceive: (val) {
        isolates.kill(isolateName);
      },
      onInitialized: () => isolates.send('hey', to: isolateName),
    );
    ReceivePort port = ReceivePort();
    IsolateNameServer.registerPortWithName(port.sendPort, '${isolateName}_2');
    port.listen((files) {
      files.forEach((file) {
        var f = file as File;
        if (f.mimeTypeType == type) {
          images.add(file);
          imageTabs.add(file.path.split('/')[file.path.split('/').length - 2]);
          imageTabs = imageTabs.toSet().toList();
        }
        notifyListeners();
      });
      currentFiles = images;
      setLoading(false);
      port.close();
      IsolateNameServer.removePortNameMapping('${isolateName}_2');
    });
  }

  getSort() async {
    int s = kwiqConfig.sort;
    sort = s;
    notifyListeners();
  }

  setHidden(value) async {
    kwiqConfig.showHidden = value;
    showHidden = value;
    kwiqConfig.save();
    notifyListeners();
  }

  void setLoading(value) {
    loading = value;
    notifyListeners();
  }

  setSort(int index) {
    kwiqConfig.sort = index;
    sort = index;
    kwiqConfig.save();
    notifyListeners();
  }

  switchCurrentFiles(List list, String label) async {
    List<FileSystemEntity> l = await compute(getTabImages, [list, label]);
    currentFiles = l;
    notifyListeners();
  }

  static getAllFilesWithIsolate(Map<String, dynamic> context) async {
    String isolateName = context['name'];
    List<FileSystemEntity> files = await FileUtils.getAllFiles(showHidden: false);
    final messenger = HandledIsolate.initialize(context);
    try {
      final SendPort? send = IsolateNameServer.lookupPortByName('${isolateName}_2');
      send!.send(files);
    } catch (e) {
      consoleLog(e);
    }
    messenger.send('done');
  }

  static Future<List<FileSystemEntity>> getTabImages(List item) async {
    List items = item[0];
    String label = item[1];
    List<FileSystemEntity> files = [];
    for (var file in items) {
      if ('${file.path.split('/')[file.path.split('/').length - 2]}' == label) {
        files.add(file);
      }
    }
    return files;
  }

  static Future<List> separateFiles(Map body) async {
    List files = body['files'];
    String type = body['type'];
    List<FileSystemEntity> ff = [];
    List<String> ffTabs = [];
    for (File file in files) {
      if (type == 'text' && docExtensions.contains(file.fileExtension)) {
        ff.add(file);
      }

      if (file.mimeTypeType == type) {
        ff.add(file);
        ffTabs.add(file.directoryName ?? Get.context!.translations.unknown);
        // ffTabs.add(file.path.split('/')[file.path.split('/').length - 2]);
        ffTabs = ffTabs.toSet().toList();
      }
    }
    return [ff, ffTabs];
  }
}
