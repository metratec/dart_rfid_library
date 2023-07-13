import 'dart:async';
import 'dart:typed_data';

import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/utils/heartbeat.dart';

/// Class for uhf reader settings.
/// These settings are set by specific reader implementations.
class UhfReaderSettings {
  /// Minimal output power value.
  int minPower;

  /// Maximal output power value.
  int maxPower;

  /// Minimal Q value.
  static const int minQ = 0;

  /// Maximal Q value.
  static const int maxQ = 15;

  UhfReaderSettings(this.minPower, this.maxPower);
}

/// Region parameter
enum UhfReaderRegion { ETSI, ETSI_HIGH, FCC }

/// Available memory banks on UHF tags
enum UhfMemoryBank {
  pc,
  epc,
  tid,
  usr;

  String get protocolString => switch (this) {
        UhfMemoryBank.pc => "PC",
        UhfMemoryBank.epc => "EPC",
        UhfMemoryBank.tid => "TID",
        UhfMemoryBank.usr => "USR",
      };
}

/// Settings for uhf inventories.
class UhfInvSettings {
  /// Only new tags filter.
  bool ont;

  /// Tag RSSI info.
  bool rssi;

  /// Tag ID info.
  bool tid;

  UhfInvSettings(this.ont, this.rssi, this.tid);

  @override
  String toString() {
    return "ONT=$ont;RSSI=$rssi;TID=$tid";
  }
}

class UhfRwResult {
  /// EPC of the tag read/written
  String epc;

  /// read/write result ok
  bool ok;

  /// Read data. Empty on write.
  Uint8List data;

  UhfRwResult(this.epc, this.ok, this.data);

  @override
  String toString() {
    return "EPC=$epc;OK=$ok,DATA=$data";
  }
}

/// Base class for all uhf readers.
/// Needs to be abstract to have a protocol distinction.
///
/// All functions for uhf readers should be defined
/// at this level as abstract functions.
abstract class UhfReader extends Reader {
  /// heartbeat for aliveness check
  Heartbeat heartbeat = Heartbeat();

  /// Stream for continuous inventory.
  StreamController<List<InventoryResult>> cinvStreamCtrl = StreamController.broadcast();

  /// Settings for the reader.
  final UhfReaderSettings settings;

  UhfReader(super.parser, this.settings);

  // TODO: add all uhf functions here

  /// Set the output power of the reader to [val].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setOutputPower(int val);

  /// Set the starting Q value to [val].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setQStart(int val);

  /// Set the starting Q value to [val] and the range from [min] to [max].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setQ(int val, int min, int max);

  /// Set the inventory output format.
  ///
  /// Output format is specified by [settings].
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setInventorySettings(UhfInvSettings settings);

  /// Retrieve the current inventory format.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<UhfInvSettings> getInventorySettings();

  /// Sets a byte [mask] hex string for Memory bank [memBank] starting at [start].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setByteMask(String memBank, int start, String mask);

  /// Clears set mask.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> clearByteMask();

  /// Perform a single inventory.
  ///
  /// Returns a list if discovered tags.
  /// The output format depends on the settings given to setInventoryFormat()
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<List<UhfTag>> inventory();

  /// Starts a continuous inventory.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> startContinuousInventory();

  /// Stops a running continuous inventory.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> stopContinuousInventory();

  /// Enable heartbeats events of the reader.
  /// The reader will send a heartbeat every x [seconds].
  /// If a heartbeat is received [onHbt] is called.
  /// If no heartbeat is received [onTimeout] will be called.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> startHeartBeat(int seconds, Function onHbt, Function onTimeout);

  /// Stop the heartbeat events.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> stopHeartBeat();

  /// Write [data] to memory [memBank] starting at byte [start].
  /// Optionally an epc [mask] hex string  can be given.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<List<UhfRwResult>> write(String memBank, int start, String data, {String? mask});

  /// Read data of [length] n from memory [memBank] starting at [start].
  /// Optionally an epc [mask] hex string can be given.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<List<UhfRwResult>> read(String memBank, int start, int length, {String? mask});

  /// Get the tag stream for continuous inventories.
  Stream<List<InventoryResult>> getInvStream() {
    return cinvStreamCtrl.stream;
  }
}
