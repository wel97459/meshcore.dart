import 'buffer_reader.dart';
import 'connection.dart';
import 'constants.dart';

mixin ConnectionResponses on Connection {
  @override
  void dispatchResponse(int code, BufferReader reader) {
    if (code == ResponseCodes.ok) {
      onOkResponse(reader);
    } else if (code == ResponseCodes.err) {
      onErrResponse(reader);
    } else if (code == ResponseCodes.selfInfo) {
      onSelfInfoResponse(reader);
    } else if (code == ResponseCodes.currTime) {
      onCurrTimeResponse(reader);
    } else if (code == ResponseCodes.noMoreMessages) {
      onNoMoreMessagesResponse(reader);
    } else if (code == ResponseCodes.contactMsgRecv) {
      onContactMsgRecvResponse(reader);
    } else if (code == ResponseCodes.channelMsgRecv) {
      onChannelMsgRecvResponse(reader);
    } else if (code == ResponseCodes.contactsStart) {
      onContactsStartResponse(reader);
    } else if (code == ResponseCodes.contact) {
      onContactResponse(reader);
    } else if (code == ResponseCodes.endOfContacts) {
      onEndOfContactsResponse(reader);
    } else if (code == ResponseCodes.sent) {
      onSentResponse(reader);
    } else if (code == ResponseCodes.exportContact) {
      onExportContactResponse(reader);
    } else if (code == ResponseCodes.batteryVoltage) {
      onBatteryVoltageResponse(reader);
    } else if (code == ResponseCodes.deviceInfo) {
      onDeviceInfoResponse(reader);
    } else if (code == ResponseCodes.privateKey) {
      onPrivateKeyResponse(reader);
    } else if (code == ResponseCodes.disabled) {
      onDisabledResponse(reader);
    } else if (code == ResponseCodes.channelInfo) {
      onChannelInfoResponse(reader);
    } else if (code == ResponseCodes.signStart) {
      onSignStartResponse(reader);
    } else if (code == ResponseCodes.signature) {
      onSignatureResponse(reader);
    } else if (code == PushCodes.advert) {
      onAdvertPush(reader);
    } else if (code == PushCodes.pathUpdated) {
      onPathUpdatedPush(reader);
    } else if (code == PushCodes.sendConfirmed) {
      onSendConfirmedPush(reader);
    } else if (code == PushCodes.msgWaiting) {
      onMsgWaitingPush(reader);
    } else if (code == PushCodes.rawData) {
      onRawDataPush(reader);
    } else if (code == PushCodes.loginSuccess) {
      onLoginSuccessPush(reader);
    } else if (code == PushCodes.statusResponse) {
      onStatusResponsePush(reader);
    } else if (code == PushCodes.logRxData) {
      onLogRxDataPush(reader);
    } else if (code == PushCodes.telemetryResponse) {
      onTelemetryResponsePush(reader);
    } else if (code == PushCodes.traceData) {
      onTraceDataPush(reader);
    } else if (code == PushCodes.newAdvert) {
      onNewAdvertPush(reader);
    } else if (code == PushCodes.binaryResponse) {
      onBinaryResponsePush(reader);
    } else {
      print('unhandled frame: code=$code');
    }
  }

  void onAdvertPush(BufferReader bufferReader) {
    emit(EventNames.advert, {
      'publicKey': bufferReader.readBytes(32),
    });
  }

  void onPathUpdatedPush(BufferReader bufferReader) {
    emit(EventNames.pathUpdated, {
      'publicKey': bufferReader.readBytes(32),
    });
  }

  void onSendConfirmedPush(BufferReader bufferReader) {
    emit(EventNames.sendConfirmed, {
      'ackCode': bufferReader.readUInt32LE(),
      'roundTrip': bufferReader.readUInt32LE(),
    });
  }

  void onMsgWaitingPush(BufferReader bufferReader) {
    emit(EventNames.msgWaiting, {});
  }

  void onRawDataPush(BufferReader bufferReader) {
    emit(EventNames.rawData, {
      'lastSnr': bufferReader.readInt8() / 4,
      'lastRssi': bufferReader.readInt8(),
      'reserved': bufferReader.readByte(),
      'payload': bufferReader.readRemainingBytes(),
    });
  }

  void onLoginSuccessPush(BufferReader bufferReader) {
    emit(EventNames.loginSuccess, {
      'reserved': bufferReader.readByte(),
      'pubKeyPrefix': bufferReader.readBytes(6),
    });
  }

  void onStatusResponsePush(BufferReader bufferReader) {
    emit(EventNames.statusResponse, {
      'reserved': bufferReader.readByte(),
      'pubKeyPrefix': bufferReader.readBytes(6),
      'statusData': bufferReader.readRemainingBytes(),
    });
  }

  void onLogRxDataPush(BufferReader bufferReader) {
    emit(EventNames.logRxData, {
      'lastSnr': bufferReader.readInt8() / 4,
      'lastRssi': bufferReader.readInt8(),
      'raw': bufferReader.readRemainingBytes(),
    });
  }

  void onTelemetryResponsePush(BufferReader bufferReader) {
    emit(EventNames.telemetryResponse, {
      'reserved': bufferReader.readByte(),
      'pubKeyPrefix': bufferReader.readBytes(6),
      'lppSensorData': bufferReader.readRemainingBytes(),
    });
  }

  void onBinaryResponsePush(BufferReader bufferReader) {
    emit(EventNames.binaryResponse, {
      'reserved': bufferReader.readByte(),
      'tag': bufferReader.readUInt32LE(),
      'responseData': bufferReader.readRemainingBytes(),
    });
  }

  void onTraceDataPush(BufferReader bufferReader) {
    final reserved = bufferReader.readByte();
    final pathLen = bufferReader.readUInt8();
    emit(EventNames.traceData, {
      'reserved': reserved,
      'pathLen': pathLen,
      'flags': bufferReader.readUInt8(),
      'tag': bufferReader.readUInt32LE(),
      'authCode': bufferReader.readUInt32LE(),
      'pathHashes': bufferReader.readBytes(pathLen),
      'pathSnrs': bufferReader.readBytes(pathLen),
      'lastSnr': bufferReader.readInt8() / 4,
    });
  }

  void onNewAdvertPush(BufferReader bufferReader) {
    emit(EventNames.newAdvert, {
      'publicKey': bufferReader.readBytes(32),
      'type': bufferReader.readByte(),
      'flags': bufferReader.readByte(),
      'outPathLen': bufferReader.readInt8(),
      'outPath': bufferReader.readBytes(64),
      'advName': bufferReader.readCString(32),
      'lastAdvert': bufferReader.readUInt32LE(),
      'advLat': bufferReader.readUInt32LE(),
      'advLon': bufferReader.readUInt32LE(),
      'lastMod': bufferReader.readUInt32LE(),
    });
  }

  void onOkResponse(BufferReader bufferReader) {
    emit(EventNames.ok, {});
  }

  void onErrResponse(BufferReader bufferReader) {
    final errCode = bufferReader.getRemainingBytesCount() > 0 ? bufferReader.readByte() : null;
    emit(EventNames.err, {
      'errCode': errCode,
    });
  }

  void onContactsStartResponse(BufferReader bufferReader) {
    emit(EventNames.contactsStart, {
      'count': bufferReader.readUInt32LE(),
    });
  }

  void onContactResponse(BufferReader bufferReader) {
    emit(EventNames.contact, {
      'publicKey': bufferReader.readBytes(32),
      'type': bufferReader.readByte(),
      'flags': bufferReader.readByte(),
      'outPathLen': bufferReader.readInt8(),
      'outPath': bufferReader.readBytes(64),
      'advName': bufferReader.readCString(32),
      'lastAdvert': bufferReader.readUInt32LE(),
      'advLat': bufferReader.readUInt32LE(),
      'advLon': bufferReader.readUInt32LE(),
      'lastMod': bufferReader.readUInt32LE(),
    });
  }

  void onEndOfContactsResponse(BufferReader bufferReader) {
    emit(EventNames.endOfContacts, {
      'mostRecentLastmod': bufferReader.readUInt32LE(),
    });
  }

  void onSentResponse(BufferReader bufferReader) {
    emit(EventNames.sent, {
      'result': bufferReader.readInt8(),
      'expectedAckCrc': bufferReader.readUInt32LE(),
      'estTimeout': bufferReader.readUInt32LE(),
    });
  }

  void onExportContactResponse(BufferReader bufferReader) {
    emit(EventNames.exportContact, {
      'advertPacketBytes': bufferReader.readRemainingBytes(),
    });
  }

  void onBatteryVoltageResponse(BufferReader bufferReader) {
    emit(EventNames.batteryVoltage, {
      'batteryMilliVolts': bufferReader.readUInt16LE(),
    });
  }

  void onDeviceInfoResponse(BufferReader bufferReader) {
    emit(EventNames.deviceInfo, {
      'firmwareVer': bufferReader.readInt8(),
      'reserved': bufferReader.readBytes(6),
      'firmware_build_date': bufferReader.readCString(12),
      'manufacturerModel': bufferReader.readString(),
    });
  }

  void onPrivateKeyResponse(BufferReader bufferReader) {
    emit(EventNames.privateKey, {
      'privateKey': bufferReader.readBytes(64),
    });
  }

  void onDisabledResponse(BufferReader bufferReader) {
    emit(EventNames.disabled, {});
  }

  void onChannelInfoResponse(BufferReader bufferReader) {
    final idx = bufferReader.readUInt8();
    final name = bufferReader.readCString(32);
    final remainingBytesLength = bufferReader.getRemainingBytesCount();

    if (remainingBytesLength == 16) {
      emit(EventNames.channelInfo, {
        'channelIdx': idx,
        'name': name,
        'secret': bufferReader.readBytes(remainingBytesLength),
      });
    } else {
      print('ChannelInfo has unexpected key length: $remainingBytesLength');
    }
  }

  void onSignStartResponse(BufferReader bufferReader) {
    emit(EventNames.signStart, {
      'reserved': bufferReader.readByte(),
      'maxSignDataLen': bufferReader.readUInt32LE(),
    });
  }

  void onSignatureResponse(BufferReader bufferReader) {
    emit(EventNames.signature, {
      'signature': bufferReader.readBytes(64),
    });
  }

  void onSelfInfoResponse(BufferReader bufferReader) {
    emit(EventNames.selfInfo, {
      'type': bufferReader.readByte(),
      'txPower': bufferReader.readByte(),
      'maxTxPower': bufferReader.readByte(),
      'publicKey': bufferReader.readBytes(32),
      'advLat': bufferReader.readInt32LE(),
      'advLon': bufferReader.readInt32LE(),
      'reserved': bufferReader.readBytes(3),
      'manualAddContacts': bufferReader.readByte(),
      'radioFreq': bufferReader.readUInt32LE(),
      'radioBw': bufferReader.readUInt32LE(),
      'radioSf': bufferReader.readByte(),
      'radioCr': bufferReader.readByte(),
      'name': bufferReader.readString(),
    });
  }

  void onCurrTimeResponse(BufferReader bufferReader) {
    emit(EventNames.currTime, {
      'epochSecs': bufferReader.readUInt32LE(),
    });
  }

  void onNoMoreMessagesResponse(BufferReader bufferReader) {
    emit(EventNames.noMoreMessages, {});
  }

  void onContactMsgRecvResponse(BufferReader bufferReader) {
    emit(EventNames.contactMsgRecv, {
      'pubKeyPrefix': bufferReader.readBytes(6),
      'pathLen': bufferReader.readByte(),
      'txtType': bufferReader.readByte(),
      'senderTimestamp': bufferReader.readUInt32LE(),
      'text': bufferReader.readString(),
    });
  }

  void onChannelMsgRecvResponse(BufferReader bufferReader) {
    emit(EventNames.channelMsgRecv, {
      'channelIdx': bufferReader.readInt8(),
      'pathLen': bufferReader.readByte(),
      'txtType': bufferReader.readByte(),
      'senderTimestamp': bufferReader.readUInt32LE(),
      'text': bufferReader.readString(),
    });
  }
}
