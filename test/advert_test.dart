import 'dart:typed_data';
import 'package:meshcore_dart/src/advert.dart';
import 'package:test/test.dart';

void main() {
  group('Advert', () {
    test('fromBytes parses advert correctly', () {
      final advertHex = "e04b135959ffac9397b600add84822cb8bf4a050a7f40965dd1ab7aea3ddd3743327e668b5db95bc8fbc3894b115415d6e4cca36f9c9e62e923afd37c3e2a154b27b0c53b6cfddd45bb3faf56fdaf08860d985ca2da44f9dcac1d7d76fc2b86d7b26e004814c69616d20436f74746c6520f09fa4a0";
      final bytes = Uint8List.fromList(List.generate(advertHex.length ~/ 2, (i) => int.parse(advertHex.substring(i * 2, i * 2 + 2), radix: 16)));
      
      final advert = Advert.fromBytes(bytes);

      expect(advert.publicKey.length, equals(32));
      expect(advert.timestamp, isA<int>());
      expect(advert.signature.length, equals(64));
      expect(advert.appData.length, greaterThan(0));
    });

    test('isVerified returns true for valid signature', () async {
      // Using the hex from parse_advert.js which should be valid
      final advertHex = "e04b135959ffac9397b600add84822cb8bf4a050a7f40965dd1ab7aea3ddd3743327e668b5db95bc8fbc3894b115415d6e4cca36f9c9e62e923afd37c3e2a154b27b0c53b6cfddd45bb3faf56fdaf08860d985ca2da44f9dcac1d7d76fc2b86d7b26e004814c69616d20436f74746c6520f09fa4a0";
      final bytes = Uint8List.fromList(List.generate(advertHex.length ~/ 2, (i) => int.parse(advertHex.substring(i * 2, i * 2 + 2), radix: 16)));
      
      final advert = Advert.fromBytes(bytes);
      final verified = await advert.isVerified();
      expect(verified, isTrue);
    });
  });
}
