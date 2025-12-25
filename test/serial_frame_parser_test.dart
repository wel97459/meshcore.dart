import 'dart:async';
import 'dart:typed_data';
import 'package:meshcore_dart/src/serial_frame_parser.dart';
import 'package:test/test.dart';

void main() {
  group('SerialFrameParser', () {
    test('parses a single complete frame', () async {
      final frameData = Uint8List.fromList([0xAA, 0xBB]);
      final rawData = Uint8List.fromList([
        0x3e, // frameType Incoming
        0x02, 0x00, // length 2
        ...frameData
      ]);

      final controller = StreamController<Uint8List>();
      final stream = controller.stream.transform(SerialFrameParser());

      final results = <Uint8List>[];
      final subscription = stream.listen(results.add);

      controller.add(rawData);
      await Future.delayed(Duration(milliseconds: 10));

      expect(results.length, equals(1));
      expect(results[0], equals(frameData));
      
      await subscription.cancel();
    });

    test('parses multiple frames in one chunk', () async {
      final frame1 = Uint8List.fromList([0x01]);
      final frame2 = Uint8List.fromList([0x02, 0x03]);
      final rawData = Uint8List.fromList([
        0x3e, 0x01, 0x00, ...frame1,
        0x3e, 0x02, 0x00, ...frame2
      ]);

      final controller = StreamController<Uint8List>();
      final stream = controller.stream.transform(SerialFrameParser());

      final results = <Uint8List>[];
      final subscription = stream.listen(results.add);

      controller.add(rawData);
      await Future.delayed(Duration(milliseconds: 10));

      expect(results.length, equals(2));
      expect(results[0], equals(frame1));
      expect(results[1], equals(frame2));

      await subscription.cancel();
    });

    test('parses frames delivered in partial chunks', () async {
      final frameData = Uint8List.fromList([0xAA, 0xBB, 0xCC]);
      final rawData = Uint8List.fromList([
        0x3e, 0x03, 0x00, ...frameData
      ]);

      final controller = StreamController<Uint8List>();
      final stream = controller.stream.transform(SerialFrameParser());

      final results = <Uint8List>[];
      final subscription = stream.listen(results.add);

      // Send first 2 bytes [type, lenLSB]
      controller.add(rawData.sublist(0, 2));
      await Future.delayed(Duration(milliseconds: 10));
      expect(results.isEmpty, isTrue);

      // Send next 2 bytes [lenMSB, data1]
      controller.add(rawData.sublist(2, 4));
      await Future.delayed(Duration(milliseconds: 10));
      expect(results.isEmpty, isTrue);

      // Send remainder
      controller.add(rawData.sublist(4));
      await Future.delayed(Duration(milliseconds: 10));

      expect(results.length, equals(1));
      expect(results[0], equals(frameData));

      await subscription.cancel();
    });

    test('skips invalid frame types', () async {
      final frameData = Uint8List.fromList([0xAA]);
      final rawData = Uint8List.fromList([
        0xFF, // invalid type
        0x3e, 0x01, 0x00, ...frameData
      ]);

      final controller = StreamController<Uint8List>();
      final stream = controller.stream.transform(SerialFrameParser());

      final results = <Uint8List>[];
      final subscription = stream.listen(results.add);

      controller.add(rawData);
      await Future.delayed(Duration(milliseconds: 10));

      expect(results.length, equals(1));
      expect(results[0], equals(frameData));

      await subscription.cancel();
    });
  });
}
