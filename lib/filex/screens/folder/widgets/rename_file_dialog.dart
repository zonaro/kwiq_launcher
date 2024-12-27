import 'dart:io';

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:kwiq_launcher/filex/widgets/widgets.dart';
import 'package:path/path.dart' as pathlib;

class RenameFileDialog extends StatefulWidget {
  final String path;
  final String type;

  const RenameFileDialog({super.key, required this.path, required this.type});

  @override
  createState() => _RenameFileDialogState();
}

class _RenameFileDialogState extends State<RenameFileDialog> {
  final TextEditingController name = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CustomAlert(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 15),
            const Text(
              'Rename Item',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 25),
            TextField(
              controller: name,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                SizedBox(
                  height: 40,
                  width: 130,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(Colors.white),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      side: WidgetStateProperty.all(
                        BorderSide(color: Theme.of(context).colorScheme.secondary),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  width: 130,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (name.text.isNotEmpty) {
                        if (widget.type == 'file') {
                          if (!File('${widget.path.replaceAll(pathlib.basename(widget.path), '')}${name.text}').existsSync()) {
                            await File(widget.path).rename('${widget.path.replaceAll(pathlib.basename(widget.path), '')}${name.text}');
                          } else {
                            context.showSnackBar('A File with that name already exists!');
                          }
                        } else {
                          if (Directory('${widget.path.replaceAll(pathlib.basename(widget.path), '')}${name.text}').existsSync()) {
                            context.showSnackBar('A Folder with that name already exists!');
                          } else {
                            await Directory(widget.path).rename('${widget.path.replaceAll(pathlib.basename(widget.path), '')}${name.text}');
                          }
                        }
                        Navigator.pop(context);
                      }
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(Theme.of(context).colorScheme.secondary),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ),
                    child: const Text(
                      'Rename',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    name.text = pathlib.basename(widget.path);
  }
}
