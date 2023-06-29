import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:reader_library/reader_library.dart';
import 'package:logger/logger.dart';

enum ReaderState { undef, idle, busy, error }

class Inventory {
  /// List of all received UIDs.
  List<String> uids = [];
}

abstract class BaseReader {
  /// Interface for low level communication
  final CommInterface _commInterface;
  StreamSubscription? _rxSub;

  /// Current state
  ReaderState _state = ReaderState.undef;
  String _stateDesc = "undefined";

  /// Callback function definitions
  void Function(ReaderState, String)? _statusCb;

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

  /// Set the status callback.
  ///
  /// The status [cb] will be called once the reader state changes.
  void setStatusCb({Function(ReaderState, String)? cb}) {
    _statusCb = cb;
  }

  /// Get the current reader state.
  ReaderState getState() {
    return _state;
  }

  /// Get the current state description.
  String getStateDescription() {
    return _stateDesc;
  }

  /// Set the state and description of the reader.
  ///
  /// Set a reader [state] and a [txt] description.
  /// This function is called by the reader classes
  /// and should never be called from user code.
  void setStateAndDesc(ReaderState state, String txt) {
    _state = state;
    _stateDesc = txt;

    if (_statusCb != null) {
      _statusCb!(_state, _stateDesc);
    }
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
}
