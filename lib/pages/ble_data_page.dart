import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../viewmodels/ble_connection_viewmodel.dart';

class BleDataPage extends StatelessWidget {
  Future<void> _showUuidsDialog(
    BuildContext context,
    BluetoothDevice device,
  ) async {
    String uuidsText = "Buscando UUIDs...";
    try {
      List<BluetoothService> services = await device.discoverServices();
      final buffer = StringBuffer();
      for (var service in services) {
        buffer.writeln('Service UUID: ${service.uuid}');
        for (var char in service.characteristics) {
          buffer.writeln('  Characteristic UUID: ${char.uuid}');
          buffer.writeln('    Properties: ${char.properties}');
        }
      }
      uuidsText =
          buffer.toString().isNotEmpty
              ? buffer.toString()
              : "Nenhum serviço encontrado.";
    } catch (e) {
      uuidsText = "Erro ao buscar UUIDs: $e";
    }
    // ignore: use_build_context_synchronously
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('UUIDs encontrados'),
            content: SingleChildScrollView(child: SelectableText(uuidsText)),
            actions: [
              TextButton(
                child: const Text("Fechar"),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BleConnectionViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Leitura de Dados BLE'),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final localContext = context;
                  await viewModel.disconnect();
                  if (Navigator.of(localContext).canPop()) {
                    Navigator.of(localContext).pop();
                  }
                },
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed:
                      viewModel.connected
                          ? () => viewModel.readDataFromDevice()
                          : null,
                  child: const Text('Receber Dados'),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  icon: const Icon(Icons.list),
                  label: const Text('Listar UUIDs'),
                  onPressed:
                      viewModel.connected && viewModel.connectedDevice != null
                          ? () => _showUuidsDialog(
                            context,
                            viewModel.connectedDevice!,
                          )
                          : null,
                ),
                const SizedBox(height: 20),
                Text(
                  'Dados Recebidos:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  viewModel.data,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
