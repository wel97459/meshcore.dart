import 'dart:typed_data';
import 'buffer_writer.dart';
import 'connection.dart';
import 'constants.dart';

mixin ConnectionCommands on Connection {
  Future<void> sendCommandAppStart() async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.appStart);
    writer.writeByte(1); // appVer
    writer.writeBytes(Uint8List(6)); // reserved
    writer.writeString("test"); // appName
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSendTxtMsg(int txtType, int attempt, int senderTimestamp, Uint8List pubKeyPrefix, String text) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.sendTxtMsg);
    writer.writeByte(txtType);
    writer.writeByte(attempt);
    writer.writeUInt32LE(senderTimestamp);
    // only the first 6 bytes of pubKey are sent
    if (pubKeyPrefix.length >= 6) {
      writer.writeBytes(pubKeyPrefix.sublist(0, 6));
    } else {
      writer.writeBytes(pubKeyPrefix);
    }
    writer.writeString(text);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSendChannelTxtMsg(int txtType, int channelIdx, int senderTimestamp, String text) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.sendChannelTxtMsg);
    writer.writeByte(txtType);
    writer.writeByte(channelIdx);
    writer.writeUInt32LE(senderTimestamp);
    writer.writeString(text);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandGetContacts([int? since]) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.getContacts);
    if (since != null) {
      writer.writeUInt32LE(since);
    }
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandGetDeviceTime() async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.getDeviceTime);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSetDeviceTime(int epochSecs) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.setDeviceTime);
    writer.writeUInt32LE(epochSecs);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSendSelfAdvert(int type) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.sendSelfAdvert);
    writer.writeByte(type);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSetAdvertName(String name) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.setAdvertName);
    writer.writeString(name);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandAddUpdateContact(
      Uint8List publicKey, int type, int flags, int outPathLen, Uint8List outPath, String advName, int lastAdvert, int advLat, int advLon) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.addUpdateContact);
    writer.writeBytes(publicKey);
    writer.writeByte(type);
    writer.writeByte(flags);
    writer.writeByte(outPathLen);
    writer.writeBytes(outPath); // 64 bytes
    writer.writeCString(advName, 32); // 32 bytes
    writer.writeUInt32LE(lastAdvert);
    writer.writeUInt32LE(advLat);
    writer.writeUInt32LE(advLon);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSyncNextMessage() async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.syncNextMessage);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSetRadioParams(int radioFreq, int radioBw, int radioSf, int radioCr) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.setRadioParams);
    writer.writeUInt32LE(radioFreq);
    writer.writeUInt32LE(radioBw);
    writer.writeByte(radioSf);
    writer.writeByte(radioCr);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSetTxPower(int txPower) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.setTxPower);
    writer.writeByte(txPower);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandResetPath(Uint8List pubKey) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.resetPath);
    writer.writeBytes(pubKey); // 32 bytes
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSetAdvertLatLon(int lat, int lon) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.setAdvertLatLon);
    writer.writeInt32LE(lat);
    writer.writeInt32LE(lon);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandRemoveContact(Uint8List pubKey) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.removeContact);
    writer.writeBytes(pubKey); // 32 bytes
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandShareContact(Uint8List pubKey) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.shareContact);
    writer.writeBytes(pubKey); // 32 bytes
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandExportContact([Uint8List? pubKey]) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.exportContact);
    if (pubKey != null) {
      writer.writeBytes(pubKey); // 32 bytes
    }
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandImportContact(Uint8List advertPacketBytes) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.importContact);
    writer.writeBytes(advertPacketBytes); // raw advert packet bytes
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandReboot() async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.reboot);
    writer.writeString("reboot");
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandGetBatteryVoltage() async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.getBatteryVoltage);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandDeviceQuery(int appTargetVer) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.deviceQuery);
    writer.writeByte(appTargetVer); // e.g: 1
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandExportPrivateKey() async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.exportPrivateKey);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandImportPrivateKey(Uint8List privateKey) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.importPrivateKey);
    writer.writeBytes(privateKey);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSendRawData(Uint8List path, Uint8List rawData) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.sendRawData);
    writer.writeByte(path.length);
    writer.writeBytes(path);
    writer.writeBytes(rawData);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSendLogin(Uint8List publicKey, String password) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.sendLogin);
    writer.writeBytes(publicKey); // 32 bytes
    writer.writeString(password); // password is remainder of frame, max 15 characters
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSendStatusReq(Uint8List publicKey) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.sendStatusReq);
    writer.writeBytes(publicKey); // 32 bytes
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSendTelemetryReq(Uint8List publicKey) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.sendTelemetryReq);
    writer.writeByte(0); // reserved
    writer.writeByte(0); // reserved
    writer.writeByte(0); // reserved
    writer.writeBytes(publicKey); // 32 bytes
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSendBinaryReq(Uint8List publicKey, Uint8List requestCodeAndParams) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.sendBinaryReq);
    writer.writeBytes(publicKey); // 32 bytes
    writer.writeBytes(requestCodeAndParams);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandGetChannel(int channelIdx) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.getChannel);
    writer.writeByte(channelIdx);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSetChannel(int channelIdx, String name, Uint8List secret) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.setChannel);
    writer.writeByte(channelIdx);
    writer.writeCString(name, 32);
    writer.writeBytes(secret);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSignStart() async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.signStart);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSignData(Uint8List dataToSign) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.signData);
    writer.writeBytes(dataToSign);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSignFinish() async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.signFinish);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSendTracePath(int tag, int auth, Uint8List path) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.sendTracePath);
    writer.writeUInt32LE(tag);
    writer.writeUInt32LE(auth);
    writer.writeByte(0); // flags
    writer.writeBytes(path);
    await sendToRadioFrame(writer.toBytes());
  }

  Future<void> sendCommandSetOtherParams(int manualAddContacts) async {
    final writer = BufferWriter();
    writer.writeByte(CommandCodes.setOtherParams);
    writer.writeByte(manualAddContacts); // 0 or 1
    await sendToRadioFrame(writer.toBytes());
  }
}
