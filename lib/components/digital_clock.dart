import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';

class DigitalClock extends StatefulWidget {
  const DigitalClock({super.key, this.textStyle});

  final TextStyle? textStyle;
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
    final String formattedDateTime = now.format('HH:mm:ss');
    setState(() {
      _timeString = formattedDateTime;
    });
  }

  void _openClock() async {
    bool isInstalled = await DeviceApps.isAppInstalled('com.android.deskclock');
    if (isInstalled) {
      DeviceApps.openApp('com.android.deskclock');
    } else {
      isInstalled = await DeviceApps.isAppInstalled('com.google.android.deskclock');
      if (isInstalled) {
        DeviceApps.openApp('com.google.android.deskclock');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: GestureDetector(
        onTap: _openClock,
        child: AutoSizeText(
          maxLines: 1,
          _timeString,
          style: widget.textStyle,
        ),
      ),
    );
  }
}
