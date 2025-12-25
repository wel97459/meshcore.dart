import 'dart:typed_data';
import 'package:meshcore_dart/src/packet.dart';
import 'package:meshcore_dart/src/advert.dart';
import 'package:meshcore_dart/src/constants.dart';
import 'package:test/test.dart';

void main() {
  group('Packet', () {
    test('Constructor initializes properties correctly', () {
      final header = 0x00;
      final path = Uint8List.fromList([0x01, 0x02]);
      final payload = Uint8List.fromList([0x03, 0x04]);

      final packet = Packet(header, path, payload);

      expect(packet.header, equals(header));
      expect(packet.path, equals(path));
      expect(packet.payload, equals(payload));
    });

    test('getRouteType returns correct route type', () {
      // 0x01 is FLOOD (RouteType.flood is 0x01)
      // Header is just the route type in this case as other bits are 0
      final packet = Packet(RouteType.flood, Uint8List(0), Uint8List(0));
      expect(packet.routeType, equals(RouteType.flood));
    });

    test('getPayloadType returns correct payload type', () {
      // Payload type is shifted by 2 bits.
      // 0x04 << 2 = 0x10. PayloadType.advert is 0x04.
      final packet = Packet(PayloadType.advert << PacketHeader.typeShift, Uint8List(0), Uint8List(0));
      expect(packet.payloadType, equals(PayloadType.advert));
    });

    test('fromBytes parses packet correctly', () {
      final bytes = Uint8List.fromList([
        0x11, // header (route=1, type=4, ver=0) -> 1 | (4 << 2) | (0 << 6) = 1 | 16 = 17 = 0x11
        0x02, // pathLen
        0xAA, 0xBB, // path
        0xCC, 0xDD, 0xEE // payload
      ]);

      final packet = Packet.fromBytes(bytes);

      expect(packet.header, equals(0x11));
      expect(packet.path, equals(Uint8List.fromList([0xAA, 0xBB])));
      expect(packet.payload, equals(Uint8List.fromList([0xCC, 0xDD, 0xEE])));
    });

    test('toBytes serializes packet correctly', () {
      final packet = Packet(
        0x11,
        Uint8List.fromList([0xAA, 0xBB]),
        Uint8List.fromList([0xCC, 0xDD, 0xEE]),
      );

      final expectedBytes = Uint8List.fromList([
        0x11, // header
        0x02, // pathLen
        0xAA, 0xBB, // path
        0xCC, 0xDD, 0xEE // payload
      ]);

      expect(packet.toBytes(), equals(expectedBytes));
    });

    test('parsePayload correctly parses ADVERT payload', () {
      final advertPacketHex = "1100e04b135959ffac9397b600add84822cb8bf4a050a7f40965dd1ab7aea3ddd3743327e668b5db95bc8fbc3894b115415d6e4cca36f9c9e62e923afd37c3e2a154b27b0c53b6cfddd45bb3faf56fdaf08860d985ca2da44f9dcac1d7d76fc2b86d7b26e004814c69616d20436f74746c6520f09fa4a0";
      final bytes = Uint8List.fromList(List.generate(advertPacketHex.length ~/ 2, (i) => int.parse(advertPacketHex.substring(i * 2, i * 2 + 2), radix: 16)));
      
      final packet = Packet.fromBytes(bytes);
      final parsed = packet.parsePayload();

      expect(parsed, isNotNull);
      expect(parsed!['public_key'], isA<Uint8List>());
      expect(parsed['timestamp'], isA<int>());
      expect(parsed['advert'], isA<Advert>());
    });
  });
}
