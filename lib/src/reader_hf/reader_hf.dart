import 'dart:async';

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

  /// Set the reader [radio interface]. Only available if [mode] is [HfReaderMode.iso15]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setRadioInterface(int modulation, String subcarrier);

  /// Get the reader [radio interface]. Only available if [mode] is [HfReaderMode.iso15]
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<(int?, String?)> getRadioInterface();
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

  /// Deselect the currently selected tag.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> deselectTag();

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
  Future<void> authMfc(int block, String key, MfcKeyType keyType);

  /// Used to authenticate with a stored key at [index] in the keystore.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> authMfcStoredKey(int block, int index);

  /// Used to store a key in the internal key store of the DeskID NFC.
  ///
  /// - [index] must be in range from 0 to 16.
  /// - [key] must be exactly 6 bytes long-
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setMfcInternalKey(int index, String key, MfcKeyType keyType);

  /// Used to get the access bits for a Mifare Classic block.
  /// Returns the access bits for the corresponding block.
  /// Please refer to the Mifare Classic documentation for the meaning of the access bits.
  /// Note that the access conditions differ for data blocks and the sector trailer.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<(bool, bool, bool)> getMfcAccessBits(int block);

  /// Used to set the keys and access bits for a Mifare Classic Block.
  /// Note that in Mifare Classic Blocks are grouped in sectors of 4 blocks.
  /// The keys are set for the whole sector, not for a single block in the sector.
  /// The access bits however are set block-wise.
  /// Make sure you are using the same keys if you set the access bits for different blocks in the same sector.
  /// The parameters of this command are block number, key1, key2 and access bits.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setMfcKeysAndAccessBits(int block, String key1, String key2, (bool, bool, bool) accessBits);

  /// Used to set the keys for a Mifare Classic block.
  /// Note that in Mifare Classic Blocks are grouped in sectors of 4 blocks.
  /// The keys are set for the whole sector, not for a single block in the sector.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> setMfcKeys(int block, String key1, String key2);

  /// Used to create a Mifare Classic Value block.
  ///
  /// [initialValue] is a signed 32 bit integer.
  /// The address byte stores the address of a block used for backup.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> writeMfcValueBlock(int block, int initialValue, int address);

  /// Used to read the value of a Mifare Classic value block.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<(int, int)> readMfcBlockValue(int block);

  /// Used to increment the value of a Mifare Classic block.
  /// Note that this operation only will have an effect after [transferMfcBlockValue] is executed.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> incrementMfcBlockValue(int block, int incrementValue);

  /// Used to decrement the value of a Mifare Classic block.
  /// Note that this operation only will have an effect after [transferMfcBlockValue] is executed.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> decrementMfcBlockValue(int block, int decrementValue);

  /// Used to restore the value of a Mifare Classic block.
  /// Note that this operation only will have an effect after [transferMfcBlockValue] is executed.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> restoreMfcBlockValue(int block);

  /// Used to write pending transactions to a block.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> transferMfcBlockValue(int block);
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

  /// Used to get the lock state the NTAG configurations.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<bool> getNtagConfigurationLock();

  /// Used to permanently lock the NTAG configuration.
  /// Note that the changes are only activated after a power cycle of the tag.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: This lock is irreversible.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> lockNtagConfigurationPermanently();

  /// Used to read the NFC counter of an NTAG.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: If password protection is enabled (see [getNtagAccessConfiguration]) for the counter [authNtag]
  /// must be called before calling this.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<int> getNtagNfcCounter();

  /// Used to lock a NTAG page. Page 3 to 15 can be locked individually.
  /// All other pages are then grouped and can only be locked as groups.
  /// The group size depends on the NTAG type. Refer to the NTAG datasheet for details.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: This lock is irreversible.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> lockNtagPagePermanently(int page);

  /// Used to set the block-lock bits. The block-lock bits are used to lock the lock bits.
  /// Refer to the NTAG datasheet for details.
  ///
  /// !: You must use [selectTag] before calling
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
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

  int? criModulation;
  String? criSubcarrier;

  Map<String, TagType> availableTagTypes = {};

  @override
  List<ConfigElement> getConfigElements(HfReader reader) {
    final isIso15Mode = mode == HfReaderMode.iso15.protocolString;
    if (!isIso15Mode) {
      return [];
    }

    return [
      NumConfigElement<int>(
        name: "AFI",
        value: afi,
        possibleValues: (config) => Iterable.generate(129),
        isEnabled: (config) => true,
        setter: reader.setAfi,
      ),
      ConfigElementGroup(
        name: "CRI",
        setter: (val) async {
          final int modulation = val.firstWhereOrNull((e) => e.name == "Radio interface modulation")?.value ?? 100;
          final String subcarrier =
              val.firstWhereOrNull((e) => e.name == "Radio interface subcarrier")?.value ?? "SINGLE";

          await reader.setRadioInterface(modulation, subcarrier);
        },
        isEnabled: (config) => true,
        value: [
          NumConfigElement<int>(
            name: "Radio interface modulation",
            value: criModulation,
            possibleValues: (config) => [10, 100],
            isEnum: true,
            setter: (val) async {},
            isEnabled: (config) => true,
          ),
          StringConfigElement(
            name: "Radio interface subcarrier",
            value: criSubcarrier,
            possibleValues: (configs) => ["SINGLE", "DOUBLE"],
            setter: (val) async {},
            isEnabled: (config) => true,
          ),
        ],
      )
    ];
  }

  @override
  bool get isActive => super.isActive && mode != null;
}
