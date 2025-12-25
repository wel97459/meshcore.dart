import 'dart:async';
import 'dart:typed_data';
import 'package:libserialport_plus/libserialport_plus.dart';
import 'serial_port_wrapper.dart';

class LibSerialPortPlusWrapper implements SerialPortWrapper {
  final String portName;
  final int baudRate;
  final StreamController<Uint8List> _controller = StreamController<Uint8List>.broadcast();
  bool _isOpen = false;
  SerialPort? _port;
  SerialPortReader? _reader;
  StreamSubscription? _subscription;

  LibSerialPortPlusWrapper(this.portName, this.baudRate);

  @override
  Stream<Uint8List> get inputStream => _controller.stream;

  @override
  Future<bool> open() async {
    if (_isOpen) return true;

    try {
      _port = SerialPort(portName);
      _port!.open();
      
      final config = SerialPortConfig(
        baudRate: baudRate,
        bits: 8,
        parity: SerialPortParity.none,
        stopBits: 1,
      );
      _port!.setConfig(config);

      _reader = SerialPortReader(_port!);
      _subscription = _reader!.stream.listen(
        (data) => _controller.add(data),
        onError: (error) {
          print("Serial port error: $error");
          close();
        },
        onDone: () => close(),
      );

      _isOpen = true;
      return true;
    } catch (e) {
      print("Error opening port: $e");
      _port?.dispose();
      _port = null;
    }
    return false;
  }

  @override
  Future<bool> close() async {
    if (!_isOpen) return true;

    _isOpen = false;
    await _subscription?.cancel();
    _subscription = null;
    _reader = null;
    
    try {
      if (_port != null && _port!.isOpen()) {
        _port!.close();
      }
    } catch (e) {
      print("Error closing port: $e");
    } finally {
      _port?.dispose();
      _port = null;
    }

    return true;
  }

  @override
  void write(Uint8List data) {
    if (_isOpen && _port != null) {
      try {
        _port!.write(data);
      } catch (e) {
        print("Error writing to port: $e");
      }
    }
  }

  @override
  bool get isOpen => _isOpen;

  static List<String> listAvailablePorts() {
    return SerialPort.getAvailablePorts();
  }
}
