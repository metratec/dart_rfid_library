import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/at_reader.dart';
import 'package:reader_library/src/reader_exception.dart';

class AtReaderCommon extends AtReader {
  // Buffer for continuous inventory
  final Inventory _cinvBuffer = Inventory();

  AtReaderCommon(super.commInterface) {
    registerUrc(AtUrc("+CINV", _handleCinvUrc));
  }

  /// Start a continuous inventory.
  ///
  /// The inventories can be retrieved through `getInventoryStream()`.
  /// Can throw a ReaderTimeoutException or a ReaderException.
  Future<void> startContinuousInventory() async {
    CmdExitCode exitCode = await sendAtCommand("AT+CINV", 500, []);
    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("Starting CINV failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("Staring CINV failed with $exitCode");
    }
  }

  /// Stops a running continuous inventory.
  ///
  /// Can throw a ReaderTimeoutException or a ReaderException.
  Future<void> stopContinuousInventory() async {
    CmdExitCode exitCode = await sendAtCommand("AT+BINV", 500, []);
    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("Starting BINV failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("Staring BINV failed with $exitCode");
    }
  }

  /// Query the device information.
  ///
  /// Can throw a ReaderTimeoutException or a ReaderException.
  Future<AtReaderInfo> queryInfo() async {
    AtReaderInfo info =
        AtReaderInfo("undef", "undef", "undef", "undef", "undef");

    CmdExitCode exitCode = await sendAtCommand("ATI", 1000, [
      AtRsp("+FW", (data) {
        try {
          List<String> tokens = data.trim().split(" ");
          if (tokens.length != 2) {
            return;
          }
          info.fwName = tokens[0];
          info.fwRevision = tokens[1];
        } catch (e) {
          readerLogger.e("Parsing FW failed: $data");
        }
      }),
      AtRsp("+HW", (data) {
        try {
          List<String> tokens = data.trim().split(" ");
          if (tokens.length != 2) {
            return;
          }
          info.hwName = tokens[0];
          info.hwRevision = tokens[1];
        } catch (e) {
          readerLogger.e("Parsing HW failed: $data");
        }
      }),
      AtRsp("+SERIAL", (data) {
        if (data.isEmpty) {
          readerLogger.e("Failed to parse serial!");
          return;
        }

        info.serial = data;
      })
    ]);
    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("ATI failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("ATI failed with $exitCode");
    }

    return info;
  }

  /// Run a single inventory.
  Future<Inventory> inventory() async {
    Inventory inv = Inventory();

    CmdExitCode exitCode = await sendAtCommand("AT+INV", 2000, [
      AtRsp("+INV", (data) {
        if (data.contains("<")) {
          return;
        }

        inv.uids.add(data);
      })
    ]);

    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("INV failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("INV failed with $exitCode");
    }

    return inv;
  }

  void _handleCinvUrc(String data) {
    if (data.contains("ROUND FINISHED")) {
      Inventory inv = Inventory();
      inv.uids.addAll(_cinvBuffer.uids);
      invStreamCtrl.add(inv);
      _cinvBuffer.uids.clear();
      return;
    } else if (data.contains("<")) {
      return;
    }

    _cinvBuffer.uids.add(data.replaceFirst("+CINV: ", ""));
  }
}
