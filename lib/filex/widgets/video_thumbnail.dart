import 'dart:io';

import 'package:flutter/material.dart';
import 'package:kwiq_launcher/filex/widgets/file_icon.dart';
import 'package:video_player/video_player.dart';

class VideoThumbnail extends StatefulWidget {
  final String path;

  const VideoThumbnail({
    super.key,
    required this.path,
  });

  @override
  createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<VideoThumbnail> with AutomaticKeepAliveClientMixin {
  String thumb = '';
  bool loading = true;
  late VideoPlayerController _controller;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return loading ? FileIcon(file: File(widget.path)) : VideoPlayer(_controller);
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            loading = false;
          }); //when your thumbnail will show.
        }
      });
  }
}
