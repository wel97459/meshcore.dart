import 'dart:async';
import 'dart:typed_data';
import 'package:meshcore_dart/src/connection.dart';
import 'package:meshcore_dart/src/connection_responses.dart';
import 'package:meshcore_dart/src/constants.dart';
import 'package:meshcore_dart/src/buffer_reader.dart';
import 'package:test/test.dart';

class TestConnectionResponses extends Connection with ConnectionResponses {
  @override
  Future<void> connect() async {}

  @override
  Future<void> close() async {}

  @override
  Future<void> sendToRadioFrame(Uint8List data) async {}
}

void main() {
  group('ConnectionResponses', () {
    late TestConnectionResponses connection;

    setUp(() {
      connection = TestConnectionResponses();
    });

    test('onOkResponse emits ok event', () async {
      final completer = Completer<dynamic>();
      connection.on(ResponseCodes.ok, (data) {
        completer.complete(data);
      });

      connection.onOkResponse(BufferReader(Uint8List(0)));
      await completer.future;
    });

    test('onErrResponse emits err event with code', () async {
      final completer = Completer<dynamic>();
      connection.on(ResponseCodes.err, (data) {
        completer.complete(data);
      });

      connection.onErrResponse(BufferReader(Uint8List.fromList([0x05])));
      final result = await completer.future;
      expect(result['errCode'], equals(0x05));
    });

    test('onFrameReceived routes to correct handler', () async {
      final completer = Completer<dynamic>();
      connection.on(ResponseCodes.ok, (data) {
        completer.complete(data);
      });

      connection.onFrameReceived(Uint8List.fromList([ResponseCodes.ok]));
      await completer.future;
    });
  });
}