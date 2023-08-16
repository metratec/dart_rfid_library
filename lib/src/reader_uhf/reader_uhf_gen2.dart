import 'dart:core';
import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dart_rfid_utils/dart_rfid_utils.dart';
import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/parser/parser.dart';
import 'package:reader_library/src/parser/parser_at.dart';

class UhfGen2ReaderSettings extends UhfReaderSettings {
  UhfGen2ReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get isUhfGen2Device => true;

  @override
  bool get supportsInventoryReport => true;

  @override
  List<Membank> get readMembanks => [Membank.epc, Membank.tid, Membank.user];
  @override
  List<Membank> get writeMembanks => [Membank.epc, Membank.user];
  @override
  List<Membank> get lockMembanks => [Membank.epc, Membank.user, Membank.lock, Membank.kill];

  bool? fastStart;
  bool? fastId;
  bool? tagFocus;

  @override
  List<ConfigElement> getConfigElements(UhfReader reader) {
    return [
      if (possiblePowerValues.length > 1)
        NumConfigElement<int>(
          name: "Power",
          group: "Inventory Options",
          value: currentPower,
          possibleValues: possiblePowerValues,
          setter: reader.setOutputPower,
        ),
      if (possibleQValues.length > 1)
        NumConfigElement<int>(
          name: "Q Value",
          group: "Inventory Options",
          value: currentQ,
          possibleValues: possibleQValues,
          setter: reader.setQStart,
        ),
      if (possibleRegionValues.length > 1)
        StringConfigElement(
          name: "Region",
          group: "Inventory Options",
          value: currentRegion,
          possibleValues: possibleRegionValues,
          setter: reader.setRegion,
        ),
      BoolConfigElement(
        name: "Fast Start",
        group: "Inventory Options",
        value: fastStart,
        setter: (val) => throw UnimplementedError("Fast start value has not been implemented yet"),
      ),
      if (antennaCount > 1)
        NumConfigElement<int>(
          name: "Mux",
          group: "Antenna/Mux",
          value: currentMuxAntenna,
          possibleValues: Iterable.generate(antennaCount, (i) => i + 1),
          setter: reader.setMuxAntenna,
        ),
      BoolConfigElement(
        name: "Fast Id",
        group: "Advanced Settings",
        value: fastId,
        setter: (val) => throw UnimplementedError("Fast id value has not been implemented yet"),
      ),
      BoolConfigElement(
        name: "Tag Focus",
        group: "Advanced Settings",
        value: tagFocus,
        setter: (val) => throw UnimplementedError("Fast id value has not been implemented yet"),
      ),
    ];
  }
}

class UhfReaderGen2 extends UhfReader {
  UhfInvSettings? _invSettings;
  final List<UhfInventoryResult> _cinv = [];

  UhfReaderGen2(CommInterface commInterface, UhfGen2ReaderSettings settings)
      : super(ParserAt(commInterface, "\r"), settings) {
    registerEvent(ParserResponse("+HBT", (_) => heartbeat.feed()));
    registerEvent(ParserResponse("+CINV", _handleCinvUrc));
    registerEvent(ParserResponse("+CMINV", _handleCinvUrc));
    registerEvent(ParserResponse("+CINVR", _handleCinvReportUrc));
  }

  void _handleExitCode(CmdExitCode code, String error) {
    if (code == CmdExitCode.timeout) {
      throw ReaderTimeoutException("Command timed out!");
    } else if (error == "<NO TAGS FOUND>") {
      throw ReaderNoTagsException("Command did not find any tags");
    } else if (code != CmdExitCode.ok) {
      throw ReaderException("Command failed with: $error");
    }
  }

