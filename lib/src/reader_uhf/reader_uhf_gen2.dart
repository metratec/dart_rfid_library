import 'dart:typed_data';
import 'dart:core';

import 'package:metratec_device/metratec_device.dart';
import 'package:reader_library/src/parser/parser.dart';
import 'package:reader_library/src/parser/parser_at.dart';
import 'package:reader_library/src/reader_exception.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf.dart';
import 'package:reader_library/src/utils/convert.dart';
import 'package:reader_library/src/utils/tags.dart';

class UhfReaderGen2 extends UhfReader {
  UhfInvSettings? _cinvSettings;
  final List<UhfInventoryEntry> _cinv = [];

  UhfReaderGen2(CommInterface commInterface, UhfReaderSettings settings)
      : super(ParserAt(commInterface, "\r"), settings) {
    registerEvent(ParserResponse("+HBT", (_) => heartbeat.feed()));
    registerEvent(ParserResponse("+CINV", _handleCinvUrc));
  }

  void _handleExitCode(CmdExitCode code, String error) {
    if (code == CmdExitCode.timeout) {
      throw ReaderTimeoutException("Command timed out!");
    } else if (code != CmdExitCode.ok) {
      throw ReaderException("Command failed with: $error");
    }
  }

  void _handleCinvUrc(String line) {
    if (_cinvSettings == null) {
      return;
    }

    if (line.contains("ROUND FINISHED")) {
      List<UhfInventoryEntry> inv = [];
      inv.addAll(_cinv);
      _cinv.clear();

      int antenna = _parseAntenna(line);
      for (UhfInventoryEntry entry in inv) {
        entry.antenna = antenna;
      }

      cinvStreamCtrl.add(inv);
      return;
    } else if (line.contains("<")) {
      return;
    }

    UhfTag? tag = _parseUhfTag(line.split(": ").last, _cinvSettings!);
    if (tag == null) {
      return;
    }

    _cinv.add(UhfInventoryEntry(tag, 0, 1));
  }

  /// Parse the antenna number from a inventory report.
  int _parseAntenna(String line) {
    if (line.contains("ANT") == false) {
      return 0;
    }

    return int.parse(line.split(',').last.split('=').last.replaceAll(">", ""),
        radix: 10);
  }

  /// Parse a tag from an inventory response.
  UhfTag? _parseUhfTag(String inv, UhfInvSettings settings) {
    List<String> tokens = inv.split(',');

    if (settings.tid == false && settings.rssi == false) {
      return UhfTag(tokens.first, '', 0);
    } else if (settings.tid == false && settings.rssi == true) {
      return UhfTag(tokens.first, '', int.parse(tokens.last));
    } else if (settings.tid == true && settings.rssi == false) {
      return UhfTag(tokens.first, tokens.last, 0);
    } else if (settings.tid == true && settings.rssi == true) {
      return UhfTag(tokens[0], tokens[1], int.parse(tokens[2]));
    }

    return null;
  }

