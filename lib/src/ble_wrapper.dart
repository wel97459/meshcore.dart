import 'dart:typed_data';
import 'package:universal_ble/universal_ble.dart';

class BleWrapper {
  Future<void> connect(String deviceId) => UniversalBle.connect(deviceId);
  
  Future<void> disconnect(String deviceId) => UniversalBle.disconnect(deviceId);
  
  Future<List<BleService>> discoverServices(String deviceId) => 
      UniversalBle.discoverServices(deviceId);
  
  Future<void> subscribeNotifications(String deviceId, String serviceUuid, String characteristicUuid) => 
      UniversalBle.subscribeNotifications(deviceId, serviceUuid, characteristicUuid);
  
  Future<void> unsubscribe(String deviceId, String serviceUuid, String characteristicUuid) => 
      UniversalBle.unsubscribe(deviceId, serviceUuid, characteristicUuid);
  
  Future<void> write(String deviceId, String serviceUuid, String characteristicUuid, Uint8List value) => 
      UniversalBle.write(deviceId, serviceUuid, characteristicUuid, value);
  
  Future<void> startScan({ScanFilter? scanFilter}) => 
      UniversalBle.startScan(scanFilter: scanFilter);
  
  Future<void> stopScan() => UniversalBle.stopScan();
  
  set onValueChange(OnValueChange? callback) => UniversalBle.onValueChange = callback;
  
  set onScanResult(OnScanResult? callback) => UniversalBle.onScanResult = callback;
}
