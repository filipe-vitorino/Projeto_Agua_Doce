import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerBlePage extends StatefulWidget {
  const ScannerBlePage({super.key});

  @override
  State<ScannerBlePage> createState() => _ScannerBlePageState();
}

class _ScannerBlePageState extends State<ScannerBlePage> {
  List<ScanResult> _devices = [];
  String? _selectedDeviceName;
  String? _selectedDeviceId;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndScan();
  }

  Future<void> _requestPermissionsAndScan() async {
    await Permission.bluetoothScan.request();
    await Permission.location.request(); // Necessário no Android

    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        _devices = results;
      });
    });

    FlutterBluePlus.isScanning.listen((scanning) {
      setState(() {
        _isScanning = scanning;
      });
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  Future<void> _showDeviceListDialog() async {
    if (_devices.isEmpty) {
      await _requestPermissionsAndScan();
      if (_devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum dispositivo BLE encontrado')),
        );
        return;
      }
    }

    final selection = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const Text(
                  'Dispositivos BLE disponíveis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = _devices[index].device;
                    final name =
                        device.platformName.isNotEmpty
                            ? device.platformName
                            : '(Sem nome)';
                    return ListTile(
                      leading: const Icon(Icons.bluetooth, color: Colors.blue),
                      title: Text(name),
                      subtitle: Text(device.remoteId.str),
                      trailing: const Icon(
                        Icons.keyboard_arrow_right,
                        color: Colors.grey,
                      ),
                      onTap:
                          () => Navigator.pop(context, {
                            "name": name,
                            "id": device.remoteId.str,
                          }),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (selection != null) {
      setState(() {
        _selectedDeviceName = selection["name"];
        _selectedDeviceId = selection["id"];
      });
      _showDeviceDialog();
    }
  }

  Future<void> _showDeviceDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Text(
                  'Conectar em $_selectedDeviceName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      "ID do dispositivo:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedDeviceId ?? '',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
              ButtonBar(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _connectToDevice(_selectedDeviceId!);
                    },
                    child: const Text('Conectar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _connectToDevice(String deviceId) async {
    final device =
        _devices.firstWhere((r) => r.device.remoteId.str == deviceId).device;
    bool success = false;
    try {
      await device.connect(timeout: const Duration(seconds: 10));
      success = true;
    } catch (e) {
      success = false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Conectado com sucesso a $_selectedDeviceName'
              : 'Falha ao conectar a $_selectedDeviceName',
        ),
      ),
    );
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conectar BLE')),
      body: Center(
        child: ElevatedButton(
          onPressed: _showDeviceListDialog,
          child: const Text('Escolher Dispositivo BLE'),
        ),
      ),
    );
  }
}
