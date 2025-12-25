import 'dart:async';
import 'dart:typed_data';
import 'package:meshcore_dart/src/serial_connection.dart';
import 'package:meshcore_dart/src/constants.dart';
import 'package:test/test.dart';
import 'mock_serial_port.dart';

void main() {
  group('SerialConnection', () {
    late SerialConnection connection;
    late MockSerialPort mockPort;

    setUp(() {
      mockPort = MockSerialPort();
      connection = SerialConnection(mockPort);
    });

    test('connect opens the port', () async {
      await connection.connect();
      expect(mockPort.isOpen, isTrue);
      expect(connection.isConnected, isTrue);
    });

    test('close closes the port', () async {
      await connection.connect();
      await connection.close();
      expect(mockPort.isOpen, isFalse);
      expect(connection.isConnected, isFalse);
    });

    test('sendToRadioFrame writes framed data to port', () async {
      final data = Uint8List.fromList([0xAA, 0xBB]);
      await connection.sendToRadioFrame(data);

      final written = mockPort.lastWrittenData!;
      expect(written[0], equals(0x3c)); // frameType Outgoing
      expect(written[1], equals(0x02)); // length LSB
      expect(written[2], equals(0x00)); // length MSB
      expect(written.sublist(3), equals(data));
    });

    test('receives and routes incoming frames', () async {
      await connection.connect();

      final completer = Completer<dynamic>();
      connection.on(ResponseCodes.ok, (data) {
        completer.complete(data);
      });

      // Send framed OK response [type, lenLSB, lenMSB, code]
      final frame = Uint8List.fromList([0x3e, 0x01, 0x00, ResponseCodes.ok]);
      mockPort.simulateData(frame);

      await completer.future;
    });
  });
}