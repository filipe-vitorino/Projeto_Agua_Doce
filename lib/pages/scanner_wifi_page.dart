import 'package:flutter/material.dart';

class ScannerWifiPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scanner WiFi')),
      body: Center(
        child: Text('Tela Scanner WiFi', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
