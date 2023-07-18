import 'dart:async';
import 'dart:typed_data';

import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/utils/heartbeat.dart';
import 'package:reader_library/src/utils/reader_settings.dart';

class HfReaderSettings extends ReaderSettings {
  @override
  List<ConfigElement> getConfigElements() {
    return [
      StringConfigElement(
        name: "Tag Type",
        value: null,
        possibleValues: ["Auto", "ISO15693", "Mifare", "NTAG"],
      ),
    ];
  }
}

enum HfReaderMode { iso14a, iso15, auto }

enum MfcKeyType { A, B }

/// Base class for all hf readers.
/// Needs to be abstract to have a protocol distinction.
///
/// All functions for hf readers should be defined
/// at this level as abstract functions.
abstract class HfReader extends Reader {
  /// heartbeat for aliveness check
  Heartbeat heartbeat = Heartbeat();

  /// Stream for continuous inventory.
  StreamController<List<HfInventoryResult>> cinvStreamCtrl = StreamController.broadcast();

  HfReader(super.parser, super.settings);

  @override
  HfReaderSettings get settings => super.settings as HfReaderSettings;

  /// !: May throw an [Exception] if value is not an [HfReaderSettings] object
  @override
  set settings(ReaderSettings value) => super.settings = value as HfReaderSettings;

  // TODO: add all hf functions here

  /// Set the reader [mode].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setMode(HfReaderMode mode);

  /// Perform a single inventory.
  ///
  /// Returns a list of discovered tags.
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<List<HfInventoryResult>> inventory();

  /// Select a given [tag].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> selectTag(HfTag tag);

  /// Authenticate a [block] on a mifare classic tag with [key] of
  /// [keyType].
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> mfcAuth(int block, Uint8List key, MfcKeyType keyType);

  /// Write [data] to a tag at [block]. Depending on the mode the tag has to be selected
  /// and authenticated.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> write(Uint8List data, int block);

  /// Read [data] of a [block] from a tag. Depending on the mode the tag has to be selected
  /// and authenticated.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<Uint8List> read(int block);

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

  /// Starts a continuous inventory.
  ///
  /// Results can be obtained by subscribing to getInvStream().
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> startContinuousInventory();

  /// Stops a running continuous inventory.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> stopContinuousInventory();

  /// Get the tag stream for continuous inventories.
  Stream<List<HfInventoryResult>> getInvStream() {
    return cinvStreamCtrl.stream;
  }
}
