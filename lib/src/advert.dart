import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'buffer_reader.dart';
import 'buffer_writer.dart';

class Advert {
  static const int advTypeNone = 0;
  static const int advTypeChat = 1;
  static const int advTypeRepeater = 2;
  static const int advTypeRoom = 3;

  static const int advLatLonMask = 0x10;
  static const int advBatteryMask = 0x20;
  static const int advTemperatureMask = 0x40;
  static const int advNameMask = 0x80;

  final Uint8List publicKey;
  final int timestamp;
  final Uint8List signature;
  final Uint8List appData;

  Advert({
    required this.publicKey,
    required this.timestamp,
    required this.signature,
    required this.appData,
  });

  factory Advert.fromBytes(Uint8List bytes) {
    final reader = BufferReader(bytes);
    final publicKey = reader.readBytes(32);
    final timestamp = reader.readUInt32LE();
    final signature = reader.readBytes(64);
    final appData = reader.readRemainingBytes();

    return Advert(
      publicKey: publicKey,
      timestamp: timestamp,
      signature: signature,
      appData: appData,
    );
  }

  Future<bool> isVerified() async {
    final algorithm = Ed25519();

    // build signed data
    final writer = BufferWriter();
    writer.writeBytes(publicKey);
    writer.writeUInt32LE(timestamp);
    writer.writeBytes(appData);

    final signedData = writer.toBytes();

    final result = await algorithm.verify(
      signedData,
      signature: Signature(signature, publicKey: SimplePublicKey(publicKey, type: KeyPairType.ed25519)),
    );

    return result;
  }
}
