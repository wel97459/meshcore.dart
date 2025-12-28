import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'connection.dart';
import 'connection_commands.dart';
import 'connection_responses.dart';
import 'constants.dart';
import 'buffer_writer.dart';
import 'buffer_reader.dart';
import 'packet.dart';
import 'buffer_utils.dart';

mixin ConnectionHelpers on Connection, ConnectionCommands, ConnectionResponses {
  Future<dynamic> getSelfInfo({Duration? timeout}) async {
    final future = waitForResponse(ResponseCodes.selfInfo, timeout: timeout);
    await sendCommandAppStart();
    return await future;
  }

  Future<void> sendAdvert(int type) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandSendSelfAdvert(type);

    return await Future.any([
      ok.then((_) => null),
      err.then((_) => throw Exception('Failed to send advert')),
    ]);
  }

  Future<void> sendFloodAdvert() async {
    return await sendAdvert(SelfAdvertTypes.flood);
  }

  Future<void> sendZeroHopAdvert() async {
    return await sendAdvert(SelfAdvertTypes.zeroHop);
  }

  Future<void> setAdvertName(String name) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandSetAdvertName(name);

    return await Future.any([
      ok.then((_) => null),
      err.then((_) => throw Exception('Failed to set advert name')),
    ]);
  }

  Future<void> setAdvertLatLong(int latitude, int longitude) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandSetAdvertLatLon(latitude, longitude);

    return await Future.any([
      ok.then((_) => null),
      err.then((_) => throw Exception('Failed to set advert lat/lon')),
    ]);
  }

  Future<void> setTxPower(int txPower) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandSetTxPower(txPower);

    return await Future.any([
      ok.then((_) => null),
      err.then((_) => throw Exception('Failed to set tx power')),
    ]);
  }

  Future<void> setRadioParams(int radioFreq, int radioBw, int radioSf, int radioCr) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandSetRadioParams(radioFreq, radioBw, radioSf, radioCr);

    return await Future.any([
      ok.then((_) => null),
      err.then((_) => throw Exception('Failed to set radio params')),
    ]);
  }

  Future<List<dynamic>> getContacts() async {
    final completer = Completer<List<dynamic>>();
    final contacts = <dynamic>[];

    void onContact(dynamic contact) {
      contacts.add(contact);
    }

    on(ResponseCodes.contact, onContact);

    once(ResponseCodes.endOfContacts, (_) {
      off(ResponseCodes.contact, onContact);
      completer.complete(contacts);
    });

    try {
      await sendCommandGetContacts();
    } catch (e) {
      off(ResponseCodes.contact, onContact);
      completer.completeError(e);
    }

    return await completer.future;
  }

  Future<dynamic> findContactByName(String name) async {
    final contacts = await getContacts();
    for (final contact in contacts) {
      if (contact['advName'] == name) {
        return contact;
      }
    }
    return null;
  }

  Future<dynamic> findContactByPublicKeyPrefix(Uint8List pubKeyPrefix) async {
    final contacts = await getContacts();
    for (final contact in contacts) {
      final contactPubKey = contact['publicKey'] as Uint8List;
      final contactPubKeyPrefix = contactPubKey.sublist(0, pubKeyPrefix.length);
      if (BufferUtils.areBuffersEqual(pubKeyPrefix, contactPubKeyPrefix)) {
        return contact;
      }
    }
    return null;
  }

  Future<dynamic> sendTextMessage(Uint8List contactPublicKey, String text, {int? type}) async {
    final sent = waitForResponse(ResponseCodes.sent);
    final err = waitForResponse(ResponseCodes.err);

    final txtType = type ?? TxtTypes.plain;
    final attempt = 0;
    final senderTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await sendCommandSendTxtMsg(txtType, attempt, senderTimestamp, contactPublicKey, text);

    return await Future.any([
      sent,
      err.then((_) => throw Exception('Failed to send text message')),
    ]);
  }

  Future<void> sendChannelTextMessage(int channelIdx, String text) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    final txtType = TxtTypes.plain;
    final senderTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await sendCommandSendChannelTxtMsg(txtType, channelIdx, senderTimestamp, text);

    return await Future.any([
      ok.then((_) => null),
      err.then((_) => throw Exception('Failed to send channel text message')),
    ]);
  }

  Future<Map<String, dynamic>?> syncNextMessage() async {
    final c = Completer<Map<String, dynamic>?>();
    late void Function(dynamic) l1, l2, l3;

    l1 = (m) {
      if (!c.isCompleted) {
        off(ResponseCodes.contactMsgRecv, l1);
        off(ResponseCodes.channelMsgRecv, l2);
        off(ResponseCodes.noMoreMessages, l3);
        c.complete({'contactMessage': m});
      }
    };
    l2 = (m) {
      if (!c.isCompleted) {
        off(ResponseCodes.contactMsgRecv, l1);
        off(ResponseCodes.channelMsgRecv, l2);
        off(ResponseCodes.noMoreMessages, l3);
        c.complete({'channelMessage': m});
      }
    };
    l3 = (m) {
      if (!c.isCompleted) {
        off(ResponseCodes.contactMsgRecv, l1);
        off(ResponseCodes.channelMsgRecv, l2);
        off(ResponseCodes.noMoreMessages, l3);
        c.complete(null);
      }
    };

    on(ResponseCodes.contactMsgRecv, l1);
    on(ResponseCodes.channelMsgRecv, l2);
    on(ResponseCodes.noMoreMessages, l3);

    await sendCommandSyncNextMessage();
    return await c.future;
  }

  Future<List<Map<String, dynamic>>> getWaitingMessages() async {
    final waitingMessages = <Map<String, dynamic>>[];
    while (true) {
      final message = await syncNextMessage();
      if (message == null) break;
      waitingMessages.add(message);
    }
    return waitingMessages;
  }

  Future<dynamic> getDeviceTime() async {
    final currTime = waitForResponse(ResponseCodes.currTime);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandGetDeviceTime();

    return await Future.any([
      currTime,
      err.then((_) => throw Exception('Failed to get device time')),
    ]);
  }

  Future<dynamic> setDeviceTime(int epochSecs) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandSetDeviceTime(epochSecs);

    return await Future.any([
      ok,
      err.then((_) => throw Exception('Failed to set device time')),
    ]);
  }

  Future<void> syncDeviceTime() async {
    await setDeviceTime(DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  Future<dynamic> importContact(Uint8List advertPacketBytes) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandImportContact(advertPacketBytes);

    return await Future.any([
      ok,
      err.then((_) => throw Exception('Failed to import contact')),
    ]);
  }

  Future<dynamic> exportContact([Uint8List? pubKey]) async {
    final exportContactResp = waitForResponse(ResponseCodes.exportContact);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandExportContact(pubKey);

    return await Future.any([
      exportContactResp,
      err.then((_) => throw Exception('Failed to export contact')),
    ]);
  }

  Future<dynamic> shareContact(Uint8List pubKey) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandShareContact(pubKey);

    return await Future.any([
      ok,
      err.then((_) => throw Exception('Failed to share contact')),
    ]);
  }

  Future<void> removeContact(Uint8List pubKey) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandRemoveContact(pubKey);

    await Future.any([
      ok,
      err.then((_) => throw Exception('Failed to remove contact')),
    ]);
  }

  Future<void> addOrUpdateContact(Uint8List publicKey, int type, int flags, int outPathLen, Uint8List outPath, String advName, int lastAdvert, int advLat, int advLon) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandAddUpdateContact(publicKey, type, flags, outPathLen, outPath, advName, lastAdvert, advLat, advLon);

    await Future.any([
      ok,
      err.then((_) => throw Exception('Failed to add/update contact')),
    ]);
  }

  Future<void> setContactPath(Map<String, dynamic> contact, Uint8List path) async {
    const maxPathLength = 64;
    final outPath = Uint8List(maxPathLength);

    for (var i = 0; i < path.length && i < maxPathLength; i++) {
      outPath[i] = path[i];
    }

    contact['outPathLen'] = path.length;
    contact['outPath'] = outPath;

    await addOrUpdateContact(
      contact['publicKey'],
      contact['type'],
      contact['flags'],
      contact['outPathLen'],
      contact['outPath'],
      contact['advName'],
      contact['lastAdvert'],
      contact['advLat'],
      contact['advLon'],
    );
  }

  Future<void> resetPath(Uint8List pubKey) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandResetPath(pubKey);

    await Future.any([
      ok,
      err.then((_) => throw Exception('Failed to reset path')),
    ]);
  }

  Future<void> reboot() async {
    final err = waitForResponse(ResponseCodes.err);

    // assume device rebooted after a short delay
    final timeout = Future.delayed(const Duration(seconds: 1), () => null);

    await sendCommandReboot();

    return await Future.any([
      timeout,
      err.then((_) => throw Exception('Failed to reboot')),
    ]);
  }

  Future<dynamic> getBatteryVoltage() async {
    final batteryVoltage = waitForResponse(ResponseCodes.batteryVoltage);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandGetBatteryVoltage();

    return await Future.any([
      batteryVoltage,
      err.then((_) => throw Exception('Failed to get battery voltage')),
    ]);
  }

  Future<dynamic> deviceQuery(int appTargetVer) async {
    final deviceInfo = waitForResponse(ResponseCodes.deviceInfo);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandDeviceQuery(appTargetVer);

    return await Future.any([
      deviceInfo,
      err.then((_) => throw Exception('Failed to query device')),
    ]);
  }

  Future<dynamic> exportPrivateKey() async {
    final privateKey = waitForResponse(ResponseCodes.privateKey);
    final err = waitForResponse(ResponseCodes.err);
    final disabled = waitForResponse(ResponseCodes.disabled);

    await sendCommandExportPrivateKey();

    return await Future.any([
      privateKey,
      err.then((_) => throw Exception('Failed to export private key')),
      disabled.then((_) => throw Exception('disabled')),
    ]);
  }

  Future<dynamic> importPrivateKey(Uint8List privateKey) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);
    final disabled = waitForResponse(ResponseCodes.disabled);

    await sendCommandImportPrivateKey(privateKey);

    return await Future.any([
      ok,
      err.then((_) => throw Exception('Failed to import private key')),
      disabled.then((_) => throw Exception('disabled')),
    ]);
  }

  Future<dynamic> login(Uint8List contactPublicKey, String password, {Duration extraTimeout = const Duration(seconds: 1)}) async {
    final publicKeyPrefix = contactPublicKey.sublist(0, 6);
    final sent = waitForResponse(ResponseCodes.sent);
    final loginSuccess = waitForResponse(PushCodes.loginSuccess);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandSendLogin(contactPublicKey, password);

    try {
      final response = await Future.any([
        sent,
        err.then((_) => throw Exception('Failed to send login')),
      ]);

      if (response is Map<String, dynamic>) {
        final estTimeout = Duration(milliseconds: response['estTimeout']) + extraTimeout;
        final success = await loginSuccess.timeout(estTimeout);
        
        if (!BufferUtils.areBuffersEqual(publicKeyPrefix, success['pubKeyPrefix'])) {
          throw Exception('Login success is not for this request');
        }
        return success;
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  Future<dynamic> getStatus(Uint8List contactPublicKey, {Duration extraTimeout = const Duration(seconds: 1)}) async {
    final publicKeyPrefix = contactPublicKey.sublist(0, 6);
    final sent = waitForResponse(ResponseCodes.sent);
    final statusResponse = waitForResponse(PushCodes.statusResponse);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandSendStatusReq(contactPublicKey);

    final response = await Future.any([
      sent,
      err.then((_) => throw Exception('Failed to send status request')),
    ]);

    if (response is Map<String, dynamic>) {
      final estTimeout = Duration(milliseconds: response['estTimeout']) + extraTimeout;
      final status = await statusResponse.timeout(estTimeout);

      if (!BufferUtils.areBuffersEqual(publicKeyPrefix, status['pubKeyPrefix'])) {
        throw Exception('Status response is not for this request');
      }

      final reader = BufferReader(status['statusData']);
      return {
        'batt_milli_volts': reader.readUInt16LE(),
        'curr_tx_queue_len': reader.readUInt16LE(),
        'noise_floor': reader.readInt16LE(),
        'last_rssi': reader.readInt16LE(),
        'n_packets_recv': reader.readUInt32LE(),
        'n_packets_sent': reader.readUInt32LE(),
        'total_air_time_secs': reader.readUInt32LE(),
        'total_up_time_secs': reader.readUInt32LE(),
        'n_sent_flood': reader.readUInt32LE(),
        'n_sent_direct': reader.readUInt32LE(),
        'n_recv_flood': reader.readUInt32LE(),
        'n_recv_direct': reader.readUInt32LE(),
        'err_events': reader.readUInt16LE(),
        'last_snr': reader.readInt16LE(),
        'n_direct_dups': reader.readUInt16LE(),
        'n_flood_dups': reader.readUInt16LE(),
      };
    }
    return null;
  }

  Future<dynamic> getTelemetry(Uint8List contactPublicKey, {Duration extraTimeout = const Duration(seconds: 1)}) async {
    final publicKeyPrefix = contactPublicKey.sublist(0, 6);
    final sent = waitForResponse(ResponseCodes.sent);
    final telemetryResponse = waitForResponse(PushCodes.telemetryResponse);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandSendTelemetryReq(contactPublicKey);

    final response = await Future.any([
      sent,
      err.then((_) => throw Exception('Failed to send telemetry request')),
    ]);

    if (response is Map<String, dynamic>) {
      final estTimeout = Duration(milliseconds: response['estTimeout']) + extraTimeout;
      final telemetry = await telemetryResponse.timeout(estTimeout);

      if (!BufferUtils.areBuffersEqual(publicKeyPrefix, telemetry['pubKeyPrefix'])) {
        throw Exception('Telemetry response is not for this request');
      }

      return telemetry;
    }
    return null;
  }

  Future<Uint8List?> sendBinaryRequest(Uint8List contactPublicKey, Uint8List requestCodeAndParams, {Duration extraTimeout = const Duration(seconds: 1)}) async {
    final sent = waitForResponse(ResponseCodes.sent);
    final binaryResponse = waitForResponse(PushCodes.binaryResponse);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandSendBinaryReq(contactPublicKey, requestCodeAndParams);

    final response = await Future.any([
      sent,
      err.then((_) => throw Exception('Failed to send binary request')),
    ]);

    if (response is Map<String, dynamic>) {
      final tag = response['expectedAckCrc'];
      final estTimeout = Duration(milliseconds: response['estTimeout']) + extraTimeout;
      
      final result = await binaryResponse.timeout(estTimeout);
      if (result['tag'] != tag) {
        throw Exception('Binary response tag mismatch');
      }
      return result['responseData'];
    }
    return null;
  }

  Future<dynamic> pingRepeaterZeroHop(Uint8List contactPublicKey, {Duration? timeout}) async {
    final startMillis = DateTime.now().millisecondsSinceEpoch;
    
    final writer = BufferWriter();
    writer.writeUInt32LE(startMillis);
    writer.writeBytes(Uint8List.fromList([0x70, 0x69, 0x6E, 0x67])); // "ping"
    writer.writeBytes(contactPublicKey.sublist(0, 2));
    final rawBytes = writer.toBytes();

    final completer = Completer<dynamic>();
    
    void onLogRxData(dynamic response) {
      final endMillis = DateTime.now().millisecondsSinceEpoch;
      final duration = endMillis - startMillis;

      final packet = Packet.fromBytes(response['raw']);
      if (packet.payloadType != PayloadType.rawCustom) return;
      if (!BufferUtils.areBuffersEqual(packet.payload, rawBytes)) return;

      off(PushCodes.logRxData, onLogRxData);
      if (!completer.isCompleted) {
        completer.complete({
          'rtt': duration,
          'snr': response['lastSnr'],
          'rssi': response['lastRssi'],
        });
      }
    }

    on(PushCodes.logRxData, onLogRxData);
    
    once(ResponseCodes.err, (_) {
      off(PushCodes.logRxData, onLogRxData);
      if (!completer.isCompleted) completer.completeError(Exception('Error during ping'));
    });

    if (timeout != null) {
      Timer(timeout, () {
        off(PushCodes.logRxData, onLogRxData);
        if (!completer.isCompleted) completer.completeError(TimeoutException('Ping timed out'));
      });
    }

    await sendCommandSendRawData(contactPublicKey.sublist(0, 1), rawBytes);
    return await completer.future;
  }

  Future<dynamic> getChannel(int channelIdx) async {
    final channelInfo = waitForResponse(ResponseCodes.channelInfo);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandGetChannel(channelIdx);

    return await Future.any([
      channelInfo,
      err.then((_) => throw Exception('Failed to get channel')),
    ]);
  }

  Future<void> setChannel(int channelIdx, String name, Uint8List secret) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandSetChannel(channelIdx, name, secret);

    await Future.any([
      ok,
      err.then((_) => throw Exception('Failed to set channel')),
    ]);
  }

  Future<void> deleteChannel(int channelIdx) async {
    return await setChannel(channelIdx, "", Uint8List(16));
  }

  Future<List<dynamic>> getChannels() async {
    final channels = <dynamic>[];
    var idx = 0;
    while (true) {
      try {
        final channel = await getChannel(idx);
        channels.add(channel);
        idx++;
      } catch (e) {
        break;
      }
    }
    return channels;
  }

  Future<dynamic> findChannelByName(String name) async {
    final channels = await getChannels();
    for (final channel in channels) {
      if (channel['name'] == name) return channel;
    }
    return null;
  }

  Future<dynamic> findChannelBySecret(Uint8List secret) async {
    final channels = await getChannels();
    for (final channel in channels) {
      if (BufferUtils.areBuffersEqual(secret, channel['secret'])) return channel;
    }
    return null;
  }

  Future<Uint8List> sign(Uint8List data) async {
    final completer = Completer<Uint8List>();
    final bufferReader = BufferReader(data);
    const chunkSize = 128;

    Future<void> sendNextChunk() async {
      Uint8List chunk;
      if (bufferReader.getRemainingBytesCount() >= chunkSize) {
        chunk = bufferReader.readBytes(chunkSize);
      } else {
        chunk = bufferReader.readRemainingBytes();
      }
      await sendCommandSignData(chunk);
    }

    void onOk(_) async {
      if (bufferReader.getRemainingBytesCount() > 0) {
        await sendNextChunk();
      } else {
        await sendCommandSignFinish();
      }
    }

    void onSignStart(dynamic response) async {
      if (bufferReader.getRemainingBytesCount() > response['maxSignDataLen']) {
        off(ResponseCodes.ok, onOk);
        completer.completeError(Exception('data_too_long'));
        return;
      }
      await sendNextChunk();
    }

    void onSignature(dynamic response) {
      off(ResponseCodes.ok, onOk);
      completer.complete(response['signature']);
    }

    void onErr(_) {
      off(ResponseCodes.ok, onOk);
      completer.completeError(Exception('Sign failed'));
    }

    on(ResponseCodes.ok, onOk);
    once(ResponseCodes.signStart, onSignStart);
    once(ResponseCodes.signature, onSignature);
    once(ResponseCodes.err, onErr);

    await sendCommandSignStart();
    return await completer.future;
  }

  Future<void> setOtherParams(bool manualAddContacts) async {
    final ok = waitForResponse(ResponseCodes.ok);
    final err = waitForResponse(ResponseCodes.err);

    await sendCommandSetOtherParams(manualAddContacts ? 1 : 0);

    return await Future.any([
      ok.then((_) => null),
      err.then((_) => throw Exception('Failed to set other params')),
    ]);
  }

  Future<void> setAutoAddContacts() async {
    return await setOtherParams(false);
  }

  Future<void> setManualAddContacts() async {
    return await setOtherParams(true);
  }

  Future<dynamic> tracePath(Uint8List path, {Duration extraTimeout = Duration.zero}) async {
    final completer = Completer<dynamic>();
    final tag = Random().nextInt(1 << 32); // 0 to 2^32 - 1

    Timer? timeoutTimer;
    void Function(dynamic)? onSent;
    void Function(dynamic)? onTraceData;
    void Function(dynamic)? onErr;

    void cleanup() {
      timeoutTimer?.cancel();
      if (onSent != null) off(ResponseCodes.sent, onSent);
      if (onTraceData != null) off(PushCodes.traceData, onTraceData);
      if (onErr != null) off(ResponseCodes.err, onErr);
    }

    onSent = (response) {
      off(ResponseCodes.err, onErr!);
      
      final estTimeout = Duration(milliseconds: response['estTimeout']) + extraTimeout;
      timeoutTimer = Timer(estTimeout, () {
        cleanup();
        if (!completer.isCompleted) {
          completer.completeError(TimeoutException('Trace timed out'));
        }
      });
    };

    onTraceData = (response) {
      if (response['tag'] != tag) return; // Ignore if tag mismatch
      
      cleanup();
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    };

    onErr = (_) {
      cleanup();
      if (!completer.isCompleted) {
        completer.completeError(Exception('Trace failed'));
      }
    };

    on(ResponseCodes.sent, onSent);
    on(PushCodes.traceData, onTraceData);
    once(ResponseCodes.err, onErr);

    try {
      await sendCommandSendTracePath(tag, 0, path);
    } catch (e) {
      cleanup();
      completer.completeError(e);
    }

    return await completer.future;
  }

  Future<dynamic> getNeighbours(Uint8List publicKey, {
    int count = 10,
    int offset = 0,
    int orderBy = 0,
    int pubKeyPrefixLength = 8,
  }) async {
    final bufferWriter = BufferWriter();
    bufferWriter.writeByte(BinaryRequestTypes.getNeighbours);
    bufferWriter.writeByte(0); // request_version=0
    bufferWriter.writeByte(count);
    bufferWriter.writeUInt16LE(offset);
    bufferWriter.writeByte(orderBy);
    bufferWriter.writeByte(pubKeyPrefixLength);
    bufferWriter.writeUInt32LE(Random().nextInt(1 << 32)); // 4 bytes random blob

    // send binary request
    final responseData = await sendBinaryRequest(publicKey, bufferWriter.toBytes());
    if (responseData == null) return null;

    // parse response
    final bufferReader = BufferReader(responseData);
    final totalNeighboursCount = bufferReader.readUInt16LE();
    final resultsCount = bufferReader.readUInt16LE();

    // parse neighbours list
    final neighbours = [];
    for (var i = 0; i < resultsCount; i++) {
      // read info
      final publicKeyPrefix = bufferReader.readBytes(pubKeyPrefixLength);
      final heardSecondsAgo = bufferReader.readUInt32LE();
      final snr = bufferReader.readInt8() / 4;

      // add to list
      neighbours.add({
        'publicKeyPrefix': publicKeyPrefix,
        'heardSecondsAgo': heardSecondsAgo,
        'snr': snr,
      });
    }

    return {
      'totalNeighboursCount': totalNeighboursCount,
      'neighbours': neighbours,
    };
  }
}