import 'package:metratec_device/metratec_device.dart';
import 'package:uhf_devices/src/uhf_device.dart';

class Ltz2b extends UhfDevice {
  Ltz2b();

  @override
  Future<bool> connect(CommInterface commInterface, CommDevice dev) async {
    if (!await super.connect(commInterface, dev)) {
      return false;
    }

    String? rev = await queryRev();
    if (rev == null) {
      destroy();
      return false;
    }

    String fwName = rev.split(" ").first;
    if (fwName != "DwarfG2b_Mini") {
      destroy();
      return false;
    }

    return true;
  }

  @override
  Future<bool> setRegion(UhfStandard region) async {
    String regionStr = "";

    if (metraTecDevice == null) {
      return false;
    }

    switch (region) {
      case UhfStandard.etsi:
        regionStr = "ETS";
        break;
      case UhfStandard.isr:
        throw Error();

      case UhfStandard.fcc:
        throw Error();
    }

    return metraTecDevice!.sendCmdExpectRsp("STD $regionStr", "OK!", 2000);
  }

  @override
  Future<bool> setTxPower(int power) async {
    if (power < -2 || power > 9 || metraTecDevice == null) {
      return false;
    }

    return metraTecDevice!.sendCmdExpectRsp("CFG PWR $power", "OK!", 2000);
  }
}
