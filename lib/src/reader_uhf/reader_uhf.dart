import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dart_rfid_utils/dart_rfid_utils.dart';
import 'package:reader_library/src/reader.dart';
import 'package:reader_library/src/utils/extensions.dart';
import 'package:reader_library/src/utils/heartbeat.dart';
import 'package:reader_library/src/utils/reader_settings.dart';

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
  List<int>? currentPower;

  /// Maximal Q value.
  int? currentMaxQ;

  /// Minimal Q value.
  int? currentMinQ;

  /// The current q value. Should always be set if the reader checks the q value
  int? currentQ;

  /// The current region value. Should always be set if the reader checks the region value
  String? currentRegion;

  /// The current mux antenna value. Should always be set if the reader checks the mux antenna value
  List<int> currentMuxAntenna = [1];

  UhfReaderSettings({
    this.possiblePowerValues = const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
    this.possibleQValues = const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15],
    this.possibleRegionValues = const ["ETSI", "FCC"],
  });

  @override
  bool get isUhfDevice => true;

  @override
  bool get isActive =>
      currentRegion != null && currentPower != null && currentQ != null && currentMaxQ != null && currentMinQ != null;

  @override
  List<ConfigElement> getConfigElements(UhfReader reader) {
    return [
      if (possiblePowerValues.length > 1)
        ConfigElementGroup(
          name: "Power Values",
          setter: (val) async {
            final powerValues = val.map((e) => e.value).whereType<int>().toList();
            await reader.setOutputPower(powerValues);
          },
          category: "Inventory Options",
          isEnabled: (configs) => true,
          addDivider: true,
          value: [
            for (var (index, powerVal) in (currentPower ?? []).indexed)
              NumConfigElement<int>(
                name: (currentPower?.length ?? 0) > 1 ? "Power Ant ${index + 1}" : "Power",
                category: "Inventory Options",
                value: powerVal,
                possibleValues: (configs) => possiblePowerValues,
                isEnabled: (configs) => true,
                setter: (val) async {},
              ),
          ],
        ),
      if (possibleRegionValues.length > 1)
        StringConfigElement(
          name: "Region",
          category: "Inventory Options",
          value: currentRegion,
          possibleValues: (configs) => possibleRegionValues,
          isEnabled: (configs) => true,
          setter: reader.setRegion,
        ),
      if (possibleQValues.length > 1)
        ConfigElementGroup(
          name: "Q Value",
          category: "Inventory Options",
          addDivider: true,
          setter: (val) async {
            final int qStartVal = val.firstWhereOrNull((e) => e.name == "Q Start")?.value ?? 5;
            final int qMinVal = val.firstWhereOrNull((e) => e.name == "Q Min")?.value ?? possibleQValues.first;
            final int qMaxVal = val.firstWhereOrNull((e) => e.name == "Q Max")?.value ?? possibleQValues.last;

            await reader.setQ(qStartVal, qMinVal, qMaxVal);
          },
          isEnabled: (configs) => true,
          value: [
            NumConfigElement<int>(
              name: "Q Start",
              category: "Inventory Options",
              value: currentQ,
              possibleValues: (configs) => possibleQValues,
              isEnabled: (configs) => true,
              setter: (val) async {},
            ),
            NumConfigElement<int>(
              name: "Q Min",
              category: "Inventory Options",
              value: currentMinQ,
              possibleValues: (configs) => possibleQValues,
              isEnabled: (configs) => true,
              setter: (val) async {},
            ),
            NumConfigElement<int>(
              name: "Q Max",
              category: "Inventory Options",
              value: currentMaxQ,
              possibleValues: (configs) => possibleQValues,
              isEnabled: (configs) => true,
              setter: (val) async {},
            ),
          ],
        ),
      if (antennaCount > 1)
        ListConfigElement<int>(
          name: "Mux Sequence",
          category: "Antenna/Mux",
          value: currentMuxAntenna,
          possibleValues: (config) => Iterable.generate(antennaCount, (i) => i + 1),
          isEnabled: (configs) => true,
          stringToElementConverter: int.parse,
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

  bool fastStart;

  UhfInvSettings(this.ont, this.rssi, this.tid, this.fastStart);

  String toProtocolString({bool supportsFastStart = true}) => [
        ont,
        rssi,
        tid,
        if (supportsFastStart) fastStart,
      ].map((e) => e.toProtocolString()).join(",");

  @override
  String toString() {
    return "ONT=$ont;RSSI=$rssi;TID=$tid;FS=$fastStart";
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
  Future<List<int>> getOutputPower();

  /// Set the output power of the reader to [val].
  ///
  /// The value is also written into [settings]
  ///
  /// If val only contains one value, the value is applied to all outputs.
  /// Otherwise the length of val must be the [antennaCount]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setOutputPower(List<int> val);

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
  Future<List<int>> getMuxAntenna();

  /// Set the mux antenna value to [val].
  ///
  /// The value is also written into [settings]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setMuxAntenna(List<int> val);

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

  Future<void> setPassword(String type, String oldPassword, String newPassword, {String? mask});

  Future<void> playFeedback(int feedbackId);

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
