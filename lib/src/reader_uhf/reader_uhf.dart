import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:reader_library/src/reader.dart';
import 'package:reader_library/src/utils/config_element.dart';
import 'package:reader_library/src/utils/heartbeat.dart';
import 'package:reader_library/src/utils/reader_settings.dart';
import 'package:reader_library/src/utils/uhf_inventory_result.dart';

/// Class for uhf reader settings.
/// These settings are set by specific reader implementations.
class UhfReaderSettings extends ReaderSettings<UhfReader> {
  Iterable<int> possiblePowerValues;
  Iterable<int> possibleQValues;
  Iterable<String> possibleRegionValues;

  /// Maximal output power value.
  int get maxPower => possiblePowerValues.fold(0, max);

  /// Minimal output power value.
  int get minPower => possiblePowerValues.fold(0, min);

  /// The current power value. Should always be set if the reader checks the power value
  int? currentPower;

  /// Maximal Q value.
  int get maxQ => possiblePowerValues.fold(0, max);

  /// Minimal Q value.
  int get minQ => possiblePowerValues.fold(0, min);

  /// The current q value. Should always be set if the reader checks the q value
  int? currentQ;

  /// The current region value. Should always be set if the reader checks the region value
  String? currentRegion;

  /// The current mux antenna value. Should always be set if the reader checks the mux antenna value
  int currentMuxAntenna = 1;

  UhfReaderSettings({
    this.possiblePowerValues = const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    this.possibleQValues = const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
    this.possibleRegionValues = const ["ETSI", "ETSI_HIGH", "FCC"],
  });

  @override
  bool get isUhfDevice => true;

  @override
  List<ConfigElement> getConfigElements(UhfReader reader) {
    return [
      if (possiblePowerValues.length > 1)
        NumConfigElement<int>(
          name: "Power",
          value: currentPower,
          possibleValues: possiblePowerValues,
          setter: reader.setOutputPower,
        ),
      if (possibleQValues.length > 1)
        NumConfigElement<int>(
          name: "Q Value",
          value: currentQ,
          possibleValues: possibleQValues,
          setter: reader.setQStart,
        ),
      if (possibleRegionValues.length > 1)
        StringConfigElement(
          name: "Region",
          value: currentRegion,
          possibleValues: possibleRegionValues,
          setter: reader.setRegion,
        ),
      if (antennaCount > 1)
        NumConfigElement<int>(
          name: "Mux",
          value: currentMuxAntenna,
          possibleValues: Iterable.generate(antennaCount, (i) => i + 1),
          setter: reader.setMuxAntenna,
        ),
    ];
  }
}

/// Region parameter
enum UhfReaderRegion {
  etsi,
  etsiHigh,
  fcc;

  String get protocolString => switch (this) {
        UhfReaderRegion.etsi => "ETSI",
        UhfReaderRegion.etsiHigh => "ETSI_HIGH",
        UhfReaderRegion.fcc => "FCC",
      };
}

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

  @override
  UhfReaderSettings get settings => super.settings as UhfReaderSettings;

  /// !: May throw an [Exception] if value is not an [UhfReaderSettings] object
  @override
  set settings(ReaderSettings value) => super.settings = value as UhfReaderSettings;

  UhfReader(super.parser, super.settings);

  // TODO: add all uhf functions here

  /// Returns the output power of the reader
  ///
  /// The value is also written into [settings]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<int> getOutputPower();

  /// Set the output power of the reader to [val].
  ///
  /// The value is also written into [settings]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setOutputPower(int val);

  /// Set the starting Q value to [val].
  ///
  /// The value is also written into [settings]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setQStart(int val);

  /// Set the starting Q value to [val] and the range from [min] to [max].
  ///
  /// The value is also written into [settings]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setQ(int val, int min, int max);

  /// Returns the current Q value
  ///
  /// The value is also written into [settings]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<int> getQ();

  /// Set the Region value to [val].
  ///
  /// The value is also written into [settings]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setRegion(String region);

  /// Returns the current Region value
  ///
  /// The value is also written into [settings]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<UhfReaderRegion> getRegion();

  /// Returns the current inv antenna value
  ///
  /// The value is also written into [settings]
  ///
  /// Must only be called once. The [invAntenna] field can be used synchronously in most cases
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<int> getInvAntenna();

  /// Set the inv antenna value to [val].
  ///
  /// The value is also written into [settings]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setInvAntenna(int val);

  /// Returns the current mux antenna value
  ///
  /// The value is also written into [settings]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<int> getMuxAntenna();

  /// Set the mux antenna value to [val].
  ///
  /// The value is also written into [settings]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setMuxAntenna(int val);

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

  @override
  Future<List<UhfInventoryResult>> inventory();

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
  /// !: Will throw [ReaderNoTagsException] if tag to write could not be found.
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
  /// !: Will throw [ReaderNoTagsException] if tag to read could not be found.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<List<UhfRwResult>> read(String memBank, int start, int length, {String? mask});

  @override
  Future<void> loadDeviceSettings() async {
    await getOutputPower();
    await getQ();
    await getRegion();
    if (settings.antennaCount > 1) {
      await getInvAntenna();
      await getMuxAntenna();
    }
  }
}
