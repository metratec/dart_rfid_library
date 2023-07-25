import 'dart:async';

import 'package:logger/logger.dart';
import 'package:metratec_device/metratec_device.dart';
import 'package:reader_library/src/parser/parser.dart';
import 'package:reader_library/src/reader_hf/reader_hf_gen1.dart';
import 'package:reader_library/src/reader_hf/reader_hf_gen2.dart';
import 'package:reader_library/src/reader_library_base.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_gen1.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_gen2.dart';

abstract class Reader {
  final Parser _parser;
  final RegExp hexRegEx = RegExp(r"^[a-fA-F0-9]+$");

  /// Logger
  final Logger _readerLogger = Logger();
  Logger get readerLogger => _readerLogger;

  Reader(this._parser, this.settings);

  ReaderSettings settings;

  /// Stream for continuous inventory.
  StreamController<List<InventoryResult>> cinvStreamCtrl = StreamController.broadcast();

  /// Connect to the reader.
  ///
  /// This function will initialize the underlying
  /// communication interface and connect to the reader.
  /// This function will throw a ReaderCommException if
  /// the reader is already connected.
  Future<bool> connect({required void Function(Object?, StackTrace) onError}) async {
    return _parser.connect(onError: onError);
  }

  /// Disconnect the reader.
  ///
  /// This function will throw a ReaderCommException if
  /// the reader is not connected.
  Future<void> disconnect() async {
    return _parser.disconnect();
  }

  /// Send a command.
  ///
  /// See Parser.sendCommand()
  Future<CmdExitCode> sendCommand(String cmd, int timeout, List<ParserResponse> responses) {
    return _parser.sendCommand(cmd, timeout, responses);
  }

  /// Register an [event].
  void registerEvent(ParserResponse event) {
    _parser.registerEvent(event);
  }

  /// Perform a single inventory.
  ///
  /// Returns a list if discovered tags.
  /// The output format depends on the settings given to setInventoryFormat()
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<List<InventoryResult>> inventory();

  /// Starts a continuous inventory.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> startContinuousInventory();

  /// Stops a running continuous inventory.
  ///
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<void> stopContinuousInventory();

  /// Get the inventory stream for continuous inventories.
  Stream<List<InventoryResult>> getInvStream() {
    return cinvStreamCtrl.stream;
  }

  Future<void> loadDeviceSettings();

  /// A list of all supported devices.
  static const List<String> supportedDevices = [
    "PULSAR_LR",
    "QRG2",
    "DESKID_UHF_V2_E",
    "PULSARMX",
    "DESKID_UHF",
    "DWARFG2",
    "DESKID_NFC",
    "QR_NFC",
    "DWARF_NFC",
    "DESKID_ISO",
    "QUASAR_MX",
    "DWARF15",
  ];

  /// A list of all devices that are old UHF devices
  static const List<String> _uhfGen1Devices = [
    "PULSARMX",
    "DESKID_UHF",
    "DWARFG2",
  ];

  /// A list of all devices that are UHF devices with AT protocol
  static const List<String> _uhfGen2Devices = [
    "PULSAR_LR",
    "QRG2",
    "DESKID_UHF_V2_E",
  ];

  /// A list of all devices that are old HF devices
  static const List<String> _hfGen1Devices = [
    "DESKID_ISO",
    "QUASAR_MX",
    "DWARF15",
  ];

  /// A list of all devices that are HF devices with AT protocol
  static const List<String> _hfGen2Devices = [
    "DESKID_NFC",
    "QR_NFC",
    "DWARF_NFC",
  ];

  static Reader? getReaderImplementationByName({required String hardwareName, required CommInterface commInterface}) {
    hardwareName = hardwareName.toUpperCase();
    final specificReader = switch (hardwareName) {
      "PULSAR_LR" => ReaderPulsarLR(commInterface),
      _ => null,
    };

    if (specificReader != null) {
      return specificReader;
    }

    if (_uhfGen2Devices.contains(hardwareName)) {
      return UhfReaderGen2(commInterface, UhfGen2ReaderSettings());
    } else if (_uhfGen1Devices.contains(hardwareName)) {
      return UhfReaderGen1(commInterface, UhfGen1ReaderSettings());
    } else if (_hfGen2Devices.contains(hardwareName)) {
      return HfReaderGen2(commInterface, HfGen2ReaderSettings());
    } else if (_hfGen1Devices.contains(hardwareName)) {
      throw HfReaderGen1(commInterface, HfGen1ReaderSettings());
    } else {
      return null;
    }
  }
}
