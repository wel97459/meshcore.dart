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
    emit(PushCodes.advert, {
      'publicKey': bufferReader.readBytes(32),
    });
  }

  void onPathUpdatedPush(BufferReader bufferReader) {
    emit(PushCodes.pathUpdated, {
      'publicKey': bufferReader.readBytes(32),
    });
  }

  void onSendConfirmedPush(BufferReader bufferReader) {
    emit(PushCodes.sendConfirmed, {
      'ackCode': bufferReader.readUInt32LE(),
      'roundTrip': bufferReader.readUInt32LE(),
    });
  }

  void onMsgWaitingPush(BufferReader bufferReader) {
    emit(PushCodes.msgWaiting, {});
  }

  void onRawDataPush(BufferReader bufferReader) {
    emit(PushCodes.rawData, {
      'lastSnr': bufferReader.readInt8() / 4,
      'lastRssi': bufferReader.readInt8(),
      'reserved': bufferReader.readByte(),
      'payload': bufferReader.readRemainingBytes(),
    });
  }

  void onLoginSuccessPush(BufferReader bufferReader) {
    emit(PushCodes.loginSuccess, {
      'reserved': bufferReader.readByte(),
      'pubKeyPrefix': bufferReader.readBytes(6),
    });
  }

  void onStatusResponsePush(BufferReader bufferReader) {
    emit(PushCodes.statusResponse, {
      'reserved': bufferReader.readByte(),
      'pubKeyPrefix': bufferReader.readBytes(6),
      'statusData': bufferReader.readRemainingBytes(),
    });
  }

  void onLogRxDataPush(BufferReader bufferReader) {
    emit(PushCodes.logRxData, {
      'lastSnr': bufferReader.readInt8() / 4,
      'lastRssi': bufferReader.readInt8(),
      'raw': bufferReader.readRemainingBytes(),
    });
  }

  void onTelemetryResponsePush(BufferReader bufferReader) {
    emit(PushCodes.telemetryResponse, {
      'reserved': bufferReader.readByte(),
      'pubKeyPrefix': bufferReader.readBytes(6),
      'lppSensorData': bufferReader.readRemainingBytes(),
    });
  }

  void onBinaryResponsePush(BufferReader bufferReader) {
    emit(PushCodes.binaryResponse, {
      'reserved': bufferReader.readByte(),
      'tag': bufferReader.readUInt32LE(),
      'responseData': bufferReader.readRemainingBytes(),
    });
  }

  void onTraceDataPush(BufferReader bufferReader) {
    final reserved = bufferReader.readByte();
    final pathLen = bufferReader.readUInt8();
    emit(PushCodes.traceData, {
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
    emit(PushCodes.newAdvert, {
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
    emit(ResponseCodes.ok, {});
  }

  void onErrResponse(BufferReader bufferReader) {
    final errCode = bufferReader.getRemainingBytesCount() > 0 ? bufferReader.readByte() : null;
    emit(ResponseCodes.err, {
      'errCode': errCode,
    });
  }

  void onContactsStartResponse(BufferReader bufferReader) {
    emit(ResponseCodes.contactsStart, {
      'count': bufferReader.readUInt32LE(),
    });
  }

  void onContactResponse(BufferReader bufferReader) {
    emit(ResponseCodes.contact, {
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
    emit(ResponseCodes.endOfContacts, {
      'mostRecentLastmod': bufferReader.readUInt32LE(),
    });
  }

  void onSentResponse(BufferReader bufferReader) {
    emit(ResponseCodes.sent, {
      'result': bufferReader.readInt8(),
      'expectedAckCrc': bufferReader.readUInt32LE(),
      'estTimeout': bufferReader.readUInt32LE(),
    });
  }

  void onExportContactResponse(BufferReader bufferReader) {
    emit(ResponseCodes.exportContact, {
      'advertPacketBytes': bufferReader.readRemainingBytes(),
    });
  }

  void onBatteryVoltageResponse(BufferReader bufferReader) {
    emit(ResponseCodes.batteryVoltage, {
      'batteryMilliVolts': bufferReader.readUInt16LE(),
    });
  }

  void onDeviceInfoResponse(BufferReader bufferReader) {
    emit(ResponseCodes.deviceInfo, {
      'firmwareVer': bufferReader.readInt8(),
      'reserved': bufferReader.readBytes(6),
      'firmware_build_date': bufferReader.readCString(12),
      'manufacturerModel': bufferReader.readString(),
    });
  }

  void onPrivateKeyResponse(BufferReader bufferReader) {
    emit(ResponseCodes.privateKey, {
      'privateKey': bufferReader.readBytes(64),
    });
  }

  void onDisabledResponse(BufferReader bufferReader) {
    emit(ResponseCodes.disabled, {});
  }

  void onChannelInfoResponse(BufferReader bufferReader) {
    final idx = bufferReader.readUInt8();
    final name = bufferReader.readCString(32);
    final remainingBytesLength = bufferReader.getRemainingBytesCount();

    if (remainingBytesLength == 16) {
      emit(ResponseCodes.channelInfo, {
        'channelIdx': idx,
        'name': name,
        'secret': bufferReader.readBytes(remainingBytesLength),
      });
    } else {
      print('ChannelInfo has unexpected key length: $remainingBytesLength');
    }
  }

  void onSignStartResponse(BufferReader bufferReader) {
    emit(ResponseCodes.signStart, {
      'reserved': bufferReader.readByte(),
      'maxSignDataLen': bufferReader.readUInt32LE(),
    });
  }

  void onSignatureResponse(BufferReader bufferReader) {
    emit(ResponseCodes.signature, {
      'signature': bufferReader.readBytes(64),
    });
  }

  void onSelfInfoResponse(BufferReader bufferReader) {
    emit(ResponseCodes.selfInfo, {
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
    emit(ResponseCodes.currTime, {
      'epochSecs': bufferReader.readUInt32LE(),
    });
  }

  void onNoMoreMessagesResponse(BufferReader bufferReader) {
    emit(ResponseCodes.noMoreMessages, {});
  }

  void onContactMsgRecvResponse(BufferReader bufferReader) {
    emit(ResponseCodes.contactMsgRecv, {
      'pubKeyPrefix': bufferReader.readBytes(6),
      'pathLen': bufferReader.readByte(),
      'txtType': bufferReader.readByte(),
      'senderTimestamp': bufferReader.readUInt32LE(),
      'text': bufferReader.readString(),
    });
  }

  void onChannelMsgRecvResponse(BufferReader bufferReader) {
    emit(ResponseCodes.channelMsgRecv, {
      'channelIdx': bufferReader.readInt8(),
      'pathLen': bufferReader.readByte(),
      'txtType': bufferReader.readByte(),
      'senderTimestamp': bufferReader.readUInt32LE(),
      'text': bufferReader.readString(),
    });
  }
}