import 'dart:async';
import 'dart:typed_data';
import 'connection.dart';
import 'connection_commands.dart';
import 'connection_responses.dart';
import 'connection_helpers.dart';
import 'serial_port_wrapper.dart';
import 'buffer_writer.dart';
import 'serial_frame_parser.dart';
import 'constants.dart';

class SerialConnection extends Connection with ConnectionCommands, ConnectionResponses, ConnectionHelpers {
  final SerialPortWrapper _port;
  StreamSubscription<Uint8List>? _subscription;

  SerialConnection(this._port);

  @override
  Future<void> connect() async {
    final success = await _port.open();
    if (success) {
      _subscription = _port.inputStream
          .transform(SerialFrameParser())
          .listen(onFrameReceived);
      onConnected();
    } else {
      throw Exception('Failed to open serial port');
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _port.close();
    onDisconnected();
  }

  @override
  Future<void> sendToRadioFrame(Uint8List data) async {
    final frame = BufferWriter();
    frame.writeByte(SerialFrameTypes.outgoing);
    frame.writeUInt16LE(data.length);
    frame.writeBytes(data);
    
    _port.write(frame.toBytes());
  }
}