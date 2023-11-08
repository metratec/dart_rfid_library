import 'dart:async';

import 'package:dart_rfid_utils/dart_rfid_utils.dart';
import 'package:logger/logger.dart';
import 'package:metratec_device/metratec_device.dart';
import 'package:reader_library/src/parser/parser.dart';
import 'package:reader_library/src/reader_hf/ascii-proto/deskid_iso.dart';
import 'package:reader_library/src/reader_hf/ascii-proto/dwarf15.dart';
import 'package:reader_library/src/reader_hf/ascii-proto/quasar_mx.dart';
import 'package:reader_library/src/reader_hf/at-proto/deskid_nfc.dart';
import 'package:reader_library/src/reader_hf/at-proto/dwarf_nfc.dart';
import 'package:reader_library/src/reader_hf/at-proto/qr_nfc.dart';
import 'package:reader_library/src/reader_hf/reader_hf_ascii.dart';
import 'package:reader_library/src/reader_hf/reader_hf_at.dart';
import 'package:reader_library/src/reader_library_base.dart';
import 'package:reader_library/src/reader_uhf/ascii-proto/deskid_uhf.dart';
import 'package:reader_library/src/reader_uhf/ascii-proto/dwarf_g2.dart';
import 'package:reader_library/src/reader_uhf/ascii-proto/pulsar_mx.dart';
import 'package:reader_library/src/reader_uhf/at-proto/deskid_uhf_v2_e.dart';
import 'package:reader_library/src/reader_uhf/at-proto/deskid_uhf_v2_f.dart';
import 'package:reader_library/src/reader_uhf/at-proto/dwarf_g2_mini.dart';
import 'package:reader_library/src/reader_uhf/at-proto/dwarf_g2_v2.dart';
import 'package:reader_library/src/reader_uhf/at-proto/pulsar_fl.dart';
import 'package:reader_library/src/reader_uhf/at-proto/pulsar_lr.dart';
import 'package:reader_library/src/reader_uhf/at-proto/qrg2.dart';
import 'package:reader_library/src/reader_uhf/at-proto/qrg2_e.dart';
import 'package:reader_library/src/reader_uhf/at-proto/qrg2_f.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_ascii.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_at.dart';

abstract class Reader {
  /// A list of all supported devices.
  static const List<String> supportedDevices = [
    "PULSAR_LR",
    "PULSAR_FL",
    "DWARFG2_V2",
    "DWARFG2-MINI_V2",
    "QRG2",
    "QRG2_E",
    "QRG2_F",
    "DESKID_UHF_V2_E",
    "DESKID_UHF_V2_F",
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
  static const List<String> _uhfASCIIDevices = [
    "PULSARMX",
    "DESKID_UHF",
    "DWARFG2",
  ];

  /// A list of all devices that are UHF devices with AT protocol
  static const List<String> _uhfATDevices = [
    "PULSAR_LR",
    "PULSAR_FL",
    "DWARFG2_V2",
    "DWARFG2-MINI_V2",
    "QRG2",
    "QRG2_E",
    "QRG2_F",
    "DESKID_UHF_V2_E",
    "DESKID_UHF_V2_F",
  ];

  /// A list of all devices that are old HF devices
  static const List<String> _hfASCIIDevices = [
    "DESKID_ISO",
    "QUASAR_MX",
    "DWARF15",
  ];

  /// A list of all devices that are HF devices with AT protocol
  static const List<String> _hfATDevices = [
    "DESKID_NFC",
    "QR_NFC",
    "DWARF_NFC",
  ];

  final Parser _parser;

  final RegExp hexRegEx = RegExp(r"^[a-fA-F0-9]+$");

  /// Logger
  final Logger _readerLogger = Logger();

  ReaderSettings settings;

  /// Stream for continuous inventory.
  StreamController<List<InventoryResult>> cinvStreamCtrl = StreamController.broadcast();

  Reader(this._parser, this.settings);

  Logger get readerLogger => _readerLogger;

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

  /// Get the inventory stream for continuous inventories.
  Stream<List<InventoryResult>> getInvStream() {
    return cinvStreamCtrl.stream;
  }

  /// Perform a single inventory.
  ///
  /// Returns a list if discovered tags.
  /// The output format depends on the settings given to setInventoryFormat()
  /// !: Will throw [ReaderTimeoutException] on timeout.
  /// !: Will throw [ReaderException] on other reader related error.
  Future<List<InventoryResult>> inventory();

  Future<void> loadDeviceSettings();

  /// Register an [event].
  void registerEvent(ParserResponse event) {
    _parser.registerEvent(event);
  }

  /// Send a command.
  ///
  /// See Parser.sendCommand()
  Future<CmdExitCode> sendCommand(String cmd, int timeout, List<ParserResponse> responses) {
    return _parser.sendCommand(cmd, timeout, responses);
  }

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

  static Reader? getReaderImplementationByName({required String hardwareName, required CommInterface commInterface}) {
    hardwareName = hardwareName.toUpperCase();
    final specificReader = switch (hardwareName) {
      "PULSARMX" => ReaderPulsarMx(commInterface),
      "DESKID_UHF" => ReaderDeskIdUhf(commInterface),
      "DWARFG2" => ReaderDwarfG2(commInterface),
      "PULSAR_LR" => ReaderPulsarLR(commInterface),
      "PULSAR_FL" => ReaderPulsarFL(commInterface),
      "DWARFG2_V2" => ReaderDwarfG2V2(commInterface),
      "DWARFG2-MINI_V2" => ReaderDwarfG2MiniV2(commInterface),
      "QRG2" => ReaderQRG2(commInterface),
      "QRG2_E" => ReaderQRG2E(commInterface),
      "QRG2_F" => ReaderQRG2F(commInterface),
      "DESKID_UHF_V2_E" => ReaderDeskIdUhfV2E(commInterface),
      "DESKID_UHF_V2_F" => ReaderDeskIdUhfV2F(commInterface),
      "DESKID_ISO" => ReaderDeskIdIso(commInterface),
      "QUASAR_MX" => ReaderQuasarMx(commInterface),
      "DWARF15" => ReaderDwarf15(commInterface),
      "DESKID_NFC" => ReaderDeskIdNfc(commInterface),
      "QR_NFC" => ReaderQrNfc(commInterface),
      "DWARF_NFC" => ReaderDwarfNfc(commInterface),
      _ => null,
    };

    if (specificReader != null) {
      return specificReader;
    }

    if (_uhfATDevices.contains(hardwareName)) {
      return UhfReaderAt(commInterface, UhfAtReaderSettings());
    } else if (_uhfASCIIDevices.contains(hardwareName)) {
      return UhfReaderAscii(commInterface, UhfAsciiReaderSettings());
    } else if (_hfATDevices.contains(hardwareName)) {
      return HfReaderAt(commInterface, HfAtReaderSettings());
    } else if (_hfASCIIDevices.contains(hardwareName)) {
      throw HfReaderAscii(commInterface, HfAsciiReaderSettings());
    } else {
      return null;
    }
  }
}
