import 'dart:async';

import 'package:reader_library/reader_library.dart';

class ReaderDevice extends GenericDevice {
  ReaderDevice(super.commInterface);

  BaseReader? _reader;

  Stream<Inventory>? getInventoryStream() => _reader?.getInventoryStream();

  /// Use [inventoryStream] instead to gain access to parsed rx data
  @override
  Future<bool> connect({
    bool rawStream = false,
    void Function(dynamic)? onRxData,
    void Function(MetraTecEvent)? onMetraTecEvent,
    void Function(Object?, StackTrace)? onError,
  }) async {
    return super.connect(
      onRxData: onRxData,
      onMetraTecEvent: onMetraTecEvent,
      rawStream: false,
      onError: onError,
    );
  }

  @override
  Future<bool> identify({bool isFirmwareInfoRequired = true, bool isHardwareInfoRequired = true}) async {
    final identifySuccessful = await super.identify(
      isFirmwareInfoRequired: isFirmwareInfoRequired,
      isHardwareInfoRequired: isHardwareInfoRequired,
    );

    if (identifySuccessful) {
      switch (deviceInfo.hardwareName) {
        case "DeskID_NFC":
          _reader = DeskIdNfc(commInterface);
          onRxData = (data) => _reader?.handleRxData(data as String);
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
