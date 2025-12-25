import 'dart:typed_data';
import 'package:meshcore_dart/src/buffer_reader.dart';
import 'package:test/test.dart';

void main() {
  group('BufferReader', () {
    test('readByte reads a single byte', () {
      final reader = BufferReader(Uint8List.fromList([0x01, 0x02]));
      expect(reader.readByte(), equals(0x01));
      expect(reader.readByte(), equals(0x02));
    });

    test('readBytes reads multiple bytes', () {
      final reader = BufferReader(Uint8List.fromList([0x01, 0x02, 0x03]));
      expect(reader.readBytes(2), equals(Uint8List.fromList([0x01, 0x02])));
      expect(reader.readByte(), equals(0x03));
    });

    test('readRemainingBytes reads all remaining bytes', () {
      final reader = BufferReader(Uint8List.fromList([0x01, 0x02, 0x03]));
      reader.readByte();
      expect(reader.readRemainingBytes(), equals(Uint8List.fromList([0x02, 0x03])));
    });

    test('readString reads UTF-8 encoded string from remaining bytes', () {
      final reader = BufferReader(Uint8List.fromList([0x41, 0x42, 0x43]));
      expect(reader.readString(), equals("ABC"));
    });

    test('readCString reads null-terminated string', () {
      final reader = BufferReader(Uint8List.fromList([0x41, 0x42, 0x00, 0x43]));
      expect(reader.readCString(3), equals("AB"));
      expect(reader.readByte(), equals(0x43));
    });

    test('readUInt16LE reads 16-bit unsigned integer in little endian', () {
      final reader = BufferReader(Uint8List.fromList([0x34, 0x12]));
      expect(reader.readUInt16LE(), equals(0x1234));
    });

    test('readUInt16BE reads 16-bit unsigned integer in big endian', () {
      final reader = BufferReader(Uint8List.fromList([0x12, 0x34]));
      expect(reader.readUInt16BE(), equals(0x1234));
    });

    test('readUInt32LE reads 32-bit unsigned integer in little endian', () {
      final reader = BufferReader(Uint8List.fromList([0x78, 0x56, 0x34, 0x12]));
      expect(reader.readUInt32LE(), equals(0x12345678));
    });

    test('readUInt32BE reads 32-bit unsigned integer in big endian', () {
      final reader = BufferReader(Uint8List.fromList([0x12, 0x34, 0x56, 0x78]));
      expect(reader.readUInt32BE(), equals(0x12345678));
    });

    test('readInt24BE reads 24-bit signed integer in big endian', () {
      final reader = BufferReader(Uint8List.fromList([0xFF, 0xFF, 0xFF]));
      expect(reader.readInt24BE(), equals(-1));
      
      final reader2 = BufferReader(Uint8List.fromList([0x00, 0x00, 0x01]));
      expect(reader2.readInt24BE(), equals(1));

      final reader3 = BufferReader(Uint8List.fromList([0x7F, 0xFF, 0xFF]));
      expect(reader3.readInt24BE(), equals(8388607));

      final reader4 = BufferReader(Uint8List.fromList([0x80, 0x00, 0x00]));
      expect(reader4.readInt24BE(), equals(-8388608));
    });
  });
}
