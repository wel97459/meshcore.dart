import 'dart:async';
import 'dart:typed_data';
import 'package:meshcore_dart/src/connection.dart';
import 'package:meshcore_dart/src/connection_commands.dart';
import 'package:meshcore_dart/src/constants.dart';
import 'package:meshcore_dart/src/buffer_reader.dart';
import 'package:test/test.dart';

// Concrete class that mixes in ConnectionCommands
class TestConnectionCommands extends Connection with ConnectionCommands {
  Uint8List? lastSentFrame;

  @override
  Future<void> connect() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> sendToRadioFrame(Uint8List data) async {
    lastSentFrame = data;
  }

  @override
  void dispatchResponse(int code, BufferReader reader) {}
}

void main() {
  group('ConnectionCommands', () {
    late TestConnectionCommands connection;

    setUp(() {
      connection = TestConnectionCommands();
    });

    test('sendCommandAppStart sends correct frame', () async {
      await connection.sendCommandAppStart();
      final frame = connection.lastSentFrame!;
      expect(frame[0], equals(CommandCodes.appStart));
      expect(frame[1], equals(1)); // appVer
      // reserved bytes (6)
      // appName "test"
    });

    test('sendCommandSendTxtMsg sends correct frame', () async {
      final txtType = TxtTypes.plain;
      final attempt = 0;
      final senderTimestamp = 1234567890;
      final pubKeyPrefix = Uint8List(6); // 0s
      final text = "Hello";

      await connection.sendCommandSendTxtMsg(txtType, attempt, senderTimestamp, pubKeyPrefix, text);
      final frame = connection.lastSentFrame!;
      
      expect(frame[0], equals(CommandCodes.sendTxtMsg));
      expect(frame[1], equals(txtType));
      expect(frame[2], equals(attempt));
      // ... check timestamp, pubKeyPrefix, text
    });
  });
}
