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

  // region Device Settings
  @override
  Future<void> startHeartBeat(int seconds, Function onHbt, Function onTimeout) {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<void> stopHeartBeat() {
    // TODO: implement
    throw UnimplementedError();
  }
  // endregion Device Settings

  // region RFID Settings
  @override
  Future<void> setMode(String mode) {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<String?> getMode() {
    // TODO: implement
    throw UnimplementedError();
  }
  // endregion RFID Settings

  // region Tag Operations
  @override
  Future<List<HfInventoryResult>> inventory() {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<void> startContinuousInventory() {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<void> stopContinuousInventory() {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<void> selectTag(HfTag tag) {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<String> read(int block) {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<void> write(int block, String data) {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<Map<String, TagType>> detectTagTypes() {
    // TODO: implement
    throw UnimplementedError();
  }
  // endregion Tag Operations

  // region ISO15693 Commands
  @override
  Future<void> setAfi(int afi) {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<int?> getAfi() {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<void> writeAfi(int afi, bool optionsFlag) {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<void> lockAfi(bool optionsFlag) {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<void> writeDsfid(int dsfid, bool optionsFlag) {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<void> lockDsfid(bool optionsFlag) {
    // TODO: implement
    throw UnimplementedError();
  }
  // endregion ISO15693 Commands

  // region ISO14A Commands
  // region Mifare Classic Commands
  @override
  Future<void> mfcAuth(int block, Uint8List key, MfcKeyType keyType) {
    // TODO: implement
    throw UnimplementedError();
  }
  // endregion Mifare Classic Commands

  // region NTAG / Mifare Ultralight Commands
  @override
  Future<String> authNtag(String password) {
    // TODO: implement npAuth
    throw UnimplementedError();
  }

  @override
  Future<String> setNtagAuth(String password, String acknowledge) {
    // TODO: implement setNpAuth
    throw UnimplementedError();
  }

  @override
  Future<(int, bool, int)> getNtagAccessConfiguration() {
    // TODO: implement getNtagAccessConfiguration
    throw UnimplementedError();
  }

  @override
  Future<(bool, bool)> getNtagCounterConfiguration() {
    // TODO: implement getNtagCounterConfiguration
    throw UnimplementedError();
  }

  @override
  Future<(NtagMirrorMode, int, int)> getNtagMirrorConfiguration() {
    // TODO: implement getNtagMirrorConfiguration
    throw UnimplementedError();
  }

  @override
  Future<bool> getNtagModulationConfiguration() {
    // TODO: implement getNtagModulationConfiguration
    throw UnimplementedError();
  }

  @override
  Future<void> lockNtagConfiguration() {
    // TODO: implement lockNtagConfiguration
    throw UnimplementedError();
  }

  @override
  Future<void> lockNtagPagePermanently(int page) {
    // TODO: implement lockNtagPagePermanently
    throw UnimplementedError();
  }

  @override
  Future<void> readNtagNfcCounter() {
    // TODO: implement readNtagNfcCounter
    throw UnimplementedError();
  }

  @override
  Future<void> setNtagAccessConfiguration(int auth, bool readProtection, int authLimit) {
    // TODO: implement setNtagAccessConfiguration
    throw UnimplementedError();
  }

  @override
  Future<void> setNtagBlockLock(int page) {
    // TODO: implement setNtagBlockLock
    throw UnimplementedError();
  }

  @override
  Future<void> setNtagCounterConfiguration(bool enableNfcCounter, bool enablePasswordProtection) {
    // TODO: implement setNtagCounterConfiguration
    throw UnimplementedError();
  }

  @override
  Future<void> setNtagMirrorConfiguration(NtagMirrorMode mode, int page, int byte) {
    // TODO: implement setNtagMirrorConfiguration
    throw UnimplementedError();
  }

  @override
  Future<void> setNtagModulationConfiguration(bool enableModulation) {
    // TODO: implement setNtagModulationConfiguration
    throw UnimplementedError();
  }
  // endregion NTAG / Mifare Ultralight Commands
  // endregion ISO14A Commands

  // region Feedback
  @override
  Future<void> playFeedback(int feedbackId) {
    // TODO: implement
    throw UnimplementedError();
  }
  // endregion Feedback
}