  void _handleCinvUrc(String line) {
    if (_invSettings == null) {
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

    UhfTag? tag = _parseUhfTag(line.split(": ").last, _invSettings!);
    if (tag == null) {
      return;
    }

    _cinv.add(UhfInventoryResult(
      tag: tag,
      lastAntenna: 0,
      timestamp: DateTime.now(),
    ));
  }

  void _handleCinvReportUrc(String line) {
    if (_invSettings == null) {
      return;
    }

    if (line.contains("<")) {
      // TODO implement real info/error handling
      return;
    }

    UhfInventoryResult? result = _parseInventoryReport(line.split(": ").last, _invSettings!);
    if (result == null) {
      return;
    }

    _cinv.add(result);
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

    if (settings.tid == false && settings.rssi == false && tokens.length == 1) {
      return UhfTag(tokens.first, '', 0);
    } else if (settings.tid == false && settings.rssi == true && tokens.length == 2) {
      return UhfTag(tokens.first, '', int.tryParse(tokens.last) ?? 0);
    } else if (settings.tid == true && settings.rssi == false && tokens.length == 2) {
      return UhfTag(tokens.first, tokens.last, 0);
    } else if (settings.tid == true && settings.rssi == true && tokens.length == 3) {
      return UhfTag(tokens[0], tokens[1], int.tryParse(tokens[2]) ?? 0);
    }

    return null;
  }

  /// Parse an InventoryResult from an inventory report response.
  UhfInventoryResult? _parseInventoryReport(String report, UhfInvSettings settings) {
    List<String> tokens = report.split(',');

    UhfTag? tag;

    if (settings.tid == false && settings.rssi == false && tokens.length == 2) {
      tag = UhfTag(tokens[0], '', 0);
    } else if (settings.tid == false && settings.rssi == true && tokens.length == 3) {
      tag = UhfTag(tokens[0], '', int.tryParse(tokens[1]) ?? 0);
    } else if (settings.tid == true && settings.rssi == false && tokens.length == 3) {
      tag = UhfTag(tokens[0], tokens.last, 0);
    } else if (settings.tid == true && settings.rssi == true && tokens.length == 4) {
      tag = UhfTag(tokens[0], tokens[1], int.tryParse(tokens[2]) ?? 0);
    }

    if (tag != null) {
      return UhfInventoryResult(
        tag: tag,
        lastAntenna: int.tryParse(tokens.last) ?? 1,
        count: 1,
        timestamp: DateTime.now(),
      );
    }

    return null;
  }

  @override
  Future<List<UhfInventoryResult>> inventory() async {
    List<UhfTag> inv = [];
    String error = "";

    _invSettings = await getInventorySettings();

    try {
      CmdExitCode exitCode = await sendCommand("AT+INV", 5000, [
        ParserResponse("+INV", (line) {
          if (line.contains("<")) {
            return;
          }

          UhfTag? tag = _parseUhfTag(line, _invSettings!);
          if (tag != null) {
            inv.add(tag);
          }
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return inv
        .map((e) => UhfInventoryResult(
              tag: e,
              lastAntenna: settings.invAntenna,
              count: 1,
              timestamp: DateTime.now(),
            ))
        .toList();
  }

  Future<List<UhfInventoryResult>> muxInventory() async {
    List<UhfTag> inv = [];
    List<UhfInventoryResult> invResults = [];
    String error = "";

    _invSettings = await getInventorySettings();

    try {
      CmdExitCode exitCode = await sendCommand("AT+MINV", 5000, [
        ParserResponse("+MINV", (line) {
          if (line.contains("ROUND FINISHED")) {
            int antenna = _parseAntenna(line);
            for (UhfTag e in inv) {
              invResults.add(
                UhfInventoryResult(tag: e, lastAntenna: antenna, timestamp: DateTime.now()),
              );
            }
            inv.clear();
          } else if (!line.contains("<")) {
            UhfTag? tag = _parseUhfTag(line, _invSettings!);
            if (tag != null) {
              inv.add(tag);
            }
          }
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return invResults;
  }

  Future<List<UhfInventoryResult>> inventoryReport({int inventoryReportDuration = 100}) async {
    List<UhfInventoryResult> report = [];
    String error = "";

    _invSettings = await getInventorySettings();

    try {
      CmdExitCode exitCode = await sendCommand("AT+INVR=$inventoryReportDuration", 5000, [
        ParserResponse("+INVR", (line) {
          UhfInventoryResult? tag = _parseInventoryReport(line, _invSettings!);
          if (tag != null) {
            report.add(tag);
          }
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return report;
  }

  @override
  Future<int> getInvAntenna() async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+ANT?", 5000, [
        ParserResponse("+ANT", (line) {
          settings.invAntenna = int.tryParse(line) ?? settings.invAntenna;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return settings.invAntenna;
  }

  @override
  Future<void> setInvAntenna(int val) async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand("AT+ANT=$val", 1000, [
        ParserResponse("+ANT", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
      settings.invAntenna = val;
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }
  }

  @override
  Future<void> startContinuousInventory() async {
    _invSettings = await getInventorySettings();

    try {
      CmdExitCode exitCode = await sendCommand("AT+CINV", 1000, []);
      _handleExitCode(exitCode, "");
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }
  }

  @override
  Future<void> stopContinuousInventory() async {
    try {
      CmdExitCode exitCode = await sendCommand("AT+BINV", 1000, []);
      _handleExitCode(exitCode, "");
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }
  }

  Future<void> startContinuousMuxInventory() async {
    _invSettings = await getInventorySettings();

    try {
      CmdExitCode exitCode = await sendCommand("AT+CMINV", 1000, []);
      _handleExitCode(exitCode, "");
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  Future<void> stopContinuousMuxInventory() async {
    try {
      CmdExitCode exitCode = await sendCommand("AT+BINV", 1000, []);
      _handleExitCode(exitCode, "");
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }
  }

  Future<void> startContinuousInventoryReport({int inventoryReportDuration = 200}) async {
    // TODO current implementation does nothing
    throw UnimplementedError();

    _invSettings = await getInventorySettings();

    try {
      CmdExitCode exitCode = await sendCommand("AT+CINVR=$inventoryReportDuration", 1000, []);
      _handleExitCode(exitCode, "");
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  Future<void> stopContinuousInventoryReport() async {
    // TODO current implementation does nothing
    throw UnimplementedError();

    try {
      CmdExitCode exitCode = await sendCommand("AT+BINVR", 1000, []);
      _handleExitCode(exitCode, "");
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }
  }

  @override
  Future<void> setByteMask(String memBank, int start, String mask) async {
    if (UhfMemoryBank.values.none((e) => e.protocolString == memBank)) {
      throw ReaderException("Unsupported memory bank: $memBank");
    } else if (!hexRegEx.hasMatch(mask)) {
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
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
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
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
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
      _invSettings = settings;
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }
  }

  @override
  Future<int> getOutputPower() async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+PWR?", 1000, [
        ParserResponse("+PWR", (line) {
          final split = line.split(",");
          settings.antennaCount = split.length;
          final powerString = split[0];
          settings.currentPower = int.tryParse(powerString) ?? settings.minPower;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return settings.currentPower!;
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
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    settings.currentPower = val;
  }

  @override
  Future<int> getQ() async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+Q?", 1000, [
        ParserResponse("+Q", (line) {
          final splitValues = line.split(",");
          if (splitValues.length != 3) {
            return;
          }

          settings.currentQ = int.tryParse(splitValues[0]) ?? settings.minQ;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return settings.currentQ!;
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
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    settings.currentQ = val;
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
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    settings.currentQ = val;
  }

  @override
  Future<UhfReaderRegion> getRegion() async {
    String error = "";
    String? region;

    try {
      CmdExitCode exitCode = await sendCommand("AT+REG?", 1000, [
        ParserResponse("+REG", (line) {
          region = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    UhfReaderRegion? regionValue = UhfReaderRegion.values.firstWhereOrNull((e) => e.protocolString == region);
    if (regionValue == null) {
      throw ReaderException("Received unsupported region: $region");
    }

    settings.currentRegion = region;
    return regionValue;
  }

  @override
  Future<void> setRegion(String region) async {
    if (UhfReaderRegion.values.none((e) => e.protocolString == region)) {
      throw ReaderException("Unsupported region: $region");
    }

    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+REG=$region", 1000, [
        ParserResponse("+REG", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    settings.currentRegion = region;
  }

  @override
  Future<int> getMuxAntenna() async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+MUX?", 1000, [
        ParserResponse("+MUX", (line) {
          // TODO AT+MUX supports lists of ints so getMuxAntenna should support it too
          final splitValues = line.split(",");
          settings.currentMuxAntenna = int.tryParse(splitValues[0]) ?? settings.currentMuxAntenna;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return settings.currentMuxAntenna;
  }

  @override
  Future<void> setMuxAntenna(int val) async {
    // TODO AT+MUX supports lists of ints so getMuxAntenna should support it too
    if (val > settings.antennaCount) {
      throw ReaderException("Mux value not in antenna range");
    }

    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+MUX=$val", 1000, [
        ParserResponse("+MUX", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    settings.currentMuxAntenna = val;
  }

  Future<List<bool>> getOutputStates() async {
    String error = "";
    List<bool> states = [];
    try {
      CmdExitCode exitCode = await sendCommand("AT+OUT?", 1000, [
        ParserResponse("+OUT", (line) {
          final split = line.split(",");
          if (split.length < 2) {
            return;
          }
          states.add(split[1] == "HIGH");
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    settings.outputStates = states;
    return states;
  }

  Future<void> setOutputStates(List<bool> values) async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand(
        "AT+OUT=${values.map((e) => e ? 1 : 0).join(",")}",
        1000,
        [
          ParserResponse("+OUT", (line) {
            error = line;
          })
        ],
      );
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    settings.outputStates = values;
  }

  Future<List<bool>> getInputStates() async {
    String error = "";
    List<bool> states = [];
    try {
      CmdExitCode exitCode = await sendCommand("AT+IN?", 1000, [
        ParserResponse("+IN", (line) {
          final split = line.split(",");
          if (split.length < 2) {
            return;
          }
          states.add(split[1] == "HIGH");
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    settings.inputStates = states;
    return states;
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
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
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
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }
  }

  @override
  Future<void> stopHeartBeat() async {
    heartbeat.stop();
    try {
      CmdExitCode exitCode = await sendCommand("AT+HBT=0", 1000, []);
      _handleExitCode(exitCode, "");
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }
  }

  @override
  Future<List<UhfRwResult>> write(String memBank, int start, String data, {String? mask}) async {
    if (settings.writeMembanks.none((e) => e.protocolString == memBank)) {
      throw ReaderException("Unsupported memory bank: $memBank");
    } else if (!hexRegEx.hasMatch(data)) {
      throw ReaderException("Unsupported data! Must be a hex string");
    } else if (mask != null && !hexRegEx.hasMatch(mask)) {
      throw ReaderException("Unsupported mask! Must be a hex string");
    }

    String error = "";
    String maskString = mask == null ? "" : ",$mask";
    List<UhfRwResult> res = [];

    try {
      CmdExitCode exitCode = await sendCommand("AT+WRT=$memBank,$start,$data$maskString", 2000, [
        ParserResponse("+WRT", (line) {
          if (line.contains("<NO TAGS FOUND>")) {
            error = line;
            return;
          }

          List<String> tokens = line.split(',');
          res.add(UhfRwResult(tokens.first, tokens.last == "OK", Uint8List(0)));
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return res;
  }

  @override
  Future<List<UhfRwResult>> read(String memBank, int start, int length, {String? mask}) async {
    if (settings.readMembanks.none((e) => e.protocolString == memBank)) {
      throw ReaderException("Unsupported memory bank: $memBank");
    } else if (mask != null && !hexRegEx.hasMatch(mask)) {
      throw ReaderException("Unsupported mask! Must be a hex string");
    }

    List<UhfRwResult> res = [];
    String error = "";
    String maskString = mask == null ? "" : ",$mask";

    try {
      CmdExitCode exitCode = await sendCommand("AT+READ=$memBank,$start,$length$maskString", 2000, [
        ParserResponse("+READ", (line) {
          if (line.contains("<NO TAGS FOUND>")) {
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
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return res;
  }

  @override
  Future<void> loadDeviceSettings() async {
    if (settings.supportsOutputs) {
      try {
        await getOutputStates();
      } catch (ex, stack) {
        readerLogger.e("Failed to load device setting: output states", ex, stack);
      }
    }

    if (settings.supportsInputs) {
      try {
        await getInputStates();
      } catch (ex, stack) {
        readerLogger.e("Failed to load device setting: input states", ex, stack);
      }
    }

    await super.loadDeviceSettings();
  }
}