  @override
  Future<List<UhfTag>> inventory() async {
    List<UhfTag> inv = [];
    String error = "";

    UhfInvSettings invSettings = await getInventorySettings();

    try {
      CmdExitCode exitCode = await sendCommand("AT+INV", 5000, [
        ParserResponse("+INV", (line) {
          if (line.contains("<")) {
            return;
          }

          UhfTag? tag = _parseUhfTag(line, invSettings);
          if (tag != null) {
            inv.add(tag);
          }
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
    _cinvSettings = await getInventorySettings();

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
      CmdExitCode exitCode = await sendCommand("AT+BINV", 1000, []);
      _handleExitCode(exitCode, "");
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setByteMask(
      UhfMemoryBank bank, int start, Uint8List mask) async {
    String error = "";
    String maskString = uint8ListToString(mask);
    String bankString = bank.toString().split('.').last;

    try {
      CmdExitCode exitCode =
          await sendCommand("AT+MSK=$bankString,$start,$maskString", 1000, [
        ParserResponse("+MSK", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> clearByteMask() async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand("AT+MSK=OFF", 1000, [
        ParserResponse("+MSK", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  String _boolTo01(bool b) {
    return b ? '1' : '0';
  }

  @override
  Future<void> setInventorySettings(UhfInvSettings settings) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand(
          "AT+INVS=${_boolTo01(settings.ont)},${_boolTo01(settings.rssi)},${_boolTo01(settings.tid)}",
          1000, [
        ParserResponse("+INVS", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setOutputPower(int val) async {
    if (val < settings.minPower || val > settings.maxPower) {
      throw ReaderException(
          "Power value not in range [${settings.minPower}, ${settings.maxPower}]");
    }

    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+PWR=$val", 1000, [
        ParserResponse("+PWR", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setQ(int val, int min, int max) async {
    if (val < UhfReaderSettings.minQ || val > UhfReaderSettings.maxQ) {
      throw ReaderException(
          "Q value not in range [${UhfReaderSettings.minQ}, ${UhfReaderSettings.maxQ}]");
    } else if (min < UhfReaderSettings.minQ || min > UhfReaderSettings.maxQ) {
      throw ReaderException(
          "Q min not in range [${UhfReaderSettings.minQ}, ${UhfReaderSettings.maxQ}]");
    } else if (max < UhfReaderSettings.minQ || max > UhfReaderSettings.maxQ) {
      throw ReaderException(
          "Q max not in range [${UhfReaderSettings.minQ}, ${UhfReaderSettings.maxQ}]");
    } else if (min > max) {
      throw ReaderException("Q min greater than Q max");
    }

    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+Q=$val,$min,$max", 1000, [
        ParserResponse("+Q", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setQStart(int val) async {
    if (val < UhfReaderSettings.minQ || val > UhfReaderSettings.maxQ) {
      throw ReaderException(
          "Q value not in range [${UhfReaderSettings.minQ}, ${UhfReaderSettings.maxQ}]");
    }

    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+Q=$val", 1000, [
        ParserResponse("+Q", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<UhfInvSettings> getInventorySettings() async {
    UhfInvSettings? invSettings;
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+INVS?", 1000, [
        ParserResponse("+INVS", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          List<bool> settings = line.split(",").map((e) => (e == '1')).toList();
          invSettings = UhfInvSettings(settings[0], settings[1], settings[2]);
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    if (invSettings == null) {
      throw ReaderException("Failed to retrieve settings");
    }

    return invSettings!;
  }

  @override
  Future<void> startHeartBeat(
      int seconds, Function onHbt, Function onTimeout) async {
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
  Future<List<UhfRwResult>> write(UhfMemoryBank bank, int start, Uint8List data,
      {Uint8List? mask}) async {
    String error = "";
    String bankString = bank.toString().split('.').last;
    String maskString = mask == null ? "" : ",${uint8ListToString(mask)}";
    String dataString = uint8ListToString(data);
    List<UhfRwResult> res = [];

    try {
      CmdExitCode exitCode = await sendCommand(
          "AT+WRT=$bankString,$start,$dataString$maskString", 2000, [
        ParserResponse("+WRT", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          List<String> tokens = line.split(',');
          res.add(UhfRwResult(tokens.first, tokens.last == "OK", Uint8List(0)));
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    return res;
  }

  @override
  Future<List<UhfRwResult>> read(UhfMemoryBank bank, int start, int length,
      {Uint8List? mask}) async {
    List<UhfRwResult> res = [];
    String error = "";
    String bankString = bank.toString().split('.').last;
    String maskString = mask == null ? "" : ",${uint8ListToString(mask)}";

    try {
      CmdExitCode exitCode = await sendCommand(
          "AT+READ=$bankString,$start,$length$maskString", 2000, [
        ParserResponse("+READ", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          List<String> tokens = line.split(',');
          if (tokens[1] == "OK") {
            res.add(UhfRwResult(tokens[0], true, stringToUint8List(tokens[2])));
          } else {
            res.add(UhfRwResult(tokens[0], false, Uint8List(0)));
          }
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    return res;
  }
}
