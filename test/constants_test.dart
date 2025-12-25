import 'package:meshcore_dart/src/constants.dart';
import 'package:test/test.dart';

void main() {
  group('Constants', () {
    test('Packet Header Constants', () {
      expect(PacketHeader.routeMask, 0x03);
      expect(PacketHeader.typeShift, 2);
      expect(PacketHeader.typeMask, 0x0F);
      expect(PacketHeader.verShift, 6);
      expect(PacketHeader.verMask, 0x03);
    });

    test('Route Types', () {
      expect(RouteType.flood, 0x01);
      expect(RouteType.direct, 0x02);
    });

    test('Payload Types', () {
      expect(PayloadType.req, 0x00);
      expect(PayloadType.response, 0x01);
      expect(PayloadType.txtMsg, 0x02);
      expect(PayloadType.ack, 0x03);
      expect(PayloadType.advert, 0x04);
      expect(PayloadType.grpTxt, 0x05);
      expect(PayloadType.grpData, 0x06);
      expect(PayloadType.anonReq, 0x07);
      expect(PayloadType.path, 0x08);
      expect(PayloadType.trace, 0x09);
      expect(PayloadType.rawCustom, 0x0F);
    });
  });
}