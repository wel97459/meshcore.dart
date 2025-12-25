import 'dart:async';
import 'dart:typed_data';
import 'package:meshcore_dart/src/serial_port_wrapper.dart';

class MockSerialPort implements SerialPortWrapper {
  final StreamController<Uint8List> _controller = StreamController<Uint8List>();
  bool _isOpen = false;
  Uint8List? lastWrittenData;

  @override
  Stream<Uint8List> get inputStream => _controller.stream;

  @override
  Future<bool> open() async {
    _isOpen = true;
    return true;
  }

  @override
  Future<bool> close() async {
    _isOpen = false;
    return true;
  }

  @override
  void write(Uint8List data) {
    lastWrittenData = data;
  }

  @override
  bool get isOpen => _isOpen;

  // Helper for tests
  void simulateData(Uint8List data) {
    _controller.add(data);
  }
}
