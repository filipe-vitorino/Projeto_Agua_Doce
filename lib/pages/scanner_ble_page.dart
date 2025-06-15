import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../viewmodels/ble_connection_viewmodel.dart';
import 'ble_data_page.dart';

class ScannerBlePage extends StatefulWidget {
  const ScannerBlePage({super.key});

  @override
  State<ScannerBlePage> createState() => _ScannerBlePageState();
}

class _ScannerBlePageState extends State<ScannerBlePage> {
  List<ScanResult> _devices = [];
  String? _selectedDeviceName;
  BluetoothDevice? _selectedDevice;
  bool _isScanning = false;

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _isScanningSubscription;

  @override
  void initState() {
    super.initState();
    _startScanAndListen();
  }

  void _startScanAndListen() async {
    await _requestPermissionsAndScan();

    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      if (!mounted) return;
      setState(() {
        _devices = results;
      });
    });

    _isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      if (!mounted) return;
      setState(() {
        _isScanning = scanning;
      });
    });
  }

  Future<void> _requestPermissionsAndScan() async {
    await Permission.bluetoothScan.request();
    await Permission.location.request();

    if (!mounted) return;
    setState(() {
      _isScanning = true;
      _devices.clear();
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
  }

  Future<void> _showDeviceListDialog() async {
    if (_devices.isEmpty) {
      await _requestPermissionsAndScan();
      if (_devices.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhum dispositivo BLE encontrado')),
        );
        return;
      }
    }

    final selection = await showDialog<BluetoothDevice>(
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

    if (selection != null) {
      setState(() {
        _selectedDeviceName =
            selection.platformName.isNotEmpty
                ? selection.platformName
                : '(Sem nome)';
        _selectedDevice = selection;
      });

      // Pegue o viewmodel fora do dialog
      final viewModel = Provider.of<BleConnectionViewModel>(
        context,
        listen: false,
      );
      _showDeviceDialog(viewModel);
    }
  }

  Future<void> _showDeviceDialog(BleConnectionViewModel viewModel) async {
    bool connecting = false;
    bool connected = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                          _selectedDevice?.remoteId.str ?? '',
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
                        onPressed:
                            connecting
                                ? null
                                : () async {
                                  setStateDialog(() => connecting = true);
                                  await viewModel.connectToDevice(
                                    _selectedDevice!,
                                  );
                                  setStateDialog(() {
                                    connecting = false;
                                    connected = viewModel.connected;
                                  });
                                  // Feche o dialog primeiro
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  }
                                  if (!mounted) return;
                                  if (viewModel.connected) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BleDataPage(),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Falha ao conectar a $_selectedDeviceName',
                                        ),
                                      ),
                                    );
                                  }
                                },
                        child:
                            connecting
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('Conectar'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _isScanningSubscription?.cancel();
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
