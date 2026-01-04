import 'dart:async';
import 'dart:typed_data';
import 'constants.dart';

class SerialFrameParser extends StreamTransformerBase<Uint8List, Uint8List> {
  @override
  Stream<Uint8List> bind(Stream<Uint8List> stream) {
    final controller = StreamController<Uint8List>(sync: true);
    final List<int> buffer = [];

    stream.listen(
      (data) {
        buffer.addAll(data);
        _processBuffer(controller, buffer);
      },
      onError: controller.addError,
      onDone: () {
        _processBuffer(controller, buffer);
        controller.close();
      },
      cancelOnError: false,
    );

    return controller.stream;
  }

  void _processBuffer(StreamController<Uint8List> controller, List<int> buffer) {
    const frameHeaderLength = 3;
    
    int offset = 0;
    while (buffer.length - offset >= frameHeaderLength) {
      final frameType = buffer[offset];
      
      // Check if frame type is supported
      if (frameType != SerialFrameTypes.incoming && frameType != SerialFrameTypes.outgoing) {
        offset++;
        continue;
      }

      // Extract length (little endian)
      final length = buffer[offset + 1] | (buffer[offset + 2] << 8);
      
      if (length == 0) {
        // Invalid length, skip header and try again
        offset += frameHeaderLength;
        continue;
      }

      final requiredLength = frameHeaderLength + length;
      if (buffer.length - offset < requiredLength) {
        // Wait for more data
        break;
      }

      // Extract frame data
      final frameData = Uint8List.fromList(buffer.sublist(offset + frameHeaderLength, offset + requiredLength));
      offset += requiredLength;
      
      controller.add(frameData);
    }

    if (offset > 0) {
      if (offset >= buffer.length) {
        buffer.clear();
      } else {
        buffer.removeRange(0, offset);
      }
    }
  }
}
