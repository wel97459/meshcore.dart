import 'dart:async';
import 'dart:typed_data';
import 'package:libserialport/libserialport.dart';
import 'serial_port_wrapper.dart';

class LibSerialPortWrapper implements SerialPortWrapper {
  final String _portName;
  late SerialPort _port;
  final StreamController<Uint8List> _controller = StreamController<Uint8List>.broadcast();
  bool _isOpen = false;
  Timer? _readTimer;

  LibSerialPortWrapper(this._portName) {
    _port = SerialPort(_portName);
  }

  @override
  Stream<Uint8List> get inputStream => _controller.stream;

  @override
  Future<bool> open() async {
    if (_isOpen) return true;
    
    // Default configuration for MeshCore devices
    final config = SerialPortConfig();
    config.baudRate = 115200;
    
    try {
      if (_port.openReadWrite()) {
        _port.config = config;
        _isOpen = true;
        _startReading();
        return true;
      }
    } catch (e) {
      print("Error opening port: $e");
    }
    return false;
  }

  @override
  Future<bool> close() async {
    if (!_isOpen) return true;
    _stopReading();
    _isOpen = !_port.close();
    return !_isOpen;
  }

  @override
  void write(Uint8List data) {
    if (_isOpen) {
      _port.write(data);
    }
  }

  @override
  bool get isOpen => _isOpen;

  void _startReading() {
    _readTimer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      if (_isOpen) {
        try {
          if (_port.bytesAvailable > 0) {
            final data = _port.read(_port.bytesAvailable);
            if (data.isNotEmpty) {
              _controller.add(data);
            }
          }
        } catch (e) {
          print("Error reading from port: $e");
          close();
        }
      }
    });
  }

  void _stopReading() {
    _readTimer?.cancel();
    _readTimer = null;
  }

  static List<String> listAvailablePorts() {
    return SerialPort.availablePorts;
  }
}
