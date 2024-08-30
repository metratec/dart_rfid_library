import 'package:dart_rfid_library/src/parser/parser.dart';

class ParserAt extends Parser {
  ParserAt(super.commInterface, super.eol);

  /// Check if the received line is an event.
  ///
  /// Returns true if the line was an event, false otherwise.
  bool _handleEvents(String line) {
    for (ParserResponse event in events) {
      if (line.startsWith(event.prefix)) {
        event.dataCb(line);
        return true;
      }
    }

    return false;
  }

  /// Check if the received line terminated a running command.
  ///
  /// Returns true if a command was terminated, false otherwise.
  bool _handleTermination(String line) {
    if (line == "OK") {
      finishCommand(CmdExitCode.ok);
      return true;
    } else if (line == "ERROR") {
      finishCommand(CmdExitCode.error);
      return true;
    }

    return false;
  }

  @override
  void handleRxLine(String line) {
    // First check if received line is an event
    if (_handleEvents(line)) {
      return;
    }

    // Check if the line terminates a running command
    if (_handleTermination(line)) {
      return;
    }

    // Check for prefix matches on registered responses
    if (responseEntry == null) {
      return;
    }

    for (ParserResponse rsp in responseEntry!.responses) {
      if (line.startsWith(rsp.prefix)) {
        rsp.dataCb(line.replaceFirst("${rsp.prefix}: ", ''));
      }
    }
  }
}
