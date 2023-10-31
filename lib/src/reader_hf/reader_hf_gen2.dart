import 'dart:async';
import 'dart:developer';

import 'package:collection/collection.dart';
import 'package:dart_rfid_utils/dart_rfid_utils.dart';
import 'package:metratec_device/metratec_device.dart';
import 'package:reader_library/src/parser/parser.dart';
import 'package:reader_library/src/parser/parser_at.dart';
import 'package:reader_library/src/reader_exception.dart';
import 'package:reader_library/src/reader_hf/reader_hf.dart';
import 'package:reader_library/src/utils/extensions.dart';

class HfGen2ReaderSettings extends HfReaderSettings {
  @override
  bool get isHfGen2Device => true;
}

class HfReaderGen2 extends HfReader {
  final List<HfTag> _inventory = [];

  HfReaderGen2(CommInterface commInterface, HfGen2ReaderSettings settings)
      : super(ParserAt(commInterface, "\r"), settings) {
    registerEvent(ParserResponse("+CINV", _handleCinvUrc));
    registerEvent(ParserResponse("+HBT", _handleHbtUrc));
  }

  void _handleCinvUrc(String line) async {
    if (line.contains("ROUND FINISHED")) {
      List<HfInventoryResult> inv = [];
      inv.addAll(_inventory.map((e) => HfInventoryResult(tag: e, timestamp: DateTime.now())));
      cinvStreamCtrl.add(inv);
      _inventory.clear();
      return;
    } else if (line.contains("<")) {
      return;
    }

    final uid = line.split(': ').last;
    final tagType = settings.availableTagTypes[uid] ?? TagType.unknown;
    _inventory.add(HfTag(uid, tagType));
  }

  void _handleHbtUrc(String line) {
    heartbeat.feed();
  }

  void _handleExitCode(CmdExitCode code, String error, {ReaderException? exception}) {
    if (exception != null) {
      throw exception;
    } else if (code == CmdExitCode.timeout) {
      throw ReaderTimeoutException("Command timed out!");
    } else if (code != CmdExitCode.ok) {
      throw ReaderException("Command failed with: $error");
    }
  }

