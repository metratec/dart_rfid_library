import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:reader_library/reader_library.dart';

class Inventory {
  /// List of all received UIDs.
  List<String> uids = [];
}

abstract class BaseReader {
  /// Interface for low level communication
  final CommInterface _commInterface;
  StreamSubscription? _rxSub;

  /// Logger
  final Logger _readerLogger = Logger();
  Logger get readerLogger => _readerLogger;

  String lineEnding = "\r";

  final StreamController<Inventory> invStreamCtrl =
      StreamController.broadcast();

  BaseReader(this._commInterface);

  /// Connect to the reader.
  ///
  /// This function will initialize the underlying
  /// communication interface and connect to the reader.
  /// This function will throw a ReaderCommException if
  /// the reader is already connected.
  Future<bool> connect() async {
    if (_rxSub != null) {
      throw ReaderCommException("Device already connected!");
    }

    if (!await _commInterface.connect()) {
      _readerLogger.e("Failed to connect to comm interface!");
      return false;
    }

    _rxSub = _commInterface.rxStream
        .map((e) => String.fromCharCodes(e))
        .transform(const LineSplitter())
        .listen(handleRxData);

    return true;
  }

  /// Disconnect the reader.
  ///
  /// This function will throw a ReaderCommException if
  /// the reader is not connected.
  Future<void> disconnect() async {
    if (_rxSub == null) {
      throw ReaderCommException("No device connected!");
    }

    await _rxSub?.cancel();
    await _commInterface.disconnect();
    _rxSub = null;
  }

  /// Write [data] directly to the comm interface.
  ///
  /// Never call this function directly from user code.
  /// It is used by the protocol abstractions.
  bool write(Uint8List data) {
    return _commInterface.write(data);
  }

  /// Retrieve a stream for continuous inventories.
  Stream<Inventory> getInventoryStream() {
    return invStreamCtrl.stream;
  }

  /// Abstract method that is implemented by
  /// protocol abstractions. Never call from
  /// user code!
  void handleRxData(String rx);

  /// Run a single inventory.
  ///
  /// !: Throws an [UnsupportedError] if the reader does not support [inventory]
  Future<Inventory> inventory() => throw UnsupportedError("Reader does not support inventory");

  /// Start a continuous inventory.
  ///
  /// The inventories can be retrieved through [getInventoryStream].
  ///
  /// !: Can throw a [ReaderTimeoutException] or a [ReaderException].
  ///
  /// !: Throws an [UnsupportedError] if the reader does not support [startContinuousInventory]
  Future<void> startContinuousInventory() => throw UnsupportedError("Reader does not support startContinuousInventory");

  /// Stops a running continuous inventory.
  ///
  /// The inventories can be retrieved through [getInventoryStream].
  ///
  /// !: Can throw a [ReaderTimeoutException] or a [ReaderException].
  ///
  /// !: Throws an [UnsupportedError] if the reader does not support [startContinuousInventory]
  Future<void> stopContinuousInventory() => throw UnsupportedError("Reader does not support stopContinuousInventory");
}
