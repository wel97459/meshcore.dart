import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:meshcore_dart/src/connection.dart';
import 'package:meshcore_dart/src/connection_commands.dart';
import 'package:meshcore_dart/src/connection_responses.dart';
import 'package:meshcore_dart/src/connection_helpers.dart';
import 'package:meshcore_dart/src/constants.dart';
import 'package:meshcore_dart/src/buffer_reader.dart';
import 'package:test/test.dart';

class TestConnectionHelpers extends Connection with ConnectionCommands, ConnectionResponses, ConnectionHelpers {
  @override
  Future<void> connect() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> sendToRadioFrame(Uint8List data) async {
    final reader = BufferReader(data);
    final cmd = reader.readByte();

    if (cmd == CommandCodes.appStart) {
      final payload = BytesBuilder();
      payload.addByte(ResponseCodes.selfInfo);
      payload.addByte(0x01); // type
      payload.addByte(0x02); // txPower
      payload.addByte(0x03); // maxTxPower
      payload.add(Uint8List(32)); // publicKey
      payload.add(Uint8List(4)); // advLat
      payload.add(Uint8List(4)); // advLon
      payload.add(Uint8List(3)); // reserved
      payload.addByte(0x00); // manualAddContacts
      payload.add(Uint8List(4)); // radioFreq
      payload.add(Uint8List(4)); // radioBw
      payload.addByte(0x00); // radioSf
      payload.addByte(0x00); // radioCr
      payload.add(utf8.encode("AB")); // name
      
      onFrameReceived(payload.toBytes());
    } else if (cmd == CommandCodes.getContacts) {
      onFrameReceived(Uint8List.fromList([ResponseCodes.contactsStart, 0x01, 0x00, 0x00, 0x00]));
      
      final contact = BytesBuilder();
      contact.addByte(ResponseCodes.contact);
      contact.add(Uint8List(32)); // publicKey
      contact.addByte(0x01); // type
      contact.addByte(0x00); // flags
      contact.addByte(0x00); // outPathLen
      contact.add(Uint8List(64)); // outPath
      contact.add(utf8.encode("Alice"));
      contact.add(Uint8List(32 - 5)); // pad name to 32
      contact.add(Uint8List(4)); // lastAdvert
      contact.add(Uint8List(4)); // advLat
      contact.add(Uint8List(4)); // advLon
      contact.add(Uint8List(4)); // lastMod
      onFrameReceived(contact.toBytes());

      onFrameReceived(Uint8List.fromList([ResponseCodes.endOfContacts, 0x00, 0x00, 0x00, 0x00]));
    }
  }
}

void main() {
  group('ConnectionHelpers', () {
    late TestConnectionHelpers connection;

    setUp(() {
      connection = TestConnectionHelpers();
    });

    test('getSelfInfo resolves with data', () async {
      final info = await connection.getSelfInfo();
      expect(info, isNotNull);
      expect(info['name'], equals("AB"));
    });

    test('getContacts resolves with list of contacts', () async {
      final contacts = await connection.getContacts();
      expect(contacts.length, equals(1));
      expect(contacts[0]['advName'], equals("Alice"));
    });
  });
}