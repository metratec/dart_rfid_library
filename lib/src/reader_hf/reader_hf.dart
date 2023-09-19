import 'dart:async';
import 'dart:typed_data';

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

  /// Perform a single inventory.
  ///
  /// Returns a list of discovered tags.
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  @override
  Future<List<HfInventoryResult>> inventory();

  /// Authenticate a [block] on a mifare classic tag with [key] of
  /// [keyType].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> mfcAuth(int block, Uint8List key, MfcKeyType keyType);

  /// Read a hex string [data] of a [block] from a tag. Depending on the mode the tag has to be selected
  /// and authenticated.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<String> read(int block);

  /// Select a given [tag].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> selectTag(HfTag tag);

  /// Set the reader [mode].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setMode(String mode);

  /// Set the reader [availableTagTypes]. and returns them
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<Iterable<String>> detectTagTypes();

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

  /// Write a hex string [data] to a tag at [block]. Depending on the mode the tag has to be selected
  /// and authenticated.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> write(int block, String data);

  @override
  Future<void> loadDeviceSettings() async {
    await detectTagTypes();
  }
}

enum HfReaderMode {
  iso14a,
  iso15,
  auto;

  String get protocolString => switch (this) {
        HfReaderMode.iso14a => "ISO14A",
        HfReaderMode.iso15 => "ISO15",
        HfReaderMode.auto => "AUTO",
      };
}

class HfReaderSettings extends ReaderSettings<HfReader> {
  @override
  bool get isHfDevice => true;

  String? mode;

  Set<String> availableTagTypes = {};

  @override
  List<ConfigElement> getConfigElements(HfReader reader) {
    return [
      StringConfigElement(
        name: "Mode",
        value: mode,
        possibleValues: (config) => ["Auto", "ISO15", "ISO14A"],
        isEnabled: (config) => true,
        setter: reader.setMode,
      )
    ];
  }

  @override
  bool get isActive => super.isActive && mode != null;
}

enum MfcKeyType { A, B }
