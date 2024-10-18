import 'dart:async';

import 'package:flutter/material.dart';
import 'package:innerlibs/innerlibs.dart';
import 'package:new_device_apps/device_apps.dart';

class DigitalClock extends StatefulWidget {
  final TextStyle? textStyle;

  final string format;

  const DigitalClock({super.key, this.textStyle, this.format = 'HH:mm:ss'});
  @override
  createState() => _DigitalClockState();
}

class _DigitalClockState extends State<DigitalClock> {
  String _timeString = "";

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

  @override
  void initState() {
    _getTime();
    Timer.periodic(1.seconds, (Timer t) => _getTime());
    super.initState();
  }

  void _getTime() {
    if (mounted) {
      setState(() {
        _timeString = now.format(widget.format);
      });
    }
  }

  void _openClock() async {
    if (await DeviceApps.isAppInstalled('com.android.deskclock')) {
      DeviceApps.openApp('com.android.deskclock');
    } else {
      if (await DeviceApps.isAppInstalled('com.google.android.deskclock')) {
        DeviceApps.openApp('com.google.android.deskclock');
      }
    }
  }
}
