import 'package:dart_rfid_utils/dart_rfid_utils.dart';
import 'package:metratec_device/metratec_device.dart';
import 'package:dart_rfid_library/src/parser/parser.dart';
import 'package:dart_rfid_library/src/parser/parser_at.dart';
import 'package:dart_rfid_library/src/reader_uhf/reader_uhf.dart';

class UhfAsciiReaderSettings extends UhfReaderSettings {
  UhfAsciiReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});
}

class UhfReaderAscii extends UhfReader {
  UhfReaderAscii(CommInterface commInterface, UhfAsciiReaderSettings settings)
      : super(ParserAt(commInterface, "\r"), settings) {
    registerEvent(ParserResponse("HBT", (_) => heartbeat.feed()));
  }

  @override
  Future<void> clearByteMask() {
    // TODO: implement clearByteMask
    throw UnimplementedError();
  }

  @override
  Future<int> getInvAntenna() {
    // TODO: implement getInvAntenna
    throw UnimplementedError();
  }

  @override
  Future<UhfInvSettings> getInventorySettings() {
    // TODO: implement getInventorySettings
    throw UnimplementedError();
  }

  @override
  Future<List<int>> getMuxAntenna() {
    // TODO: implement getMuxAntenna
    throw UnimplementedError();
  }

  @override
  Future<List<int>> getOutputPower() {
    // TODO: implement getOutputPower
    throw UnimplementedError();
  }

  @override
  Future<int> getQ() {
    // TODO: implement getQ
    throw UnimplementedError();
  }

  @override
  Future<UhfReaderRegion> getRegion() {
    // TODO: implement getRegion
    throw UnimplementedError();
  }

  @override
  Future<List<UhfInventoryResult>> inventory() {
    // TODO: implement inventory
    throw UnimplementedError();
  }

  @override
  Future<List<UhfRwResult>> read(String memBank, int start, int length, {String? mask}) {
    // TODO: implement read
    throw UnimplementedError();
  }

  @override
  Future<void> setByteMask(String memBank, int start, String mask) {
    // TODO: implement setByteMask
    throw UnimplementedError();
  }

  @override
  Future<void> setInvAntenna(int val) {
    // TODO: implement setInvAntenna
    throw UnimplementedError();
  }

  @override
  Future<void> setInventorySettings(UhfInvSettings settings) {
    // TODO: implement setInventorySettings
    throw UnimplementedError();
  }

  @override
  Future<void> setMuxAntenna(List<int> val) {
    // TODO: implement setMuxAntenna
    throw UnimplementedError();
  }

  @override
  Future<void> setOutputPower(List<int> val) {
    // TODO: implement setOutputPower
    throw UnimplementedError();
  }

  @override
  Future<void> setQ(int val, int min, int max) {
    // TODO: implement setQ
    throw UnimplementedError();
  }

  @override
  Future<void> setQStart(int val) {
    // TODO: implement setQStart
    throw UnimplementedError();
  }

  @override
  Future<void> setRegion(String region) {
    // TODO: implement setRegion
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
  Future<List<UhfRwResult>> write(String memBank, int start, String data, {String? mask}) {
    // TODO: implement write
    throw UnimplementedError();
  }

  @override
  Future<void> playFeedback(int feedbackId) {
    // TODO: implement playFeedback
    throw UnimplementedError();
  }

  @override
  Future<void> setPassword(String type, String oldPassword, String newPassword, {String? mask}) {
    // TODO: implement setPassword
    throw UnimplementedError();
  }

  @override
  Future<void> killTag(String password, {String? mask}) {
    // TODO: implement killTag
    throw UnimplementedError();
  }

  @override
  Future<void> lockMembank(String memBank, String password, {String? mask}) {
    // TODO: implement lockMembank
    throw UnimplementedError();
  }

  @override
  Future<void> lockMembankPermanently(String memBank, String password, {String? mask}) {
    // TODO: implement lockMembankPermanently
    throw UnimplementedError();
  }

  @override
  Future<void> unlockMembank(String memBank, String password, {String? mask}) {
    // TODO: implement unlockMembank
    throw UnimplementedError();
  }
}
