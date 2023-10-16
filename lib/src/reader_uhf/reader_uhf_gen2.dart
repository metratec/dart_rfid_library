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

  UhfInvSettings? invSettings;

  bool? fastId;
  bool? tagFocus;

  /// The current rf mode value. Should always be set if the reader checks the rf mode value
  int? currentRfMode;

  /// The current rf mode value. Should always be set if the reader checks the rf mode value
  List<int>? currentMultiplexer;

  Iterable<int> possibleRfModeValues(String region) {
    if (region == "FCC") {
      return [103, 120, 222, 223, 241, 244, 285, 302, 323, 344, 345];
    }

    return [222, 223, 241, 244, 285];
  }

  String? currentSession;

  List<String> possibleSessionValues = ["AUTO", "0", "1", "2", "3"];

  bool? highOnTag;
  int? highOnTagPin;
  int? highOnTagDuration;

  @override
  List<ConfigElement> getConfigElements(UhfReader reader) {
    if (reader is! UhfReaderGen2) {
      return super.getConfigElements(reader);
    }

    return [
      if (possiblePowerValues.length > 1)
        ConfigElementGroup(
          name: "Power Values",
          setter: (val) async {
            final powerValues = val.map((e) => e.value).whereType<int>().toList();
            await reader.setOutputPower(powerValues);
          },
          category: "Inventory Options",
          isEnabled: (configs) => true,
          addDivider: true,
          value: [
            for (var (index, powerVal) in (currentPower ?? []).indexed)
              NumConfigElement<int>(
                name: (currentPower?.length ?? 0) > 1 ? "Power Ant ${index + 1}" : "Power",
                category: "Inventory Options",
                value: powerVal,
                possibleValues: (configs) => possiblePowerValues,
                isEnabled: (configs) => true,
                setter: (val) async {},
              ),
          ],
        ),
      if (possibleRegionValues.length > 1)
        StringConfigElement(
          name: "Region",
          category: "Inventory Options",
          value: currentRegion,
          possibleValues: (configs) => possibleRegionValues,
          isEnabled: (configs) => true,
          setter: reader.setRegion,
        ),
      if (possibleQValues.length > 1)
        ConfigElementGroup(
          name: "Q Value",
          category: "Inventory Options",
          addDivider: true,
          setter: (val) async {
            final int qStartVal = val.firstWhereOrNull((e) => e.name == "Q Start")?.value ?? 5;
            final int qMinVal = val.firstWhereOrNull((e) => e.name == "Q Min")?.value ?? possibleQValues.first;
            final int qMaxVal = val.firstWhereOrNull((e) => e.name == "Q Max")?.value ?? possibleQValues.last;

            await reader.setQ(qStartVal, qMinVal, qMaxVal);
          },
          isEnabled: (configs) => true,
          value: [
            NumConfigElement<int>(
              name: "Q Start",
              category: "Inventory Options",
              value: currentQ,
              possibleValues: (configs) {
                final int qMinVal = configs.firstWhereOrNull((e) => e.name == "Q Min")?.value ?? possibleQValues.first;
                final int qMaxVal = configs.firstWhereOrNull((e) => e.name == "Q Max")?.value ?? possibleQValues.last;

                return List.generate(qMaxVal - qMinVal + 1, (index) => qMinVal + index);
              },
              isEnabled: (configs) => true,
              setter: (val) async {},
            ),
            NumConfigElement<int>(
              name: "Q Min",
              category: "Inventory Options",
              value: currentMinQ,
              possibleValues: (configs) => possibleQValues,
              isEnabled: (configs) => true,
              setter: (val) async {},
            ),
            NumConfigElement<int>(
              name: "Q Max",
              category: "Inventory Options",
              value: currentMaxQ,
              possibleValues: (configs) => possibleQValues,
              isEnabled: (configs) => true,
              setter: (val) async {},
            ),
          ],
        ),
      if (antennaCount > 1)
        ListConfigElement<int>(
          name: "Mux Sequence",
          category: "Antenna/Mux",
          value: currentMuxAntenna,
          possibleValues: (config) => Iterable.generate(antennaCount, (i) => i + 1),
          isEnabled: (configs) => true,
          stringToElementConverter: int.parse,
          setter: reader.setMuxAntenna,
        ),
      if (supportsOutputs)
        ConfigElementGroup(
          name: "Ext. Multiplexer",
          setter: (val) async {
            final muxValues = val
                .map<int>((e) => switch (e.value) {
                      "4x" => 4,
                      "8x" => 8,
                      "16x" => 16,
                      _ => 0,
                    })
                .toList();
            await reader.setMultiplexer(muxValues);
          },
          category: "Antenna/Mux",
          isEnabled: (configs) => true,
          addDivider: true,
          value: [
            for (var (index, muxVal) in (currentMultiplexer ?? []).indexed)
              StringConfigElement(
                name: "Ext. Multiplexer Port ${index + 1}",
                category: "Inventory Options",
                value: switch (muxVal) {
                  4 => "4x",
                  8 => "8x",
                  16 => "16x",
                  _ => "no",
                },
                possibleValues: (configs) => ["no", "4x", "8x", "16x"],
                isEnabled: (configs) => true,
                setter: (val) async {},
              ),
          ],
        ),
      NumConfigElement<int>(
        name: "Rf Mode",
        category: "Advanced Settings",
        value: currentRfMode,
        isEnum: true,
        possibleValues: (configs) {
          final String region = configs.firstWhereOrNull((e) => e.name == "Region")?.value ?? "ETSI";
          var possibleValues = possibleRfModeValues(region);
          if (currentRfMode != null && !possibleValues.contains(currentRfMode)) {
            possibleValues = possibleValues.toList()..add(currentRfMode!);
          }
          return possibleValues;
        },
        isEnabled: (configs) => true,
        setter: reader.setRfMode,
      ),
      ConfigElementGroup(
        name: "Inventory Settings",
        category: "Advanced Settings",
        isEnabled: (configs) => true,
        setter: (val) async {
          final bool onlyNewTagVal = val.firstWhereOrNull((e) => e.name == "Only new Tags")?.value ?? false;
          final bool fastStartVal = val.firstWhereOrNull((e) => e.name == "Fast Start")?.value ?? false;
          invSettings ??= UhfInvSettings(onlyNewTagVal, false, false, fastStartVal);
          invSettings?.ont = onlyNewTagVal;
          invSettings?.fastStart = fastStartVal;

          await reader.setInventorySettings(invSettings!);
        },
        value: [
          BoolConfigElement(
            name: "Fast Start",
            value: invSettings?.fastStart,
            isEnabled: (configs) => true,
            setter: (val) async {},
          ),
          BoolConfigElement(
            name: "Only new Tags",
            value: invSettings?.ont,
            isEnabled: (configs) => true,
            setter: (val) async {},
          ),
        ],
      ),
      ConfigElementGroup(
        name: "Advanced Settings Group",
        setter: (val) async {
          final bool fastIdVal = val.firstWhereOrNull((e) => e.name == "Fast Id")?.value ?? false;
          final bool tagFocusVal = val.firstWhereOrNull((e) => e.name == "Tag Focus")?.value ?? false;

          await reader.setImpinjSettings(fastIdVal, tagFocusVal);
        },
        category: "Advanced Settings",
        isEnabled: (configs) => true,
        value: [
          BoolConfigElement(
            name: "Fast Id",
            category: "Advanced Settings",
            value: fastId,
            isEnabled: (configs) => true,
            setter: (val) async {},
          ),
          BoolConfigElement(
            name: "Tag Focus",
            category: "Advanced Settings",
            value: tagFocus,
            isEnabled: (configs) => true,
            setter: (val) async {},
          ),
        ],
      ),
      StringConfigElement(
        name: "Session",
        category: "Advanced Settings",
        value: currentSession,
        possibleValues: (configs) => possibleSessionValues,
        isEnabled: (configs) => true,
        setter: (val) async {
          await reader.setSession(val);
        },
      ),
      if (supportsOutputs)
        ConfigElementGroup(
          name: "High on Tag Group",
          setter: (val) async {
            final bool highOnTagVal = val.firstWhereOrNull((e) => e.name == "High on Tag")?.value ?? false;
            final int highOnTagPinVal = val.firstWhereOrNull((e) => e.name == "High on Tag Pin")?.value ?? 1;
            final int highOnTagDurationVal =
                val.firstWhereOrNull((e) => e.name == "High on Tag Duration")?.value ?? 100;

            await reader.setHighOnTag(highOnTagVal, highOnTagPinVal, highOnTagDurationVal);
          },
          category: "Advanced Settings",
          isEnabled: (configs) => true,
          addDivider: true,
          value: [
            BoolConfigElement(
              name: "High on Tag",
              category: "Advanced Settings",
              value: highOnTag,
              isEnabled: (configs) => true,
              setter: (val) async {},
            ),
            NumConfigElement<int>(
              name: "High on Tag Pin",
              category: "Advanced Settings",
              value: highOnTagPin,
              isEnabled: (configs) =>
                  (configs.firstWhereOrNull((e) => e.name == "High on Tag") as BoolConfigElement?)?.value ?? false,
              setter: (val) async {},
            ),
            NumConfigElement<int>(
              name: "High on Tag Duration",
              category: "Advanced Settings",
              value: highOnTagDuration,
              isEnabled: (configs) =>
                  (configs.firstWhereOrNull((e) => e.name == "High on Tag") as BoolConfigElement?)?.value ?? false,
              setter: (val) async {},
            ),
          ],
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

  @override
  Future<void> setInventorySettings(UhfInvSettings invSettings) async {
    String error = "";

    try {
      final protocolString = invSettings.toProtocolString();

      CmdExitCode exitCode = await sendCommand("AT+INVS=$protocolString", 1000, [
        ParserResponse("+INVS", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
      _invSettings = invSettings;
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }
  }

  @override
  Future<List<int>> getOutputPower() async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+PWR?", 1000, [
        ParserResponse("+PWR", (line) {
          final split = line.split(",");
          settings.antennaCount = split.length;
          settings.currentPower = split.map((e) => int.tryParse(e) ?? settings.minPower).toList();
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
  Future<void> setOutputPower(List<int> val) async {
    final onlyValidPowerValues = val.none((e) => e < settings.minPower || e > settings.maxPower);
    if (onlyValidPowerValues) {}

    if (val.length > settings.antennaCount) {
      throw ReaderException("Too many power values received. Must be at most ${settings.antennaCount} values");
    }

    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+PWR=${val.join(",")}", 1000, [
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

          settings.currentQ = int.tryParse(splitValues[0]);
          settings.currentMinQ = int.tryParse(splitValues[1]);
          settings.currentMaxQ = int.tryParse(splitValues[2]);
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
    if (!settings.possibleQValues.contains(val)) {
      throw ReaderException("Q value must be one of ${settings.possibleQValues}");
    } else if (!settings.possibleQValues.contains(min)) {
      throw ReaderException("Q min must be one of ${settings.possibleQValues}");
    } else if (!settings.possibleQValues.contains(max)) {
      throw ReaderException("Q max must be one of ${settings.possibleQValues}");
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
    settings.currentMinQ = min;
    settings.currentMaxQ = max;
  }

  @override
  Future<void> setQStart(int val) async {
    if (!settings.possibleQValues.contains(val)) {
      throw ReaderException("Q value must be one of ${settings.possibleQValues}");
    }
    final minValue = max(val - 2, settings.currentMinQ ?? settings.possibleQValues.first);
    final maxValue = min(val + 2, settings.currentMaxQ ?? settings.possibleQValues.last);

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
  Future<List<int>> getMuxAntenna() async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+MUX?", 1000, [
        ParserResponse("+MUX", (line) {
          final split = line.split(",");
          settings.currentMuxAntenna = split.map((e) => int.tryParse(e)).whereType<int>().toList();
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
  Future<void> setMuxAntenna(List<int> val) async {
    final onlyValidValues = val.every((e) => e < settings.antennaCount);
    if (onlyValidValues) {
      throw ReaderException("Mux value not in antenna range");
    }

    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+MUX=${val.join(",")}", 1000, [
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
    String error = "";
    final gen2Settings = (settings as UhfGen2ReaderSettings);

    try {
      CmdExitCode exitCode = await sendCommand("AT+INVS?", 1000, [
        ParserResponse("+INVS", (line) {
          List<bool> values = line.split(",").map((e) => (e == '1')).toList();
          if (values.length < 3) {
            error = line;
            return;
          }

          gen2Settings.invSettings = UhfInvSettings(
            values[0],
            values[1],
            values[2],
            values.length > 3 ? values[3] : false,
          );
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    if (gen2Settings.invSettings == null) {
      throw ReaderException("Failed to retrieve settings from line $error");
    }

    return gen2Settings.invSettings!;
  }

  Future<List<int>> getMultiplexer() async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand("AT+EMX?", 1000, [
        ParserResponse("+EMX", (line) {
          final split = line.split(",");
          (settings as UhfGen2ReaderSettings).currentMultiplexer =
              split.map((e) => int.tryParse(e)).whereType<int>().toList();
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return (settings as UhfGen2ReaderSettings).currentMultiplexer!;
  }

  Future<void> setMultiplexer(List<int> muxValues) async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand("AT+EMX=${muxValues.join(",")}", 1000, [
        ParserResponse("+EMX", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    (settings as UhfGen2ReaderSettings).currentMultiplexer = muxValues;
  }

  Future<int> getRfMode() async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand("AT+RFM?", 1000, [
        ParserResponse("+RFM", (line) {
          (settings as UhfGen2ReaderSettings).currentRfMode =
              int.tryParse(line) ?? (settings as UhfGen2ReaderSettings).currentRfMode;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return (settings as UhfGen2ReaderSettings).currentRfMode!;
  }

  Future<void> setRfMode(int value) async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand("AT+RFM=$value", 1000, [
        ParserResponse("+RFM", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    (settings as UhfGen2ReaderSettings).currentRfMode = value;
  }

  Future<String> getSession() async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand("AT+SES?", 1000, [
        ParserResponse("+SES", (line) {
          (settings as UhfGen2ReaderSettings).currentSession = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return (settings as UhfGen2ReaderSettings).currentSession!;
  }

  Future<void> setSession(String value) async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand("AT+SES=$value", 1000, [
        ParserResponse("+SES", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    (settings as UhfGen2ReaderSettings).currentSession = value;
  }

  Future<(bool, bool)> getImpinjSettings() async {
    final gen2Settings = (settings as UhfGen2ReaderSettings);
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand("AT+ICS?", 1000, [
        ParserResponse("ERROR", (line) {
          error = line;
          return;
        }),
        ParserResponse("+ICS", (line) {
          final split = line.split(",");
          if (split.length < 2) {
            return;
          }

          gen2Settings.fastId = split[0] == '1';
          gen2Settings.tagFocus = split[1] == '1';
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return (gen2Settings.fastId!, gen2Settings.tagFocus!);
  }

  Future<void> setImpinjSettings(bool fastIdVal, bool tagFocusVal) async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand(
        "AT+ICS=${fastIdVal.toProtocolString()},${tagFocusVal.toProtocolString()}",
        1000,
        [
          ParserResponse("+ICS", (line) {
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

    (settings as UhfGen2ReaderSettings).fastId = fastIdVal;
    (settings as UhfGen2ReaderSettings).tagFocus = tagFocusVal;
  }

  Future<(bool, int, int)> getHighOnTag() async {
    final gen2Settings = (settings as UhfGen2ReaderSettings);
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand("AT+HOT?", 1000, [
        ParserResponse("+HOT", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          if (line == "OFF") {
            gen2Settings.highOnTag = false;
            gen2Settings.highOnTagPin = 1;
            gen2Settings.highOnTagDuration = 200;
            return;
          }

          final split = line.split(",");
          if (split.length < 2) {
            return;
          }

          gen2Settings.highOnTag = true;
          gen2Settings.highOnTagPin = int.tryParse(split[0]) ?? 1;
          gen2Settings.highOnTagDuration = int.tryParse(split[1]) ?? 200;
        })
      ]);
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    return (gen2Settings.highOnTag!, gen2Settings.highOnTagPin!, gen2Settings.highOnTagDuration!);
  }

  Future<void> setHighOnTag(bool highOnTagVal, int highOnTagPinVal, int highOnTagDurationVal) async {
    final gen2Settings = (settings as UhfGen2ReaderSettings);
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand(
        highOnTagVal ? "AT+HOT=0" : "AT+HOT=${highOnTagPinVal},${highOnTagDurationVal}",
        1000,
        [
          ParserResponse("+HOT", (line) {
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

    gen2Settings.highOnTag = highOnTagVal;
    gen2Settings.highOnTagPin = highOnTagPinVal;
    gen2Settings.highOnTagDuration = highOnTagDurationVal;
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
  Future<void> killTag(String password, {String? mask}) async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand(
        "AT+KILL=$password${mask != null ? ",$mask" : ''}",
        1000,
        [
          ParserResponse("+KILL", (line) {
            final split = line.split(",");
            if (split.last != "OK") {
              error = split.last;
            }
          })
        ],
      );
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }
  }

  @override
  Future<void> lockMembank(String memBank, String password, {String? mask}) async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand(
        "AT+LCK=$memBank,$password${mask != null ? ",$mask" : ''}",
        1000,
        [
          ParserResponse("+LCK", (line) {
            final split = line.split(",");
            if (split.last != "OK") {
              error = split.last;
            }
          })
        ],
      );
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }
  }

  @override
  Future<void> lockMembankPermanently(String memBank, String password, {String? mask}) async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand(
        "AT+PLCK=$memBank,$password${mask != null ? ",$mask" : ''}",
        1000,
        [
          ParserResponse("+PLCK", (line) {
            final split = line.split(",");
            if (split.last != "OK") {
              error = split.last;
            }
          })
        ],
      );
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }
  }

  @override
  Future<void> unlockMembank(String memBank, String password, {String? mask}) async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand(
        "AT+ULCK=$memBank,$password${mask != null ? ",$mask" : ''}",
        1000,
        [
          ParserResponse("+ULCK", (line) {
            final split = line.split(",");
            if (split.last != "OK") {
              error = split.last;
            }
          })
        ],
      );
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
    }
  }

  /// Type should either be LCK or KILL
  @override
  Future<void> setPassword(String type, String oldPassword, String newPassword, {String? mask}) async {
    String error = "";
    try {
      CmdExitCode exitCode = await sendCommand(
        "AT+PWD=$type,$oldPassword,$newPassword${mask != null ? ",$mask" : ''}",
        1000,
        [
          ParserResponse("+PWD", (line) {
            final split = line.split(",");
            if (split.last != "OK") {
              error = split.last;
            }
          })
        ],
      );
      _handleExitCode(exitCode, error);
    } on ReaderException {
      rethrow;
    } catch (ex) {
      ReaderException(ex.toString());
    }

    if (error.isNotEmpty) {
      throw ReaderException(error);
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
  Future<void> loadDeviceSettings() async {
    if (settings is! UhfGen2ReaderSettings) {
      await super.loadDeviceSettings();
      return;
    }

    final gen2Settings = settings as UhfGen2ReaderSettings;

    if (gen2Settings.supportsOutputs) {
      try {
        await getOutputStates();
      } catch (ex, stack) {
        readerLogger.e("Failed to load device setting: output states", ex, stack);
      }
      try {
        await getMultiplexer();
      } catch (ex, stack) {
        readerLogger.e("Failed to load device setting: multiplexer", ex, stack);
      }
      try {
        await getHighOnTag();
      } catch (ex, stack) {
        readerLogger.e("Failed to load device setting: high on tag", ex, stack);
      }
    }

    if (gen2Settings.supportsInputs) {
      try {
        await getInputStates();
      } catch (ex, stack) {
        readerLogger.e("Failed to load device setting: input states", ex, stack);
      }
    }

    try {
      await getRfMode();
    } catch (ex, stack) {
      readerLogger.e("Failed to load device setting: rf mode", ex, stack);
    }

    try {
      await getSession();
    } catch (ex, stack) {
      readerLogger.e("Failed to load device setting: session", ex, stack);
    }

    try {
      await getImpinjSettings();
    } catch (ex, stack) {
      readerLogger.e("Failed to load device setting: impinj settings", ex, stack);
    }

    await super.loadDeviceSettings();
  }
}
