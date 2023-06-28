import 'package:reader_library/reader_library.dart';
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

    CmdExitCode exitCode = await sendAtCommand("AT+MOD=$modeStr", 500, []);
    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("MOD failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("MOD failed with $exitCode");
    }
  }

  /// Select a tag by [uid].
  Future<void> selectTag(String uid) async {
    CmdExitCode exitCode = await sendAtCommand("AT+SEL=$uid", 500, []);
    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("SEL failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("SEL failed with $exitCode");
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
    CmdExitCode exitCode =
        await sendAtCommand("AT+AUT=$block,$key,$typeStr", 500, []);
    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("AUT failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("AUT failed with $exitCode");
    }
  }

  Future<void> writeBlock(int block, String data) async {
    CmdExitCode exitCode = await sendAtCommand("AT+WRT=$block,$data", 1000, []);
    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("WRT failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("WRT failed with $exitCode");
    }
  }
}
