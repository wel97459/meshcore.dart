import 'dart:async';
import 'dart:typed_data';
import 'package:meshcore_dart/src/connection.dart';
import 'package:meshcore_dart/src/buffer_reader.dart';
import 'package:test/test.dart';

// Concrete implementation for testing
class TestConnection extends Connection {
  bool _shouldFailConnect = false;
  Uint8List? lastSentFrame;

  @override
  Future<void> close() async {
    onDisconnected();
  }

  @override
  Future<void> connect() async {
    if (_shouldFailConnect) {
      throw Exception('Failed to connect');
    }
    onConnected();
  }

  @override
  Future<void> sendToRadioFrame(Uint8List data) async {
    lastSentFrame = data;
  }

  @override
  void dispatchResponse(int code, BufferReader reader) {
    emit(code, reader.readRemainingBytes());
  }

  void setShouldFailConnect(bool value) {
    _shouldFailConnect = value;
  }

  // Helper to trigger events
  void simulateConnected() => onConnected();
  void simulateDisconnected() => onDisconnected();
}

void main() {
  group('Connection Event System', () {
    late TestConnection connection;

    setUp(() {
      connection = TestConnection();
    });

    test('can emit and listen for events', () async {
      final completer = Completer<dynamic>();
      connection.on('test_event', (data) {
        completer.complete(data);
      });

      connection.emit('test_event', 'hello');

      expect(await completer.future, equals('hello'));
    });

    test('can remove listener', () async {
      var count = 0;
      void listener(data) {
        count++;
      }

      connection.on('test_event', listener);
      connection.emit('test_event', null);
      
      connection.off('test_event', listener);
      connection.emit('test_event', null);

      // Should only be called once
      await Future.delayed(Duration(milliseconds: 10)); // simple wait for async stream
      expect(count, equals(1));
    });

    test('once listener is called only once', () async {
      var count = 0;
      connection.once('test_event', (data) {
        count++;
      });

      connection.emit('test_event', null);
      connection.emit('test_event', null);

      await Future.delayed(Duration(milliseconds: 10));
      expect(count, equals(1));
    });
  });

  group('Connection Lifecycle', () {
    late TestConnection connection;

    setUp(() {
      connection = TestConnection();
    });

    test('initial state is disconnected', () {
      expect(connection.isConnected, isFalse);
    });

    test('connect() updates state and emits connected', () async {
      final completer = Completer<void>();
      connection.on('connected', (_) {
        completer.complete();
      });

      await connection.connect();

      expect(connection.isConnected, isTrue);
      await completer.future;
    });

    test('close() updates state and emits disconnected', () async {
      await connection.connect();
      expect(connection.isConnected, isTrue);

      final completer = Completer<void>();
      connection.on('disconnected', (_) {
        completer.complete();
      });

      await connection.close();

      expect(connection.isConnected, isFalse);
      await completer.future;
    });
  });

  group('Command Dispatching', () {
    late TestConnection connection;

    setUp(() {
      connection = TestConnection();
    });

    test('sendToRadioFrame captures the frame', () async {
      final data = Uint8List.fromList([0x01, 0x02]);
      await connection.sendToRadioFrame(data);
      expect(connection.lastSentFrame, equals(data));
    });
  });

  group('Response Handling', () {
    late TestConnection connection;

    setUp(() {
      connection = TestConnection();
    });

    test('waitForResponse resolves when event is emitted', () async {
      final future = connection.waitForResponse('ok_event');
      connection.emit('ok_event', 'success');
      expect(await future, equals('success'));
    });

    test('waitForResponse times out if no event is emitted', () async {
      final future = connection.waitForResponse('timeout_event', timeout: Duration(milliseconds: 10));
      expect(future, throwsA(isA<TimeoutException>()));
    });

    test('onFrameReceived routes to correct event', () async {
      final completer = Completer<dynamic>();
      connection.on(0x01, (data) {
        completer.complete(data);
      });

      // Frame with code 0x01 and some data
      final frame = Uint8List.fromList([0x01, 0xAA, 0xBB]);
      connection.onFrameReceived(frame);

      final result = await completer.future;
      expect(result, isA<Uint8List>());
      expect(result, equals(Uint8List.fromList([0xAA, 0xBB])));
    });
  });
}
