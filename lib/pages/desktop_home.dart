import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Windows11MimicScreen extends StatefulWidget {
  @override
  _Windows11MimicScreenState createState() => _Windows11MimicScreenState();
}

class _Windows11MimicScreenState extends State<Windows11MimicScreen> {
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _currentTime = _formatDateTime(DateTime.now());
    // Atualiza o relógio a cada minuto
    Future.delayed(Duration(minutes: 1) - Duration(seconds: DateTime.now().second), _updateTime);
  }

  void _updateTime() {
    setState(() {
      _currentTime = _formatDateTime(DateTime.now());
    });
    Future.delayed(Duration(minutes: 1), _updateTime);
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('HH:mm\ndd/MM/yyyy').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Align(
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
                      icon: Icon(Icons.wb_sunny),
                      onPressed: () {},
                    ),
                  ],
                ),
                // Ícones no centro
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.android),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.folder_open),
                      onPressed: () {},
                    ),
                  ],
                ),
                // Ícones à direita
                Row(
                  children: [
                    Text(_currentTime, style: TextStyle(color: Colors.white)),
                    IconButton(
                      icon: Icon(Icons.notifications),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.wifi),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.volume_up),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.apps),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
