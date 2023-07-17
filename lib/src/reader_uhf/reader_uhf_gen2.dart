import 'dart:core';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:metratec_device/metratec_device.dart';
import 'package:reader_library/src/parser/parser.dart';
import 'package:reader_library/src/parser/parser_at.dart';
import 'package:reader_library/src/reader_exception.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf.dart';
import 'package:reader_library/src/utils/extensions.dart';
import 'package:reader_library/src/utils/uhf_inventory_result.dart';

class UhfReaderGen2 extends UhfReader {
  UhfInvSettings? _cinvSettings;
  final List<UhfInventoryResult> _cinv = [];
  final RegExp _hexRegEx = RegExp(r"^[a-fA-F0-9]+$");

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
      List<UhfInventoryResult> inv = [];
      inv.addAll(_cinv);
      _cinv.clear();

      int antenna = _parseAntenna(line);
      for (UhfInventoryResult entry in inv) {
        entry.lastAntenna = antenna;
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

    _cinv.add(UhfInventoryResult(
      tag: tag,
      lastAntenna: 0,
      count: 1,
      timestamp: DateTime.now(),
    ));
  }

  /// Parse the antenna number from a inventory report.
  int _parseAntenna(String line) {
    if (line.contains("ANT") == false) {
      return 0;
    }

    return int.parse(line.split(',').last.split('=').last.replaceAll(">", ""), radix: 10);
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
  Future<List<UhfInventoryResult>> inventory() async {
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

    return inv
        .map((e) => UhfInventoryResult(
              tag: e,
              lastAntenna: invAntenna,
              count: 1,
              timestamp: DateTime.now(),
            ))
        .toList();
  }

  /// Sets the [invAntenna] field to its real value and return it afterwards
  ///
  /// Must only be called once. The [invAntenna] field can be used synchronously in most cases
  Future<int> getInvAntenna() async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+INV", 5000, [
        ParserResponse("+ANT", (line) {
          final split = line.split(":");
          if (split.length < 2) {
            return;
          }
          invAntenna = int.tryParse(split[1]) ?? invAntenna;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    return invAntenna;
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
  Future<void> setByteMask(String memBank, int start, String mask) async {
    if (UhfMemoryBank.values.none((e) => e.protocolString == memBank)) {
      throw ReaderException("Unsupported memory bank: $memBank");
    } else if (!_hexRegEx.hasMatch(mask)) {
      throw ReaderException("Unsupported mask! Must be a hex string");
    }

    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand("AT+MSK=$memBank,$start,$mask", 1000, [
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
          "AT+INVS=${_boolTo01(settings.ont)},${_boolTo01(settings.rssi)},${_boolTo01(settings.tid)}", 1000, [
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
  Future<int> getOutputPower() async {
    String error = "";
    var power = settings.minPower;

    try {
      CmdExitCode exitCode = await sendCommand("AT+PWR?", 1000, [
        ParserResponse("+PWR", (line) {
          final powerString = line.split(",")[0];
          power = int.tryParse(powerString) ?? settings.minPower;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    return power;
  }

  @override
  Future<void> setOutputPower(int val) async {
    if (val < settings.minPower || val > settings.maxPower) {
      throw ReaderException("Power value not in range [${settings.minPower}, ${settings.maxPower}]");
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
  Future<(int, int, int)> getQ() async {
    String error = "";
    var qValues = (0, 0, 0);

    try {
      CmdExitCode exitCode = await sendCommand("AT+Q?", 1000, [
        ParserResponse("+Q", (line) {
          final splitValues = line.split(",");
          if (splitValues.length != 3) {
            return;
          }

          qValues = (
            int.tryParse(splitValues[0]) ?? settings.minQ,
            int.tryParse(splitValues[1]) ?? settings.minQ,
            int.tryParse(splitValues[2]) ?? settings.maxQ,
          );
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    return qValues;
  }

  @override
  Future<void> setQ(int val, int min, int max) async {
    if (val < settings.minQ || val > settings.maxQ) {
      throw ReaderException("Q value not in range [${settings.minQ}, ${settings.maxQ}]");
    } else if (min < settings.minQ || min > settings.maxQ) {
      throw ReaderException("Q min not in range [${settings.minQ}, ${settings.maxQ}]");
    } else if (max < settings.minQ || max > settings.maxQ) {
      throw ReaderException("Q max not in range [${settings.minQ}, ${settings.maxQ}]");
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
    if (val < settings.minQ || val > settings.maxQ) {
      throw ReaderException("Q value not in range [${settings.minQ}, ${settings.maxQ}]");
    }
    final minValue = max(val - 2, settings.minQ);
    final maxValue = min(val + 2, settings.maxQ);

    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+Q=$val,$minValue,$maxValue", 1000, [
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
  Future<List<UhfRwResult>> write(String memBank, int start, String data, {String? mask}) async {
    if (UhfMemoryBank.values.none((e) => e.protocolString == memBank)) {
      throw ReaderException("Unsupported memory bank: $memBank");
    } else if (!_hexRegEx.hasMatch(data)) {
      throw ReaderException("Unsupported data! Must be a hex string");
    } else if (mask != null && !_hexRegEx.hasMatch(mask)) {
      throw ReaderException("Unsupported mask! Must be a hex string");
    }

    String error = "";
    String maskString = mask == null ? "" : ",$mask";
    List<UhfRwResult> res = [];

    try {
      CmdExitCode exitCode = await sendCommand("AT+WRT=$memBank,$start,$data$maskString", 2000, [
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
  Future<List<UhfRwResult>> read(String memBank, int start, int length, {String? mask}) async {
    if (UhfMemoryBank.values.none((e) => e.protocolString == memBank)) {
      throw ReaderException("Unsupported memory bank: $memBank");
    } else if (mask != null && !_hexRegEx.hasMatch(mask)) {
      throw ReaderException("Unsupported mask! Must be a hex string");
    }

    List<UhfRwResult> res = [];
    String error = "";
    String maskString = mask == null ? "" : ",$mask";

    try {
      CmdExitCode exitCode = await sendCommand("AT+READ=$memBank,$start,$length$maskString", 2000, [
        ParserResponse("+READ", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          List<String> tokens = line.split(',');
          if (tokens[1] == "OK") {
            res.add(UhfRwResult(tokens[0], true, tokens[2].hexStringToBytes()));
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
