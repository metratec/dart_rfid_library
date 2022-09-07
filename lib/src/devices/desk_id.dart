import 'package:metratec_device/metratec_device.dart';
import 'package:uhf_devices/src/uhf_device.dart';

class DeskId extends UhfDevice {
  DeskId();

  @override
  Future<bool> probe(CommInterface commInterface, CommDevice dev) async {
    if (!await super.probe(commInterface, dev)) {
      return false;
    }

    String? rev = await queryRev();
    if (rev == null) {
      destroy();
      return false;
    }

    String fwName = rev.split(" ").first;
    if (fwName != "DESKID_UHF") {
      destroy();
      return false;
    }

    return true;
  }

  @override
  Future<bool> setStandard(UhfStandard standard) async {
    String std = "";

    if (metraTecDevice == null) {
      return false;
    }

    switch (standard) {
      case UhfStandard.ets:
        std = "ETS";
        break;
      case UhfStandard.isr:
        std = "ISR";
        break;
      case UhfStandard.fcc:
        std = "FCC";
        break;
    }

    return metraTecDevice!.sendCmdExpectRsp("STD $std", "OK!", 1000);
  }

  @override
  Future<bool> setTxPower(int power) async {
    if (power < -2 || power > 27 || metraTecDevice == null) {
      return false;
    }

    return metraTecDevice!.sendCmdExpectRsp("CFG PWR $power", "OK!", 1000);
  }
}
