import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kwiq_launcher/components/digital_clock.dart';

class Windows11MimicScreen extends StatefulWidget {
  const Windows11MimicScreen({super.key});

  @override
  createState() => _Windows11MimicScreenState();
}

class _Windows11MimicScreenState extends State<Windows11MimicScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          color: Colors.grey[900],
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Ícones à esquerda
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.wb_sunny),
                    onPressed: () {},
                  ),
                ],
              ),
              // Ícones no centro
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.android),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: () {},
                  ),
                ],
              ),
              // Ícones à direita
              Row(
                children: [
                  const DigitalClock(
                      format: 'HH:mm:ss',
                      textStyle: TextStyle(
                        color: Colors.white,
                      )),
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.wifi),
                    onPressed: () {
                      SystemChannels.platform.invokeMethod('wifi.open');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.apps),
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
