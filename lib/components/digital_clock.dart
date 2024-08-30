import 'dart:async';

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:installed_apps/installed_apps.dart';

class DigitalClock extends StatefulWidget {
  const DigitalClock({super.key, this.textStyle, this.format = 'HH:mm:ss'});

  final TextStyle? textStyle;

  final string format;
  @override
  createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  String _timeString = "";

  @override
  void initState() {
    _getTime();
    Timer.periodic(1.seconds, (Timer t) => _getTime());
    super.initState();
  }

  void _getTime() {
    setState(() {
      _timeString = now.format(widget.format);
    });
  }

  void _openClock() async {
    if (await InstalledApps.isAppInstalled('com.android.deskclock') == true) {
      InstalledApps.startApp('com.android.deskclock');
    } else {
      if (await InstalledApps.isAppInstalled('com.google.android.deskclock') == true) {
        InstalledApps.startApp('com.google.android.deskclock');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openClock,
      child: Text(
        maxLines: 1,
        _timeString,
        style: widget.textStyle,
      ),
    );
  }
}
