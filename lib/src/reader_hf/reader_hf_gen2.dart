import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dart_rfid_utils/dart_rfid_utils.dart';
import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/parser/parser.dart';
import 'package:reader_library/src/parser/parser_at.dart';

class HfGen2ReaderSettings extends HfReaderSettings {
  @override
  bool get isHfGen2Device => true;
}

class HfReaderGen2 extends HfReader {
  final List<HfTag> _inventory = [];
  bool _runDetectionLoop = false;

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

    String uid = line.split(': ').last;
    _inventory.add(HfTag(
      uid,
      settings.availableTagTypes[uid] ?? TagType.unknown,
    ));
  }

  void _handleHbtUrc(String line) {
    heartbeat.feed();
  }

  void _handleExitCode(CmdExitCode code, String error) {
    if (code == CmdExitCode.timeout) {
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
      }
    } else {
      // We set afi to 0 as default value so its not null
      settings.afi = 0;
    }

    return settings.mode;
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
      await detectTagTypes();
      CmdExitCode exitCode = await sendCommand("AT+CINV", 1000, []);
      _handleExitCode(exitCode, "");
      unawaited(_startDetectTagTypeLoop());
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> stopContinuousInventory() async {
    try {
      CmdExitCode exitCode = await sendCommand("AT+BINV", 3000, []);
      _handleExitCode(exitCode, "");
      _stopDetectTagTypeLoop();
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
  Future<String> read(int block) async {
    String data = "";
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+READ=$block", 2000, [
        ParserResponse("+READ", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          data = line;
        })
      ]);
      _handleExitCode(exitCode, error);
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
          final tagType = TagType.values.firstWhereOrNull((e) => e.protocolString == tagTypeString) ?? TagType.unknown;

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
  Future<void> mfcAuth(int block, Uint8List key, MfcKeyType keyType) async {
    if (key.length != 6) {
      throw ReaderException("Wrong key size for MFC");
    }

    String typeString = keyType.toString().split('.').last;
    String keyString = key.toHexString();
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+AUT=$block,$keyString,$typeString", 1000, [
        ParserResponse("+AUT", (line) {
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

  Future<void> _startDetectTagTypeLoop() async {
    _runDetectionLoop = true;
    while (_runDetectionLoop) {
      await detectTagTypes();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  void _stopDetectTagTypeLoop() {
    _runDetectionLoop = false;
  }

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
