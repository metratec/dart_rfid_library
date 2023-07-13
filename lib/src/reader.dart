import 'package:logger/logger.dart';
import 'package:reader_library/src/parser/parser.dart';

abstract class Reader {
  final Parser _parser;

  /// Logger
  final Logger _readerLogger = Logger();
  Logger get readerLogger => _readerLogger;

  Reader(this._parser);

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
}
