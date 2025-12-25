import 'dart:async';
import 'dart:typed_data';
import 'constants.dart';

class SerialFrameParser extends StreamTransformerBase<Uint8List, Uint8List> {
  final List<int> _buffer = [];

  @override
  Stream<Uint8List> bind(Stream<Uint8List> stream) {
    final controller = StreamController<Uint8List>(sync: true);
    
    stream.listen(
      (data) {
        _buffer.addAll(data);
        _processBuffer(controller);
      },
      onError: controller.addError,
      onDone: () {
        _processBuffer(controller);
        controller.close();
      },
      cancelOnError: false,
    );

    return controller.stream;
  }

  void _processBuffer(StreamController<Uint8List> controller) {
    const frameHeaderLength = 3;
    
    while (_buffer.length >= frameHeaderLength) {
      final frameType = _buffer[0];
      
      // Check if frame type is supported
      if (frameType != SerialFrameTypes.incoming && frameType != SerialFrameTypes.outgoing) {
        _buffer.removeAt(0);
        continue;
      }

      // Extract length (little endian)
      final length = _buffer[1] | (_buffer[2] << 8);
      
      if (length == 0) {
        // Invalid length, skip header and try again
        _buffer.removeRange(0, frameHeaderLength);
        continue;
      }

      final requiredLength = frameHeaderLength + length;
      if (_buffer.length < requiredLength) {
        // Wait for more data
        break;
      }

      // Extract frame data
      final frameData = Uint8List.fromList(_buffer.sublist(frameHeaderLength, requiredLength));
      _buffer.removeRange(0, requiredLength);
      
      controller.add(frameData);
    }
  }
}
