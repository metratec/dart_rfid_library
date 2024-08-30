import 'package:dart_rfid_utils/dart_rfid_utils.dart';
import 'package:metratec_device/metratec_device.dart';
import 'package:dart_rfid_library/src/parser/parser_at.dart';
import 'package:dart_rfid_library/src/reader_hf/reader_hf.dart';

class HfAsciiReaderSettings extends HfReaderSettings {
  // Add HfGen1 reader settings here
}

class HfReaderAscii extends HfReader {
  HfReaderAscii(CommInterface commInterface, HfAsciiReaderSettings settings)
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

  @override
  Future<(int?, String?)> getRadioInterface() {
    // TODO: implement getRadioInterface
    throw UnimplementedError();
  }

  @override
  Future<void> setRadioInterface(int modulation, String subcarrier) {
    // TODO: implement setRadioInterface
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
  Future<void> deselectTag() {
    // TODO: implement deselectTag
    throw UnimplementedError();
  }

  @override
  Future<String> read(int block) {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<void> write(int block, String data, {bool? iso15OptionsFlag}) {
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
  Future<String> readAlike(String command) {
    // TODO: implement readAlike
    throw UnimplementedError();
  }

  @override
  Future<String> writeAlike(String command) {
    // TODO: implement writeAlike
    throw UnimplementedError();
  }

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
  @override
  Future<String> sendIso14Request(String command) {
    // TODO: implement sendIso14Request
    throw UnimplementedError();
  }

  // region Mifare Classic Commands
  @override
  Future<void> authMfc(int block, String key, MfcKeyType keyType) {
    // TODO: implement
    throw UnimplementedError();
  }

  @override
  Future<void> authMfcStoredKey(int block, int index) {
    // TODO: implement authMfcStoredKey
    throw UnimplementedError();
  }

  @override
  Future<void> decrementMfcBlockValue(int block, int decrementValue) {
    // TODO: implement decrementMfcBlockValue
    throw UnimplementedError();
  }

  @override
  Future<(bool, bool, bool)> getMfcAccessBits(int block) {
    // TODO: implement getMfcAccessBits
    throw UnimplementedError();
  }

  @override
  Future<void> incrementMfcBlockValue(int block, int incrementValue) {
    // TODO: implement incrementMfcBlockValue
    throw UnimplementedError();
  }

  @override
  Future<(int, int)> readMfcBlockValue(int block) {
    // TODO: implement readMfcBlockValue
    throw UnimplementedError();
  }

  @override
  Future<void> restoreMfcBlockValue(int block) {
    // TODO: implement restoreMfcBlockValue
    throw UnimplementedError();
  }

  @override
  Future<void> setMfcInternalKey(int index, String key, MfcKeyType keyType) {
    // TODO: implement setMfcInternalKey
    throw UnimplementedError();
  }

  @override
  Future<void> setMfcKeys(int block, String key1, String key2) {
    // TODO: implement setMfcKeys
    throw UnimplementedError();
  }

  @override
  Future<void> setMfcKeysAndAccessBits(int block, String key1, String key2, (bool, bool, bool) accessBits) {
    // TODO: implement setMfcKeysAndAccessBits
    throw UnimplementedError();
  }

  @override
  Future<void> transferMfcBlockValue(int block) {
    // TODO: implement transferMfcBlockValue
    throw UnimplementedError();
  }

  @override
  Future<void> writeMfcValueBlock(int block, int initialValue, int address) {
    // TODO: implement writeMfcValueBlock
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
  Future<void> setNtagAuth(String password, String acknowledge) {
    // TODO: implement setNpAuth
    throw UnimplementedError();
  }

  @override
  Future<(int, bool, int)> getNtagAccessConfiguration() {
    // TODO: implement getNtagAccessConfiguration
    throw UnimplementedError();
  }

  @override
  Future<bool> getNtagConfigurationLock() {
    // TODO: implement getNtagConfigurationLock
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
  Future<void> lockNtagConfigurationPermanently() {
    // TODO: implement lockNtagConfiguration
    throw UnimplementedError();
  }

  @override
  Future<void> lockNtagPagePermanently(int page) {
    // TODO: implement lockNtagPagePermanently
    throw UnimplementedError();
  }

  @override
  Future<int> getNtagNfcCounter() {
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
