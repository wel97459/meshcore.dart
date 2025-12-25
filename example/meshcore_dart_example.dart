import 'dart:typed_data';
import 'package:meshcore_dart/meshcore.dart';

void main() {
  print('MeshCore Dart Library Example');
  
  // Create a packet
  final packet = Packet(0x12, Uint8List(0x34), Uint8List(0x56));
  print('Packet route type: ${packet.routeType}');
}
