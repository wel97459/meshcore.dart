import 'dart:typed_data';

abstract class SerialPortWrapper {
  Stream<Uint8List> get inputStream;
  Future<bool> open();
  Future<bool> close();
  void write(Uint8List data);
  bool get isOpen;
}
