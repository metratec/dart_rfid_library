import 'dart:async';

import 'package:reader_library/reader_library.dart';

import 'dart:typed_data';

enum CmdExitCode {
  ok,
  error,
  timeout,
  canceled,
}

class AtReaderInfo {
  String fwName;
  String fwRevision;
  String hwName;
  String hwRevision;
  String serial;

  AtReaderInfo(
      this.fwName, this.fwRevision, this.hwName, this.hwRevision, this.serial);
}

class AtRsp {
  /// The response prefix to match
  String rsp;

  /// Callback function for received data
  void Function(String) dataCb;

  AtRsp(this.rsp, this.dataCb);
}

class AtCmd {
  /// Response to the command
  String cmd;

  /// Command timeout in milliseconds
  int timeout;

  /// Possible responses to the command
  List<AtRsp> responses;

  /// Completer for async notification
  Completer<CmdExitCode> completer = Completer();

  AtCmd(this.cmd, this.timeout, this.responses);
}

class AtUrc {
  /// The urc prefix to match
  String urc;

  /// Callback function for received data
  void Function(String)? dataCb;

  AtUrc(this.urc, this.dataCb);
}

abstract class AtReader extends BaseReader {
  /// Command queue
  final List<AtCmd> _cmdQueue = [];
  final List<AtUrc> _urcRegistry = [];
  Timer? _cmdTimer;

  AtReader(super.commInterface);

  /// Place a command in the command queue.
  ///
  /// This functions queues a [cmd] to send. The
  /// line ending is added by the send function.
  /// If a [timeout] != 0 is provided this function
  /// will return with a timeout return code if no
  /// response is received in the specified time in milliseconds.
  /// The [responses] list contains a list of all possible
  /// response prefixes to the command and data callbacks.
  Future<CmdExitCode> sendAtCommand(
      String cmd, int timeout, List<AtRsp> responses) {
    return _queueAtCmd(cmd, timeout, responses);
  }

  /// Register a [urc].
  void registerUrc(AtUrc urc) {
    _urcRegistry.add(urc);
  }

  /// This function handles received data.
  ///
  /// First it checks if any urc matches.
  /// After that it checks if the received
  /// data terminates a running command and
  /// then sends the next command. If the data does
  /// not terminate a running command it is checked
  /// if it matches any registered response for the command.
  /// If it does the callback is called. Otherwise the data
  /// is discarded.
  @override
  void handleRxData(String rx) {
    /// Check if a urc was received
    for (AtUrc urc in _urcRegistry) {
      if (rx.startsWith(urc.urc) == false) {
        continue;
      }

      if (urc.dataCb != null) {
        urc.dataCb!(rx);
      }
      readerLogger.i("Handled urc: $rx");
      return;
    }

    if (_cmdQueue.isEmpty) {
      readerLogger.w("Received data on empty queue: $rx");
      return;
    }

    AtCmd cmd = _cmdQueue.first;

    // Check for exit condition
    if (rx == "OK") {
      _finishCmd(CmdExitCode.ok);
      return;
    } else if (rx == "ERROR") {
      _finishCmd(CmdExitCode.error);
      return;
    }

    // Check for prefix match
    if (cmd.responses.isEmpty) {
      readerLogger.w("Received data but did not expect any: $rx");
      return;
    }

    for (AtRsp rsp in cmd.responses) {
      if (rx.startsWith(rsp.rsp)) {
        rsp.dataCb(rx.replaceFirst("${rsp.rsp}: ", ''));
      }
    }
  }

  /// Place a new command in the command queue.
  Future<CmdExitCode> _queueAtCmd(
      String cmd, int timeout, List<AtRsp> responses) {
    AtCmd atCmd = AtCmd(cmd, timeout, responses);

    bool first = _cmdQueue.isEmpty;

    _cmdQueue.add(atCmd);

    if (first) {
      try {
        _sendNextCmd();
      } on ReaderCommException catch (e) {
        readerLogger.e("Sending command failed: ${e.cause}");
      }
    }

    return atCmd.completer.future;
  }

  /// Send the next command from the command queue.
  void _sendNextCmd() {
    if (_cmdQueue.isEmpty) {
      readerLogger.i("Command queue depleted. Returning");
      return;
    }

    AtCmd atCmd = _cmdQueue.first;

    readerLogger.i("Sending command: ${atCmd.cmd}");

    if (write(Uint8List.fromList("${atCmd.cmd}$lineEnding".codeUnits)) ==
        false) {
      _cancelCmdQueue();
      throw ReaderCommException("write() failed!");
    }

    if (atCmd.timeout > 0) {
      _cmdTimer = Timer(Duration(milliseconds: atCmd.timeout),
          () => {_finishCmd(CmdExitCode.timeout)});
    }
  }

  /// Finishes the running command with [exitCode].
  void _finishCmd(CmdExitCode exitCode) {
    // Stop the timer
    _cmdTimer?.cancel();
    _cmdTimer = null;

    readerLogger.i("Finished command with: $exitCode");

    // Complete the command
    _cmdQueue.first.completer.complete(exitCode);
    _cmdQueue.removeAt(0);

    if (exitCode != CmdExitCode.ok) {
      readerLogger.w("Command finished with non-ok code: $exitCode");
      _cancelCmdQueue();
      return;
    }

    // Start the next command
    try {
      _sendNextCmd();
    } on ReaderCommException catch (e) {
      readerLogger.e("Sending command failed: ${e.cause}");
    }
  }

  /// Cancel all pending commands in the command queue.
  void _cancelCmdQueue() {
    for (AtCmd cmd in _cmdQueue) {
      cmd.completer.complete(CmdExitCode.canceled);
    }

    _cmdTimer?.cancel();
    _cmdTimer = null;
    _cmdQueue.clear();
  }
}