  // region Device Settings
  @override
  Future<void> startHeartBeat(int seconds, Function onHbt, Function onTimeout) async {
    heartbeat.stop();

    try {
      CmdExitCode exitCode = await sendCommand("AT+HBT=$seconds", 1000, []);
      _handleExitCode(exitCode, "");

      heartbeat.start(seconds * 1000 + 2000, onHbt, onTimeout);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> stopHeartBeat() async {
    heartbeat.stop();
    try {
      CmdExitCode exitCode = await sendCommand("AT+HBT=0", 1000, []);
      _handleExitCode(exitCode, "");
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }
  // endregion Device Settings

  // region RFID Settings
  @override
  Future<void> setMode(String mode) async {
    if (HfReaderMode.values.none((e) => e.protocolString == mode)) {
      throw ReaderException("Unsupported mode: $mode");
    }

    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+MOD=${mode.toUpperCase()}", 1000, [
        ParserResponse("+MOD", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    settings.mode = mode;
  }

  @override
  Future<String?> getMode() async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+MOD?", 1000, [
        ParserResponse("+MOD", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          settings.mode = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    if (settings.mode == HfReaderMode.iso15.protocolString) {
      try {
        await getAfi();
      } catch (ex, stack) {
        // Could not read AFI but we want to return the mode nevertheless
        log("Failed to get afi", error: ex, stackTrace: stack);
        // We set afi to 0 as default value so its not null
        settings.afi = 0;
      }

      try {
        await getRadioInterface();
      } catch (ex, stack) {
        log("Failed to get radio interface", error: ex, stackTrace: stack);
        settings.criModulation = 100;
        settings.criSubcarrier = "SINGLE";
      }
    } else {
      // We set afi to 0 as default value so its not null
      settings.afi = 0;
      settings.criModulation = 100;
      settings.criSubcarrier = "SINGLE";
    }

    return settings.mode;
  }

  @override
  Future<(int?, String?)> getRadioInterface() async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+CRI?", 1000, [
        ParserResponse("+CRI", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          final split = line.split(",");
          if (split.length != 2) {
            error = line;
            return;
          }

          settings.criSubcarrier = split[0];
          settings.criModulation = int.tryParse(split[1]);
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (e) {
      throw ReaderException(e.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }

    return (settings.criModulation, settings.criSubcarrier);
  }

  @override
  Future<void> setRadioInterface(int modulation, String subcarrier) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+CRI=${subcarrier.toUpperCase()},$modulation", 1000, [
        ParserResponse("+CRI", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (e) {
      throw ReaderException(e.toString());
    }

    settings.criSubcarrier = subcarrier;
    settings.criModulation = modulation;
  }
  // endregion RFID Settings

  // region Tag Operations
  @override
  Future<List<HfInventoryResult>> inventory() async {
    List<HfInventoryResult> inv = [];
    String error = "";

    try {
      final availableTagTypes = await detectTagTypes();

      CmdExitCode exitCode = await sendCommand("AT+INV", 2000, [
        ParserResponse("+INV", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          inv.add(HfInventoryResult(
            tag: HfTag(
              line,
              availableTagTypes[line] ?? TagType.unknown,
            ),
            timestamp: DateTime.now(),
          ));
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    return inv;
  }

  @override
  Future<void> startContinuousInventory() async {
    try {
      CmdExitCode exitCode = await sendCommand("AT+CINV", 1000, []);
      _handleExitCode(exitCode, "");
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> stopContinuousInventory() async {
    try {
      CmdExitCode exitCode = await sendCommand("AT+BINV", 3000, []);
      _handleExitCode(exitCode, "");
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> selectTag(HfTag tag) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+SEL=${tag.uid}", 1000, [
        ParserResponse("+SEL", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> deselectTag() async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+DEL", 1000, [
        ParserResponse("+DEL", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<String> read(int block) async {
    final RegExp illegalBlockPattern = RegExp(r"<Illegal block for (.*): (\d*) \[(\d*)-(\d*)\]>");
    String data = "";
    String error = "";
    ReaderException? exception;

    try {
      CmdExitCode exitCode = await sendCommand("AT+READ=$block", 2000, [
        ParserResponse("+READ", (line) {
          final illegalBlockMatch = illegalBlockPattern.firstMatch(line);
          if (illegalBlockMatch != null) {
            final minValue = int.tryParse(illegalBlockMatch[3] ?? '');
            final maxValue = int.tryParse(illegalBlockMatch[4] ?? '');
            exception = ReaderRangeException(line, inner: RangeError.range(block, minValue, maxValue));
          }

          if (line.contains("<")) {
            error = line;
            return;
          }

          data = line;
        })
      ]);
      _handleExitCode(exitCode, error, exception: exception);
    } on ReaderException {
      rethrow;
    } catch (e) {
      throw ReaderException(e.toString());
    }

    return data;
  }

  @override
  Future<void> write(int block, String data) async {
    if (!hexRegEx.hasMatch(data)) {
      throw ReaderException("Unsupported data! Must be a hex string");
    }

    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+WRT=$block,$data", 2000, [
        ParserResponse("+WRT", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<Map<String, TagType>> detectTagTypes() async {
    String error = "";
    final availableTagTypes = <String, TagType>{};

    try {
      CmdExitCode exitCode = await sendCommand("AT+DTT", 1000, [
        ParserResponse("+DTT", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          final split = line.split(",");
          if (split.length < 2) {
            error = line;
            return;
          }
          final tagUid = split[0];
          final tagTypeString = split[1];
          final tagType = TagType.fromProtocolString(tagTypeString);

          if (tagType == TagType.unknown) {
            readerLogger.w("Could not detect tag type of tag $tagUid: $tagTypeString");
          }

          availableTagTypes[tagUid] = tagType;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    settings.availableTagTypes = availableTagTypes;
    return settings.availableTagTypes;
  }
  // endregion Tag Operations

  // region ISO15693 Commands
  @override
  Future<void> setAfi(int afi) async {
    if (afi < 0 || afi > 255) {
      throw ReaderException("Unsupported afi value: $afi");
    }

    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand(
        "AT+AFI=${afi.toRadixString(16).padLeft(2, "0")}",
        1000,
        [
          ParserResponse("+AFI", (line) {
            error = line;
          })
        ],
      );
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    settings.afi = afi;
  }

  @override
  Future<int?> getAfi() async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+AFI?", 1000, [
        ParserResponse("+AFI", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          settings.afi = int.tryParse(line);
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    return settings.afi;
  }

  @override
  Future<void> writeAfi(int afi, bool optionsFlag) async {
    if (afi < 0 || afi > 255) {
      throw ReaderException("Unsupported afi value: $afi");
    }

    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand(
        "AT+WAFI=${afi.toRadixString(16).padLeft(2, "0")},${optionsFlag.toProtocolString()}",
        1000,
        [
          ParserResponse("+WAFI", (line) {
            error = line;
          })
        ],
      );
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> lockAfi(bool optionsFlag) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+LAFI=${optionsFlag.toProtocolString()}", 1000, [
        ParserResponse("+LAFI", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> writeDsfid(int dsfid, bool optionsFlag) async {
    if (dsfid < 0 || dsfid > 255) {
      throw ReaderException("Unsupported DSFID value: $dsfid");
    }

    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand(
        "AT+WDSFID=${dsfid.toRadixString(16).padLeft(2, "0")},${optionsFlag.toProtocolString()}",
        1000,
        [
          ParserResponse("+WDSFID", (line) {
            error = line;
          })
        ],
      );
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> lockDsfid(bool optionsFlag) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+LDSFID=${optionsFlag.toProtocolString()}", 1000, [
        ParserResponse("+LDSFID", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }
  // endregion ISO15693 Commands

  // region ISO14A Commands
  // region Mifare Classic Commands
  @override
  Future<void> authMfc(int block, String key, MfcKeyType keyType) async {
    if (key.length != 12) {
      throw ReaderException("Wrong key size for MFC");
    }

    String typeString = keyType.toString().split('.').last;
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+AUT=$block,$key,$typeString", 1000, [
        ParserResponse("+AUT", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> authMfcStoredKey(int block, int index) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+AUTN=$block,$index", 1000, [
        ParserResponse("+AUTN", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> decrementMfcBlockValue(int block, int decrementValue) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+DVL=$block,$decrementValue", 1000, [
        ParserResponse("+DVL", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<(bool, bool, bool)> getMfcAccessBits(int block) async {
    String error = "";
    (bool, bool, bool)? accessBits;

    try {
      CmdExitCode exitCode = await sendCommand("AT+GAB=$block", 1000, [
        ParserResponse("+GAB", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          if (line.length != 3) {
            error = line;
            return;
          }

          accessBits = (line[0] == '1', line[1] == '1', line[2] == '1');
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }

    return accessBits!;
  }

  @override
  Future<void> incrementMfcBlockValue(int block, int incrementValue) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+IVL=$block,$incrementValue", 1000, [
        ParserResponse("+IVL", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<(int, int)> readMfcBlockValue(int block) async {
    String error = "";
    (int, int)? blockValue;

    try {
      CmdExitCode exitCode = await sendCommand("AT+RVL=$block", 1000, [
        ParserResponse("+RVL", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          final split = line.split(',');
          if (split.length != 2) {
            error = line;
            return;
          }

          blockValue = (int.parse(split.first), int.parse(split.last));
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }

    return blockValue!;
  }

  @override
  Future<void> restoreMfcBlockValue(int block) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+RSVL=$block", 1000, [
        ParserResponse("+RSVL", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setMfcInternalKey(int index, String key, MfcKeyType keyType) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+SIK=$index,$key,${keyType.name}", 1000, [
        ParserResponse("+SIK", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setMfcKeys(int block, String key1, String key2) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+SKO=$block,$key1,$key2", 1000, [
        ParserResponse("+SKO", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setMfcKeysAndAccessBits(int block, String key1, String key2, (bool, bool, bool) accessBits) async {
    String error = "";

    try {
      final accessBitString =
          accessBits.$1.toProtocolString() + accessBits.$2.toProtocolString() + accessBits.$3.toProtocolString();
      CmdExitCode exitCode = await sendCommand("AT+SKO=$block,$key1,$key2,$accessBitString", 1000, [
        ParserResponse("+SKO", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> transferMfcBlockValue(int block) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+TXF=$block", 1000, [
        ParserResponse("+TXF", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> writeMfcValueBlock(int block, int initialValue, int address) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+WVL=$block,$initialValue,$address", 1000, [
        ParserResponse("+WVL", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }
  // endregion Mifare Classic Commands

  // region NTAG / Mifare Ultralight Commands
  @override
  Future<String> authNtag(String password) async {
    String error = "";
    String ack = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+NPAUTH=$password", 1000, [
        ParserResponse("+NPAUTH", (line) {
          if (line.contains("<") || line.length != 4) {
            error = line;
            return;
          }

          ack = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }

    return ack;
  }

  @override
  Future<(int, bool, int)> getNtagAccessConfiguration() async {
    String error = "";
    (int, bool, int)? accessConfig;

    try {
      CmdExitCode exitCode = await sendCommand("AT+NACFG?", 1000, [
        ParserResponse("+NACFG", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          final split = line.split(",");
          if (split.length != 3) {
            error = line;
            return;
          }

          accessConfig = (int.parse(split.first), split[1] == "1", int.parse(split.last));
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }

    return accessConfig!;
  }

  @override
  Future<bool> getNtagConfigurationLock() async {
    String error = "";
    bool isLocked = false;

    try {
      CmdExitCode exitCode = await sendCommand("AT+NCLK?", 1000, [
        ParserResponse("+NCLK", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          isLocked = int.parse(line) == 1;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }

    return isLocked;
  }

  @override
  Future<(bool, bool)> getNtagCounterConfiguration() async {
    String error = "";
    (bool, bool)? counterConfig;

    try {
      CmdExitCode exitCode = await sendCommand("AT+NCCFG?", 1000, [
        ParserResponse("+NCCFG", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          final split = line.split(",");
          if (split.length != 2) {
            error = line;
            return;
          }

          counterConfig = (split[0] == "1", split[1] == "1");
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }

    return counterConfig!;
  }

  @override
  Future<(NtagMirrorMode, int, int)> getNtagMirrorConfiguration() async {
    String error = "";
    (NtagMirrorMode, int, int)? mirrorConfig;

    try {
      CmdExitCode exitCode = await sendCommand("AT+NMCFG?", 1000, [
        ParserResponse("+NMCFG", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          final split = line.split(",");
          if (split.length != 3) {
            error = line;
            return;
          }

          mirrorConfig = (NtagMirrorMode.fromProtocolString(split[0]), int.parse(split[1]), int.parse(split[2]));
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }

    return mirrorConfig!;
  }

  @override
  Future<bool> getNtagModulationConfiguration() async {
    String error = "";
    bool modulationConfig = false;

    try {
      CmdExitCode exitCode = await sendCommand("AT+NDCFG?", 1000, [
        ParserResponse("+NDCFG", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          modulationConfig = line == "1";
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }

    return modulationConfig;
  }

  @override
  Future<int> getNtagNfcCounter() async {
    String error = "";
    int? nfcCounter;

    try {
      CmdExitCode exitCode = await sendCommand("AT+NCNT", 1000, [
        ParserResponse("+NCNT", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          nfcCounter = int.parse(line);
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }

    return nfcCounter!;
  }

  @override
  Future<void> lockNtagConfigurationPermanently() async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+NCLK", 1000, [
        ParserResponse("+NCLK", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> lockNtagPagePermanently(int page) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+NLK=$page", 1000, [
        ParserResponse("+NLK", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setNtagAccessConfiguration(int auth, bool readProtection, int authLimit) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+NACFG=$auth,${readProtection.toProtocolString()},$authLimit", 1000, [
        ParserResponse("+NACFG", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setNtagAuth(String password, String acknowledge) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+NPWD=$password,$acknowledge", 1000, [
        ParserResponse("+NPWD", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setNtagBlockLock(int page) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+NBLK=$page", 1000, [
        ParserResponse("+NBLK", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setNtagCounterConfiguration(bool enableNfcCounter, bool enablePasswordProtection) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand(
        "AT+NCCFG=${enableNfcCounter.toProtocolString()},${enablePasswordProtection.toProtocolString()}",
        1000,
        [
          ParserResponse("+NCCFG", (line) {
            error = line;
          })
        ],
      );
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setNtagMirrorConfiguration(NtagMirrorMode mode, int page, int byte) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand(
        "AT+NMCFG=${mode.toProtocolString()},$page,$byte",
        1000,
        [
          ParserResponse("+NMCFG", (line) {
            error = line;
          })
        ],
      );
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setNtagModulationConfiguration(bool enableModulation) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand(
        "AT+NDCFG=${enableModulation.toProtocolString()}",
        1000,
        [
          ParserResponse("+NDCFG", (line) {
            error = line;
          })
        ],
      );
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }
  // endregion NTAG / Mifare Ultralight Commands
  // endregion ISO14A Commands

  // region Feedback
  @override
  Future<void> playFeedback(int feedbackId) async {
    if (!settings.hasBeeper) {
      return;
    }

    try {
      CmdExitCode exitCode = await sendCommand("AT+FDB=$feedbackId", 1000, []);
      _handleExitCode(exitCode, "");
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }
  // endregion Feedback

  @override
  Future<void> loadDeviceSettings() async {
    try {
      await getMode();
    } catch (ex, stack) {
      log("Failed to get mode", error: ex, stackTrace: stack);
    }

    await super.loadDeviceSettings();
  }
}
