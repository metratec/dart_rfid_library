import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/at_reader.dart';
import 'package:reader_library/src/reader_exception.dart';

class AtReaderCommon extends AtReader {
  // Buffer for continuous inventory
  final Inventory _cinvBuffer = Inventory();

  AtReaderCommon(super.commInterface) {
    registerUrc(AtUrc("+CINV", _handleCinvUrc));
  }

  Future<void> startContinuousInventory() async {
    CmdExitCode exitCode = await sendAtCommand("AT+CINV", null, 500, null);
    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("Starting CINV failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("Staring CINV failed with $exitCode");
    }
  }

  Future<void> stopContinuousInventory() async {
    CmdExitCode exitCode = await sendAtCommand("AT+BINV", null, 500, null);
    if (exitCode == CmdExitCode.timeout) {
      throw ReaderTimeoutException("Starting BINV failed due to timeout");
    } else if (exitCode != CmdExitCode.ok) {
      throw ReaderException("Staring BINV failed with $exitCode");
    }
  }

  Future<Inventory> inventory() async {
    Inventory inv = Inventory();

    CmdExitCode exitCode = await sendAtCommand("AT+INV", "+INV", 2000, (data) {
      if (data.contains("<")) {
        return;
      }

      inv.uids.add(data);
    });

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
