import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:meshcore_dart/src/lib_serial_port_plus_wrapper.dart';
import 'package:meshcore_dart/src/serial_port_wrapper.dart';

void main() {
  group('LibSerialPortPlusWrapper', () {
    test('should implement SerialPortWrapper', () {
      final wrapper = LibSerialPortPlusWrapper('test_port', 115200);
      expect(wrapper, isA<SerialPortWrapper>());
    });

    test('open() should return false for invalid port', () async {
      final wrapper = LibSerialPortPlusWrapper('invalid_port_name', 115200);
      final result = await wrapper.open();
      expect(result, isFalse);
      expect(wrapper.isOpen, isFalse);
    });

    test('close() should return true even if not open', () async {
      final wrapper = LibSerialPortPlusWrapper('test_port', 115200);
      final result = await wrapper.close();
      expect(result, isTrue);
      expect(wrapper.isOpen, isFalse);
    });

    test('write() should not throw when closed', () {
      final wrapper = LibSerialPortPlusWrapper('test_port', 115200);
      expect(() => wrapper.write(Uint8List.fromList([1, 2, 3])), returnsNormally);
    });

    test('inputStream should be a broadcast stream', () {
      final wrapper = LibSerialPortPlusWrapper('test_port', 115200);
      expect(wrapper.inputStream.isBroadcast, isTrue);
    });

    test('isOpen should be false initially', () {
      final wrapper = LibSerialPortPlusWrapper('test_port', 115200);
      expect(wrapper.isOpen, isFalse);
    });
  });
}
