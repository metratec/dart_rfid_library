import 'dart:async';

import 'package:reader_library/reader_library.dart';

class ReaderDevice extends GenericDevice {
  ReaderDevice(super.commInterface);

  BaseReader? _reader;

  Stream<Inventory>? getInventoryStream() => _reader?.getInventoryStream();

  /// [onRxData] and [onMetraTecEvent] are ignored as the data is handled internally
  ///
  /// Use [inventoryStream] instead to gain access to parsed rx data
  @override
  Future<bool> connect({
    bool rawStream = false,
    void Function(dynamic)? onRxData,
    void Function(MetraTecEvent)? onMetraTecEvent,
    void Function(Object?, StackTrace)? onError,
  }) async {
    return super.connect(
      rawStream: false,
      onError: onError,
    );
  }

  @override
  Future<bool> identify({bool isFirmwareInfoRequired = true, bool isHardwareInfoRequired = true}) async {
    var value = await super.identify(
      isFirmwareInfoRequired: isFirmwareInfoRequired,
      isHardwareInfoRequired: isHardwareInfoRequired,
    );

    if (value) {
      switch (deviceInfo.hardwareName) {
        case "DeskID_NFC":
          _reader = DeskIdNfc(commInterface);
          onRxData = (data) => _reader?.handleRxData(data as String);
      }
    }

    return value;
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
      throw ArgumentError.notNull("Reader must be connected before calling inventory");
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
      throw ArgumentError.notNull("Reader must be connected before calling startContInventory");
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
      throw ArgumentError.notNull("Reader must be connected before calling stopContInventory");
    }

    _reader!.stopContinuousInventory();
  }
}
