import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Importando as páginas
import 'pages/scanner_ble_page.dart';
import 'pages/scanner_wifi_page.dart';
import 'pages/ver_dados_page.dart';
import 'pages/graficos_page.dart';
import 'package:pad_scanner/viewmodels/ble_connection_viewmodel.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => BleConnectionViewModel(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menu Principal',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MainMenuPage(),
    );
  }
}

class MainMenuPage extends StatelessWidget {
  final List<_MenuItem> menuItems = [
    _MenuItem(
      'Scanner Bluetooth',
      Icons.bluetooth,
      Colors.blue,
      ScannerBlePage(),
    ),
    _MenuItem('Scanner WiFi', Icons.wifi, Colors.orange, ScannerWifiPage()),
    _MenuItem('Ver Dados', Icons.storage, Colors.green, VerDadosPage()),
    _MenuItem('Gráficos', Icons.show_chart, Colors.purple, GraficosPage()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Menu Principal'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children:
              menuItems.map((item) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => item.page),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(item.icon, size: 64, color: item.color),
                        SizedBox(height: 16),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: item.color.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final MaterialColor color;
  final Widget page;

  _MenuItem(this.title, this.icon, this.color, this.page);
}
