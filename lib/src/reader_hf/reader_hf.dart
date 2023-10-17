import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dart_rfid_utils/dart_rfid_utils.dart';
import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/utils/heartbeat.dart';

/// Base class for all hf readers.
/// Needs to be abstract to have a protocol distinction.
///
/// All functions for hf readers should be defined
/// at this level as abstract functions.
abstract class HfReader extends Reader {
  /// heartbeat for aliveness check
  Heartbeat heartbeat = Heartbeat();

  HfReader(super.parser, super.settings);

  @override
  HfReaderSettings get settings => super.settings as HfReaderSettings;

  /// !: May throw an [Exception] if value is not an [HfReaderSettings] object
  @override
  set settings(ReaderSettings value) => super.settings = value as HfReaderSettings;

  // TODO: add all hf functions here

  // region Device Settings
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
  // endregion Device Settings

  // region RFID Settings
  /// Set the reader [mode].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setMode(String mode);

  /// Get the reader [mode].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<String?> getMode();
  // endregion RFID Settings

  // region Tag Operations
  /// Perform a single inventory.
  ///
  /// Returns a list of discovered tags.
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  @override
  Future<List<HfInventoryResult>> inventory();

  /// Select a given [tag].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> selectTag(HfTag tag);

  /// Read a hex string [data] of a [block] from a tag. Depending on the mode the tag has to be selected
  /// and authenticated.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<String> read(int block);

  /// Write a hex string [data] to a tag at [block]. Depending on the mode the tag has to be selected
  /// and authenticated.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> write(int block, String data);

  /// Set the reader [availableTagTypes]. and returns them
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<Map<String, TagType>> detectTagTypes();
  // endregion Tag Operations

  // region ISO15693 Commands
  /// Set the reader [afi] value.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setAfi(int afi);

  /// Get the reader [afi] value.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<int?> getAfi();

  /// Write the tag [afi] value.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> writeAfi(int afi, bool optionsFlag);

  /// Lock the tag [afi] value.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> lockAfi(bool optionsFlag);

  /// Write the tag [dsfid] value.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> writeDsfid(int dsfid, bool optionsFlag);

  /// Lock the tag [afi] value.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> lockDsfid(bool optionsFlag);
  // endregion ISO15693 Commands

  // region ISO14A Commands
  // region Mifare Classic Commands
  /// Authenticate a [block] on a mifare classic tag with [key] of
  /// [keyType].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> mfcAuth(int block, Uint8List key, MfcKeyType keyType);
  // endregion Mifare Classic Commands

  // region NTAG / Mifare Ultralight Commands
  // endregion NTAG / Mifare Ultralight Commands
  // endregion ISO14A Commands

  // region Feedback
  Future<void> playFeedback(int feedbackId);
  // endregion Feedback

  @override
  Future<void> loadDeviceSettings() async {
    await detectTagTypes();
  }
}

enum HfReaderMode {
  auto,
  iso15,
  iso14a;

  String get protocolString => switch (this) {
        HfReaderMode.auto => "AUTO",
        HfReaderMode.iso15 => "ISO15",
        HfReaderMode.iso14a => "ISO14A",
      };
}

class HfReaderSettings extends ReaderSettings<HfReader> {
  @override
  bool get isHfDevice => true;

  String? mode;

  int? afi;

  Map<String, TagType> availableTagTypes = {};

  @override
  List<ConfigElement> getConfigElements(HfReader reader) {
    return [
      StringConfigElement(
        name: "Mode",
        value: mode,
        possibleValues: (config) => HfReaderMode.values.map((e) => e.protocolString),
        isEnabled: (config) => true,
        setter: reader.setMode,
      ),
      NumConfigElement<int>(
        name: "AFI",
        value: afi,
        possibleValues: (config) => Iterable.generate(129),
        isEnabled: (config) {
          final modeValue = config.firstWhereOrNull((e) => e.name == "Mode")?.value as String?;
          return modeValue == HfReaderMode.iso15.protocolString;
        },
        setter: reader.setAfi,
      ),
    ];
  }

  @override
  bool get isActive => super.isActive && mode != null;
}

enum MfcKeyType { A, B }
