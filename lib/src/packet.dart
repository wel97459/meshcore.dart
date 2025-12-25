import 'dart:typed_data';
import 'constants.dart';
import 'buffer_reader.dart';
import 'buffer_writer.dart';
import 'advert.dart';

class Packet {
  int header;
  Uint8List path;
  Uint8List payload;

  Packet(this.header, this.path, this.payload);

  factory Packet.fromBytes(Uint8List bytes) {
    final reader = BufferReader(bytes);
    final header = reader.readByte();
    final pathLen = reader.readByte();
    final path = reader.readBytes(pathLen);
    final payload = reader.readRemainingBytes();
    return Packet(header, path, payload);
  }

  Uint8List toBytes() {
    final writer = BufferWriter();
    writer.writeByte(header);
    writer.writeByte(path.length);
    writer.writeBytes(path);
    writer.writeBytes(payload);
    return writer.toBytes();
  }

  int get routeType {
    return header & PacketHeader.routeMask;
  }

  int get payloadType {
    return (header >> PacketHeader.typeShift) & PacketHeader.typeMask;
  }

  Map<String, dynamic>? parsePayload() {
    switch (payloadType) {
      case PayloadType.path:
        return _parsePayloadTypePath();
      case PayloadType.req:
        return _parsePayloadTypeReq();
      case PayloadType.response:
        return _parsePayloadTypeResponse();
      case PayloadType.txtMsg:
        return _parsePayloadTypeTxtMsg();
      case PayloadType.ack:
        return _parsePayloadTypeAck();
      case PayloadType.advert:
        return _parsePayloadTypeAdvert();
      case PayloadType.anonReq:
        return _parsePayloadTypeAnonReq();
      default:
        return null;
    }
  }

  Map<String, dynamic> _parsePayloadTypePath() {
    final reader = BufferReader(payload);
    final dest = reader.readByte();
    final src = reader.readByte();
    return {'src': src, 'dest': dest};
  }

  Map<String, dynamic> _parsePayloadTypeReq() {
    final reader = BufferReader(payload);
    final dest = reader.readByte();
    final src = reader.readByte();
    final encrypted = reader.readRemainingBytes();
    return {'src': src, 'dest': dest, 'encrypted': encrypted};
  }

  Map<String, dynamic> _parsePayloadTypeResponse() {
    final reader = BufferReader(payload);
    final dest = reader.readByte();
    final src = reader.readByte();
    return {'src': src, 'dest': dest};
  }

  Map<String, dynamic> _parsePayloadTypeTxtMsg() {
    final reader = BufferReader(payload);
    final dest = reader.readByte();
    final src = reader.readByte();
    return {'src': src, 'dest': dest};
  }

  Map<String, dynamic> _parsePayloadTypeAck() {
    return {'ack_code': payload};
  }

  Map<String, dynamic> _parsePayloadTypeAdvert() {
    final advert = Advert.fromBytes(payload);
    return {
      'public_key': advert.publicKey,
      'timestamp': advert.timestamp,
      'advert': advert,
    };
  }

  Map<String, dynamic> _parsePayloadTypeAnonReq() {
    final reader = BufferReader(payload);
    final dest = reader.readByte();
    final srcPublicKey = reader.readBytes(32);
    return {'src': srcPublicKey, 'dest': dest};
  }
}
