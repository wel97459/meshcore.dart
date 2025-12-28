import 'dart:async';
import 'dart:typed_data';
import 'package:universal_ble/universal_ble.dart';
import 'connection.dart';
import 'connection_commands.dart';
import 'connection_responses.dart';
import 'connection_helpers.dart';
import 'constants.dart';
import 'ble_wrapper.dart';

class BleConnection extends Connection
    with ConnectionCommands, ConnectionResponses, ConnectionHelpers {
  final String deviceId;
  final BleWrapper ble;
  
  static final Map<String, BleConnection> _instances = {};

  BleConnection(this.deviceId, {BleWrapper? ble}) : ble = ble ?? BleWrapper() {
    _instances[deviceId] = this;
    this.ble.onValueChange = (deviceId, characteristicId, value, error) {
      _handleValueChange(deviceId, characteristicId, value);
    };
  }

  static void _handleValueChange(String deviceId, String characteristicId, Uint8List value) {
    final instance = _instances[deviceId];
    if (instance != null && characteristicId.toLowerCase() == BleUuids.characteristicUuidTx.toLowerCase()) {
      instance.onFrameReceived(value);
    }
  }

  @override
  Future<void> connect() async {
    await ble.connect(deviceId);
    
    // Discover services
    final services = await ble.discoverServices(deviceId);
    
    // Find the MeshCore service
    final meshService = services.firstWhere(
      (s) => s.uuid.toLowerCase() == BleUuids.serviceUuid.toLowerCase(),
      orElse: () => throw Exception('MeshCore service not found'),
    );

    // Find characteristics
    final characteristics = meshService.characteristics;

    final txChar = characteristics.firstWhere(
      (c) => c.uuid.toLowerCase() == BleUuids.characteristicUuidTx.toLowerCase(),
      orElse: () => throw Exception('TX characteristic not found'),
    );

    // Enable notifications on TX
    await ble.subscribeNotifications(
      deviceId,
      meshService.uuid,
      txChar.uuid,
    );

    onConnected();
  }

  @override
  Future<void> close() async {
    try {
      await ble.unsubscribe(
        deviceId,
        BleUuids.serviceUuid,
        BleUuids.characteristicUuidTx,
      );
      await ble.disconnect(deviceId);
    } catch (e) {
      // Ignore disconnect errors
    } finally {
      onDisconnected();
      _instances.remove(deviceId);
    }
  }

  @override
  Future<void> sendToRadioFrame(Uint8List data) async {
    emit('tx', data);
    await ble.write(
      deviceId,
      BleUuids.serviceUuid,
      BleUuids.characteristicUuidRx,
      data,
    );
  }

  static Future<List<BleDevice>> scan({BleWrapper? ble, Duration timeout = const Duration(seconds: 5)}) async {
    final b = ble ?? BleWrapper();
    final Map<String, BleDevice> devices = {};
    final completer = Completer<List<BleDevice>>();

    b.onScanResult = (BleDevice device) {
      devices[device.deviceId] = device;
    };

    await b.startScan(
      scanFilter: ScanFilter(withServices: [BleUuids.serviceUuid]),
    );

    Timer(timeout, () async {
      try {
        await b.stopScan();
      } catch (e) {
        // Ignore stopScan errors
      }
      b.onScanResult = null;
      if (!completer.isCompleted) {
        completer.complete(devices.values.toList());
      }
    });

    return completer.future;
  }
}
