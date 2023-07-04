import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:metratec_device/metratec_device.dart';

enum CmdExitCode {
  ok,
  error,
  timeout,
  canceled,
}

class ParserResponse {
  /// Prefix the response has to contain.
  /// Set to empty string for no prefix.
  String prefix;

  void Function(String) dataCb;

  ParserResponse(this.prefix, this.dataCb);
}

class ParserResponseEntry {
  /// List of possible responses to the command.
  List<ParserResponse> responses;

  /// Completer for async notifications
  Completer<CmdExitCode> completer = Completer();

  ParserResponseEntry(this.responses);
}

abstract class Parser {
  /// Low level communication interface
  final CommInterface _commInterface;
  StreamSubscription? _rxSub;

  /// Running command. If null the parser is idle
  /// and can send the next command
  ParserResponseEntry? responseEntry;

  /// Timer for command timeout
  Timer? _cmdTimer;

  /// List of registered events
  final List<ParserResponse> events = [];

  /// End of Line character(s)
  final String _eol;

  Parser(this._commInterface, this._eol);

  /// Connect the low level communication interface.
  ///
  /// !: Will throw a [Exception] if already connected.
  Future<bool> connect() async {
    if (_commInterface.isConnected()) {
      throw Exception("Already connected");
    }

    if (!await _commInterface.connect()) {
      return false;
    }

    _rxSub = _commInterface.rxStream
        .map((e) => String.fromCharCodes(e))
        .transform(const LineSplitter())
        .listen(handleRxLine);

    return true;
  }

  /// Disconnect from the communication interface.
  Future<void> disconnect() async {
    await _rxSub?.cancel();
    await _commInterface.disconnect();
    _rxSub = null;
  }

  /// Send a [cmd] to the reader.
  ///
  /// Use the [responses] list to retrieve answers to the command.
  /// The [timeout] specifies the command timeout in milliseconds.
  /// !: Throws an [Exception] if a command is already running.
  /// !: Throws an [Exception] if sending the command fails.
  Future<CmdExitCode> sendCommand(
      String cmd, int timeout, List<ParserResponse> responses) async {
    if (responseEntry != null) {
      throw Exception("Another command is already running!");
    }

    responseEntry = ParserResponseEntry(responses);

    if (_commInterface.write(Uint8List.fromList("$cmd$_eol".codeUnits)) ==
        false) {
      responseEntry = null;
      throw Exception("Sending command failed!");
    }

    if (timeout > 0) {
      _cmdTimer = Timer(Duration(milliseconds: timeout), () {
        finishCommand(CmdExitCode.timeout);
      });
    }

    return responseEntry!.completer.future;
  }

  /// Called to terminate running command.
  ///
  /// The [code] will be returned to the waiting caller.
  /// Never call this function directly.
  void finishCommand(CmdExitCode code) {
    _cmdTimer?.cancel();
    _cmdTimer = null;

    responseEntry?.completer.complete(code);
    responseEntry = null;
  }

  /// Register a unsolicited [event] in the parser.
  void registerEvent(ParserResponse event) {
    events.add(event);
  }

  /// Handles received line from the comm interface.
  /// Never call directly.
  void handleRxLine(String line);
}
