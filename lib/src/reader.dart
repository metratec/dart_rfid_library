import 'dart:async';

import 'package:logger/logger.dart';
import 'package:reader_library/src/parser/parser.dart';
import 'package:reader_library/src/utils/inventory_result.dart';
import 'package:reader_library/src/utils/reader_settings.dart';

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
}
