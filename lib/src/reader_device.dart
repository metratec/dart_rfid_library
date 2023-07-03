import 'dart:async';

import 'package:reader_library/reader_library.dart';

class ReaderDevice extends GenericDevice {
  ReaderDevice(super.commInterface);

  BaseReader? _reader;

  Stream<Inventory>? getInventoryStream() => _reader?.getInventoryStream();

  @override
  Future<bool> identify({bool isFirmwareInfoRequired = true, bool isHardwareInfoRequired = true}) async {
    final identifySuccessful = await super.identify(
      isFirmwareInfoRequired: isFirmwareInfoRequired,
      isHardwareInfoRequired: isHardwareInfoRequired,
    );

    if (identifySuccessful) {
      switch (deviceInfo.hardwareName?.toUpperCase()) {
        case "DESKID_NFC":
          _reader = DeskIdNfc(commInterface);
          onRxData = (data) => _reader?.handleRxData(data as String);
          break;
        case "QR_NFC":
          _reader = AtReaderCommon(commInterface);
          onRxData = (data) => _reader?.handleRxData(data as String);
          break;
        case "DWARF_NFC":
          _reader = AtReaderCommon(commInterface);
          onRxData = (data) => _reader?.handleRxData(data as String);
          break;
        case "PULSARLR":
          _reader = AtReaderCommon(commInterface);
          onRxData = (data) => _reader?.handleRxData(data as String);
          break;
        case "QRG2":
          _reader = AtReaderCommon(commInterface);
          onRxData = (data) => _reader?.handleRxData(data as String);
          break;
        case "DESKID_UHF_V2":
          _reader = AtReaderCommon(commInterface);
          onRxData = (data) => _reader?.handleRxData(data as String);
          break;
      }
    }

    return identifySuccessful;
  }

  /// Run a single inventory.
  ///
  /// !: Can throw a [ReaderTimeoutException] or a [ReaderException].
  ///
  /// !: May throw an [UnsupportedError] if the current reader does not support inventory
  ///
  /// !: Throws an [ArgumentError.notNull] if called before the reader has been identified
  Future<Inventory> inventory() async {
    if (_reader == null) {
      throw ArgumentError.notNull("_reader");
    }

    return _reader!.inventory();
  }

  /// Start a continuous inventory
  ///
  /// The inventories can be retrieved through [getInventoryStream].
  ///
  /// !: Can throw a [ReaderTimeoutException] or a [ReaderException].
  ///
  /// !: May throw an [UnsupportedError] if the current reader does not support cont. inventory
  ///
  /// !: Throws an [ArgumentError.notNull] if called before the reader has been identified
  Future<void> startContInventory() async {
    if (_reader == null) {
      throw ArgumentError.notNull("_reader");
    }

    _reader!.startContinuousInventory();
  }

  /// Stops a running continuous inventory.
  ///
  /// The inventories can be retrieved through [getInventoryStream].
  ///
  /// !: Can throw a [ReaderTimeoutException] or a [ReaderException].
  ///
  /// !: May throw an [UnsupportedError] if the current reader does not support cont. inventory
  ///
  /// !: Throws an [ArgumentError.notNull] if called before the reader has been identified
  Future<void> stopContInventory() async {
    if (_reader == null) {
      throw ArgumentError.notNull("_reader");
    }

    _reader!.stopContinuousInventory();
  }
}
