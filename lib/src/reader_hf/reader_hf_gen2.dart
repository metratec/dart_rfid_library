import 'dart:typed_data';

import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/parser/parser.dart';
import 'package:reader_library/src/parser/parser_at.dart';
import 'package:reader_library/src/reader_exception.dart';
import 'package:reader_library/src/utils/convert.dart';

class HfReaderGen2 extends HfReader {
  final List<HfTag> _inventory = [];

  HfReaderGen2(CommInterface commInterface) : super(ParserAt(commInterface, "\r")) {
    registerEvent(ParserResponse("+CINV", _handleCinvUrc));
    registerEvent(ParserResponse("+HBT", _handleHbtUrc));
  }

  void _handleCinvUrc(String line) {
    if (line.contains("ROUND FINISHED")) {
      List<HfTag> inv = [];
      inv.addAll(_inventory);
      cinvStreamCtrl.add(inv);
      _inventory.clear();
      return;
    } else if (line.contains("<")) {
      return;
    }

    String uid = line.split(': ').last;
    _inventory.add(HfTag(uid, "Unknown"));
  }

  void _handleHbtUrc(String line) {
    heartbeat.feed();
  }

  void _handleExitCode(CmdExitCode code, String error) {
    if (code == CmdExitCode.timeout) {
      throw ReaderTimeoutException("Command timed out!");
    } else if (code != CmdExitCode.ok) {
      throw ReaderException("Command failed with: $error");
    }
  }

  @override
  Future<List<HfTag>> inventory() async {
    List<HfTag> inv = [];
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+INV", 2000, [
        ParserResponse("+INV", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          inv.add(HfTag(line, "Unknown"));
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    return inv;
  }

  @override
  Future<void> mfcAuth(int block, Uint8List key, MfcKeyType keyType) async {
    if (key.length != 6) {
      throw ReaderException("Wrong key size for MFC");
    }

    String typeString = keyType.toString().split('.').last;
    String keyString = uint8ListToString(key);
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+AUT=$block,$keyString,$typeString", 1000, [
        ParserResponse("+AUT", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> write(Uint8List data, int block) async {
    String error = "";
    String dataString = uint8ListToString(data);

    try {
      CmdExitCode exitCode = await sendCommand("AT+WRT=$block,$dataString", 2000, [
        ParserResponse("+WRT", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<Uint8List> read(int block) async {
    String data = "";
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+READ=$block", 2000, [
        ParserResponse("+READ", (line) {
          if (line.contains("<")) {
            error = line;
            return;
          }

          data = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }

    return stringToUint8List(data);
  }

  @override
  Future<void> selectTag(HfTag tag) async {
    String error = "";

    try {
      CmdExitCode exitCode = await sendCommand("AT+SEL=${tag.uid}", 1000, [
        ParserResponse("+SEL", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> setMode(HfReaderMode mode) async {
    String error = "";
    String modeStr = mode.toString().split('.').last.toUpperCase();

    try {
      CmdExitCode exitCode = await sendCommand("AT+MOD=$modeStr", 1000, [
        ParserResponse("+MOD", (line) {
          error = line;
        })
      ]);
      _handleExitCode(exitCode, error);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> startHeartBeat(int seconds, Function onHbt, Function onTimeout) async {
    heartbeat.stop();

    try {
      CmdExitCode exitCode = await sendCommand("AT+HBT=$seconds", 1000, []);
      _handleExitCode(exitCode, "");

      heartbeat.start(seconds * 1000 + 2000, onHbt, onTimeout);
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> stopHeartBeat() async {
    heartbeat.stop();
    try {
      CmdExitCode exitCode = await sendCommand("AT+HBT=0", 1000, []);
      _handleExitCode(exitCode, "");
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> startContinuousInventory() async {
    try {
      CmdExitCode exitCode = await sendCommand("AT+CINV", 1000, []);
      _handleExitCode(exitCode, "");
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }

  @override
  Future<void> stopContinuousInventory() async {
    try {
      CmdExitCode exitCode = await sendCommand("AT+BINV", 3000, []);
      _handleExitCode(exitCode, "");
    } catch (e) {
      throw ReaderException(e.toString());
    }
  }
}
