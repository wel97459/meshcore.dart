import 'dart:async';
import 'dart:typed_data';
import 'event_emitter.dart';
import 'buffer_reader.dart';
import 'constants.dart';

abstract class Connection extends EventEmitter {
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  Future<void> connect();
  Future<void> close();
  Future<void> sendToRadioFrame(Uint8List data);

  void onConnected() {
    _isConnected = true;
    emit(EventNames.connected);
  }

  void onDisconnected() {
    _isConnected = false;
    emit(EventNames.disconnected);
  }

  Future<dynamic> waitForResponse(dynamic event, {Duration? timeout}) {
    final completer = Completer<dynamic>();
    Timer? timer;

    void listener(dynamic data) {
      timer?.cancel();
      off(event, listener);
      if (!completer.isCompleted) {
        completer.complete(data);
      }
    }

    on(event, listener);

    if (timeout != null) {
      timer = Timer(timeout, () {
        off(event, listener);
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Timed out waiting for $event', timeout));
        }
      });
    }

    return completer.future;
  }

  void onFrameReceived(Uint8List frame) {
    emit(EventNames.rx, frame);

    if (frame.isEmpty) return;

    final bufferReader = BufferReader(frame);
    final responseCode = bufferReader.readByte();

    dispatchResponse(responseCode, bufferReader);
  }

  // To be implemented by ConnectionResponses mixin
  void dispatchResponse(int code, BufferReader reader);
}
