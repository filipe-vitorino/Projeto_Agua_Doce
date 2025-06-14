import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class ScannerBluetoothPage extends StatefulWidget {
  const ScannerBluetoothPage({super.key});

  @override
  State<ScannerBluetoothPage> createState() => _ScannerBluetoothPageState();
}

class _ScannerBluetoothPageState extends State<ScannerBluetoothPage> {
  final _ble = FlutterReactiveBle();
  List<DiscoveredDevice> _devices = [];
  bool _scanning = false;
  DiscoveredDevice? _selectedDevice;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  void _startScan() {
    setState(() {
      _devices.clear();
      _scanning = true;
    });

    _ble
        .scanForDevices(withServices: [])
        .listen(
          (device) {
            if (!_devices.any((d) => d.id == device.id)) {
              setState(() {
                _devices.add(device);
              });
            }
          },
          onError: (error) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Erro ao escanear: $error')));
            setState(() {
              _scanning = false;
            });
          },
        );

    // Para o scan automaticamente após 10 segundos
    Future.delayed(const Duration(seconds: 10), () {
      _ble.deinitialize();
      setState(() {
        _scanning = false;
      });
    });
  }

  Future<void> _showDeviceListDialog() async {
    if (_devices.isEmpty) {
      _startScan();
      await Future.delayed(const Duration(seconds: 2));
      if (_devices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum dispositivo encontrado')),
        );
        return;
      }
    }

    final selected = await showDialog<DiscoveredDevice>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabeçalho colorido
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
                  'Dispositivos Bluetooth',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Lista de dispositivos
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _devices.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final device = _devices[index];
                    final name =
                        device.name.isNotEmpty ? device.name : '(Desconhecido)';
                    return ListTile(
                      leading: const Icon(Icons.bluetooth, color: Colors.blue),
                      title: Text(name),
                      subtitle: Text(device.id),
                      trailing: const Icon(
                        Icons.keyboard_arrow_right,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigator.pop(context, device),
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

    if (selected != null) {
      setState(() {
        _selectedDevice = selected;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Selecionado: ${selected.name.isNotEmpty ? selected.name : selected.id}',
          ),
        ),
      );

      // Aqui você pode implementar conexão, troca de dados, etc.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conectar Bluetooth')),
      body: Center(
        child: ElevatedButton(
          onPressed: _showDeviceListDialog,
          child: const Text('Escolher Dispositivo Bluetooth'),
        ),
      ),
    );
  }
}
