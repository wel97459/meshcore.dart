import 'dart:typed_data';
import 'package:meshcore_dart/src/buffer_writer.dart';
import 'package:test/test.dart';

void main() {
  group('BufferWriter', () {
    test('writeByte writes a single byte', () {
      final writer = BufferWriter();
      writer.writeByte(0x01);
      expect(writer.toBytes(), equals(Uint8List.fromList([0x01])));
    });

    test('writeBytes writes multiple bytes', () {
      final writer = BufferWriter();
      writer.writeBytes(Uint8List.fromList([0x01, 0x02, 0x03]));
      expect(writer.toBytes(), equals(Uint8List.fromList([0x01, 0x02, 0x03])));
    });

    test('writeUInt16LE writes 16-bit unsigned integer in little endian', () {
      final writer = BufferWriter();
      writer.writeUInt16LE(0x1234);
      expect(writer.toBytes(), equals(Uint8List.fromList([0x34, 0x12])));
    });

    test('writeUInt32LE writes 32-bit unsigned integer in little endian', () {
      final writer = BufferWriter();
      writer.writeUInt32LE(0x12345678);
      expect(writer.toBytes(), equals(Uint8List.fromList([0x78, 0x56, 0x34, 0x12])));
    });

    test('writeInt32LE writes 32-bit signed integer in little endian', () {
      final writer = BufferWriter();
      writer.writeInt32LE(-1);
      expect(writer.toBytes(), equals(Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF])));
    });

    test('writeString writes UTF-8 encoded string', () {
      final writer = BufferWriter();
      writer.writeString("ABC");
      expect(writer.toBytes(), equals(Uint8List.fromList([0x41, 0x42, 0x43])));
    });

    test('writeCString writes null-terminated string with fixed length', () {
      final writer = BufferWriter();
      writer.writeCString("ABC", 5);
      expect(writer.toBytes(), equals(Uint8List.fromList([0x41, 0x42, 0x43, 0x00, 0x00])));
    });

    test('writeCString truncates string if it exceeds maxLength - 1', () {
      final writer = BufferWriter();
      writer.writeCString("ABCDEF", 5);
      // "ABCD" + null terminator
      expect(writer.toBytes(), equals(Uint8List.fromList([0x41, 0x42, 0x43, 0x44, 0x00])));
    });
  });
}
