import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BleConnectionViewModel extends ChangeNotifier {
  BluetoothDevice? _connectedDevice;
  bool _connecting = false;
  bool _connected = false;
  String _data = '';

  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get connecting => _connecting;
  bool get connected => _connected;
  String get data => _data;

  Future<void> connectToDevice(BluetoothDevice device) async {
    _connecting = true;
    _connected = false;
    _connectedDevice = device;
    _data = '';
    notifyListeners();

    try {
      await device.connect(timeout: const Duration(seconds: 10));
      _connected = true;
    } catch (e) {
      _connected = false;
    }
    _connecting = false;
    notifyListeners();
  }

  Future<void> disconnect() async {
    if (_connectedDevice != null) {
      await _connectedDevice!.disconnect();
      _connectedDevice = null;
      _connected = false;
      _data = '';
      notifyListeners();
    }
  }

  Future<void> readDataFromDevice({
    Guid? serviceUuid,
    Guid? characteristicUuid,
  }) async {
    if (_connectedDevice == null) return;
    try {
      // Descubra serviços
      List<BluetoothService> services =
          await _connectedDevice!.discoverServices();
      BluetoothCharacteristic? targetChar;

      // Procura a characteristic (se não informado, pega a primeira característica legível)
      for (var service in services) {
        for (var char in service.characteristics) {
          if ((characteristicUuid != null && char.uuid == characteristicUuid) ||
              (characteristicUuid == null && char.properties.read)) {
            targetChar = char;
            break;
          }
        }
        if (targetChar != null) break;
      }

      if (targetChar != null) {
        var value = await targetChar.read();
        _data = value.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      } else {
        _data = 'Nenhuma characteristic legível encontrada!';
      }
    } catch (e) {
      _data = 'Erro ao ler dados: $e';
    }
    notifyListeners();
  }
}
