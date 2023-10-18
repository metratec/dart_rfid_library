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
  /// Used to authenticate with an NTAG after the authentication password protected pages can be accessed.
  /// [password] must be an exactly 4 bytes long hex string.
  /// Will return the configured password acknowledge. See [setNtagAuth]
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<String> authNtag(String password);

  /// Used to set the password and the password acknowledge for NTAG.
  /// [password] must be an exactly 4 bytes long hex string.
  /// [acknowledge] must be an exactly 2 bytes long hex string.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setNtagAuth(String password, String acknowledge);

  /// Used to get the NTAG access configuration.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<(int, bool, int)> getNtagAccessConfiguration();

  /// Used to set the NTAG access configuration.
  /// Note that the changes are only activated after a power cycle of the tag.
  ///
  /// If [readProtection] is true both read and write are password protected.
  /// Otherwise only write is password protected
  ///
  /// [auth] must be an integer between 4 and 255 (including)
  /// [authLimit] must be an integer between 0 and 7 (including)
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setNtagAccessConfiguration(int auth, bool readProtection, int authLimit);

  /// Used to get the NTAG mirror configuration.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<(NtagMirrorMode, int, int)> getNtagMirrorConfiguration();

  /// Used to set the NTAG mirror configuration.
  /// Note that the changes are only activated after a power cycle of the tag.
  ///
  /// [page] must be an integer between 4 and (Last Page - 3)
  /// [byte] must be an integer between 0 and 3 (including)
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setNtagMirrorConfiguration(NtagMirrorMode mode, int page, int byte);

  /// Used to get the NTAG counter configuration.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<(bool, bool)> getNtagCounterConfiguration();

  /// Used to get or set the NTAG counter configuration.
  /// Note that the changes are only activated after a power cycle of the tag.
  ///
  /// [enableNfcCounter] Set to true to enable the NFC counter.
  /// [enabledPasswordProtection] Set to 1 to enable password protection for the NFC counter.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setNtagCounterConfiguration(bool enableNfcCounter, bool enablePasswordProtection);

  /// Used to get the NTAG modulation configuration.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<bool> getNtagModulationConfiguration();

  /// Used to set the NTAG modulation configuration.
  /// The parameter is boolean. If set to 1 strong modulation is enabled, otherwise it is disabled.
  /// Note that the changes are only activated after a power cycle of the tag.
  ///
  /// [enableModulation] Set to true to enable strong modulation.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setNtagModulationConfiguration(bool enableModulation);

  /// Used to permanently lock the NTAG configuration.
  /// Note that the changes are only activated after a power cycle of the tag.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: This lock is irreversible.
  Future<void> lockNtagConfigurationPermanently();

  /// Used to read the NFC counter of an NTAG.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: If password protection is enabled (see [getNtagAccessConfiguration]) for the counter [authNtag]
  /// must be called before calling this.
  Future<int> getNtagNfcCounter();

  /// Used to lock a NTAG page. Page 3 to 15 can be locked individually.
  /// All other pages are then grouped and can only be locked as groups.
  /// The group size depends on the NTAG type. Refer to the NTAG datasheet for details.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: This lock is irreversible.
  Future<void> lockNtagPagePermanently(int page);

  /// Used to set the block-lock bits. The block-lock bits are used to lock the lock bits.
  /// Refer to the NTAG datasheet for details.
  ///
  /// !: You must use [selectTag] before calling
  Future<void> setNtagBlockLock(int page);
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
