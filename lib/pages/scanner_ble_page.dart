import 'package:flutter/material.dart';

class ScannerBluetoothPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Scanner Bluetooth')),
      body: Center(
        child: Text('Tela Scanner Bluetooth', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}
