import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/at_reader.dart';
import 'package:reader_library/src/reader_exception.dart';

enum DeskIdNfcMode {
  iso14a,
  iso15,
  auto,
}

enum MfcKeyType { A, B }

class DeskIdNfc extends AtReaderCommon {
  DeskIdNfc(super.commInterface);

  /// Set the operation mode of the deskId
  Future<void> setMode(DeskIdNfcMode mode) async {
    String modeStr = "";

    switch (mode) {
      case DeskIdNfcMode.iso14a:
        modeStr = "ISO14A";
        break;
      case DeskIdNfcMode.iso15:
        modeStr = "ISO15";
        break;
      case DeskIdNfcMode.auto:
        modeStr = "AUTO";
        break;
    }

    String errString = "";

    CmdExitCode exitCode = await sendAtCommand("AT+MOD=$modeStr", 500, [
      AtRsp("+MOD", (data) {
        errString = data;
      })
    ]);
    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("MOD failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("MOD failed with $exitCode $errString");
    }
  }

  /// Select a tag by [uid].
  Future<void> selectTag(String uid) async {
    String errString = "";
    CmdExitCode exitCode = await sendAtCommand("AT+SEL=$uid", 500, [
      AtRsp("+SEL", (data) {
        errString = data;
      })
    ]);
    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("SEL failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("SEL failed with $exitCode $errString");
    }
  }

  /// Authenticate with a mifare classic tag.
  ///
  /// The given [block] is authenticated with [key] of [keyType];
  Future<void> mfcAuth(int block, String key, MfcKeyType keyType) async {
    String typeStr = "";

    switch (keyType) {
      case MfcKeyType.A:
        typeStr = "A";
        break;
      case MfcKeyType.B:
        typeStr = "B";
        break;
    }

    String errString = "";
    CmdExitCode exitCode =
        await sendAtCommand("AT+AUT=$block,$key,$typeStr", 500, [
      AtRsp("+AUT", (data) {
        errString = data;
      })
    ]);
    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("AUT failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("AUT failed with $exitCode $errString");
    }
  }

  /// Write a single block of data.
  Future<void> writeBlock(int block, String data) async {
    String errString = "";
    CmdExitCode exitCode = await sendAtCommand("AT+WRT=$block,$data", 1000, [
      AtRsp("+WRT", (data) {
        errString = data;
      })
    ]);
    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("WRT failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("WRT failed with $exitCode $errString");
    }
  }

  /// Read a single block of data
  Future<String> readBlock(int block) async {
    String rcvData = "";
    String errString = "";
    CmdExitCode exitCode = await sendAtCommand("AT+READ=$block", 1000, [
      AtRsp("+READ", (data) {
        if (data.contains("<")) {
          errString = data;
          return;
        }
        rcvData = data;
      })
    ]);

    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("READ failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("READ failed with $exitCode $errString");
    }

    return rcvData;
  }
}
