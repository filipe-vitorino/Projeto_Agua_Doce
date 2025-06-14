import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_iot/wifi_iot.dart';

class ScannerWifiPage extends StatefulWidget {
  const ScannerWifiPage({super.key});

  @override
  State<ScannerWifiPage> createState() => _ScannerWifiPage();
}

class _ScannerWifiPage extends State<ScannerWifiPage> {
  List<WiFiAccessPoint> _networks = [];
  String? _selectedSSID;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissionsAndScan();
  }

  Future<void> _requestPermissionsAndScan() async {
    await Permission.location.request();

    final canScan = await WiFiScan.instance.canStartScan();
    if (canScan == CanStartScan.yes) {
      await WiFiScan.instance.startScan();
      final results = await WiFiScan.instance.getScannedResults();
      setState(() {
        _networks = results;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível escanear Wi-Fi: $canScan')),
      );
    }
  }

  Future<void> _showNetworkListDialog() async {
    if (_networks.isEmpty) {
      await _requestPermissionsAndScan();
      if (_networks.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nenhuma rede Wi-Fi encontrada')),
        );
        return;
      }
    }

    final ssid = await showDialog<String>(
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
                  'Redes Wi-Fi disponíveis',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Lista de redes
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _networks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final ap = _networks[index];
                    final ssid = ap.ssid.isNotEmpty ? ap.ssid : '(Sem nome)';
                    return ListTile(
                      leading: const Icon(Icons.wifi, color: Colors.blue),
                      title: Text(ssid),
                      trailing: const Icon(
                        Icons.keyboard_arrow_right,
                        color: Colors.grey,
                      ),
                      onTap: () => Navigator.pop(context, ssid),
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

    if (ssid != null) {
      setState(() {
        _selectedSSID = ssid;
      });
      _showPasswordDialog();
    }
  }

  Future<void> _showPasswordDialog() async {
    _passwordController.clear();

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
                child: Text(
                  'Conectar em $_selectedSSID',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Campo de senha
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                ),
              ),

              // Botões
              ButtonBar(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final password = _passwordController.text;
                      if (password.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Informe a senha')),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      await _connectToWiFi(_selectedSSID!, password);
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

  Future<void> _connectToWiFi(String ssid, String password) async {
    bool success = false;
    try {
      success = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA,
        joinOnce: true,
      );
    } catch (e) {
      success = false;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Conectado com sucesso a $ssid'
              : 'Falha ao conectar a $ssid',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conectar Wi-Fi')),
      body: Center(
        child: ElevatedButton(
          onPressed: _showNetworkListDialog,
          child: const Text('Escolher Rede Wi-Fi'),
        ),
      ),
    );
  }
}
