import 'dart:typed_data';

import 'package:dart_rfid_utils/dart_rfid_utils.dart';
import 'package:metratec_device/metratec_device.dart';
import 'package:reader_library/src/parser/parser_at.dart';
import 'package:reader_library/src/reader_hf/reader_hf.dart';

class HfGen1ReaderSettings extends HfReaderSettings {
  // Add HfGen1 reader settings here
}

class HfReaderGen1 extends HfReader {
  HfReaderGen1(CommInterface commInterface, HfGen1ReaderSettings settings)
      : super(ParserAt(commInterface, "\r"), settings) {}

  @override
  Future<List<HfInventoryResult>> inventory() {
    // TODO: implement inventory
    throw UnimplementedError();
  }

  @override
  Future<void> loadDeviceSettings() {
    // TODO: implement loadDeviceSettings
    throw UnimplementedError();
  }

  @override
  Future<void> mfcAuth(int block, Uint8List key, MfcKeyType keyType) {
    // TODO: implement mfcAuth
    throw UnimplementedError();
  }

  @override
  Future<String> read(int block) {
    // TODO: implement read
    throw UnimplementedError();
  }

  @override
  Future<void> selectTag(HfTag tag) {
    // TODO: implement selectTag
    throw UnimplementedError();
  }

  @override
  Future<void> setMode(String mode) {
    // TODO: implement setMode
    throw UnimplementedError();
  }

  @override
  Future<void> startContinuousInventory() {
    // TODO: implement startContinuousInventory
    throw UnimplementedError();
  }

  @override
  Future<void> startHeartBeat(int seconds, Function onHbt, Function onTimeout) {
    // TODO: implement startHeartBeat
    throw UnimplementedError();
  }

  @override
  Future<void> stopContinuousInventory() {
    // TODO: implement stopContinuousInventory
    throw UnimplementedError();
  }

  @override
  Future<void> stopHeartBeat() {
    // TODO: implement stopHeartBeat
    throw UnimplementedError();
  }

  @override
  Future<void> write(int block, String data) {
    // TODO: implement write
    throw UnimplementedError();
  }

  @override
  Future<Iterable<String>> detectTagTypes() {
    // TODO: implement detectTagType
    throw UnimplementedError();
  }

  @override
  Future<void> playFeedback(int feedbackId) {
    // TODO: implement playFeedback
    throw UnimplementedError();
  }
}
