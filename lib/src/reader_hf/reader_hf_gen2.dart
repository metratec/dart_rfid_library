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

  HfReaderGen2(CommInterface commInterface, HfGen2ReaderSettings settings)
      : super(ParserAt(commInterface, "\r"), settings) {
    registerEvent(ParserResponse("+CINV", _handleCinvUrc));
    registerEvent(ParserResponse("+HBT", _handleHbtUrc));
  }

  void _handleCinvUrc(String line) {
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
    _inventory.add(HfTag(uid, "Unknown"));
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

          final bool canDetermineTagType = availableTagTypes.length == 1;

          inv.add(HfInventoryResult(
            tag: HfTag(
              line,
              canDetermineTagType ? availableTagTypes.first : "Unknown",
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
  }

  @override
  Future<Iterable<String>> detectTagTypes() async {
    String error = "";
    final availableTagTypes = <String>{};

    try {
      CmdExitCode exitCode = await sendCommand("AT+DTT", 1000, [
        ParserResponse("+DTT", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          availableTagTypes.add(line);
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    settings.availableTagTypes = availableTagTypes;
    return settings.availableTagTypes;
  }

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

  @override
  Future<void> loadDeviceSettings() async {}
}
