import 'dart:async';

// import 'package:metratec_device/metratec_device.dart';
// import 'package:uhf_devices/src/devices/ltz2b.dart';
import 'package:uhf_devices/uhf_devices.dart';

enum UhfStandard { etsi, isr, fcc }

abstract class UhfDevice {
  MetraTecDevice? metraTecDevice;

  /// Continous mode stream members.
  StreamController<List<String>>? _contInvCtrl;
  StreamSubscription? _contSubscription;
  final List<String> _contInv = [];

  UhfDevice();

  /// Probes the device.
  ///
  /// In order to probe the device you need to give the [commInterface]
  /// and the [dev] to this function.
  Future<bool> connect(CommInterface commInterface, CommDevice dev) async {
    if (metraTecDevice != null) {
      return true;
    }

    metraTecDevice = MetraTecDevice(commInterface);
    if (!await metraTecDevice!.probe(dev)) {
      return false;
    }

    return true;
  }

  /// Factory function for uhf devices.
  static Future<UhfDevice?> create(
      CommInterface commInterface, CommDevice dev) async {
    MetraTecDevice metraTecDevice = MetraTecDevice(commInterface);
    if (!await metraTecDevice.probe(dev)) {
      return null;
    }

    String revString = "";

    bool rc = await metraTecDevice.sendCmd("REV", 2000, (List<String> rx) {
      revString = rx.first;
      print("Revison: $revString");
      return MetraTecCommandRc.commandRcOk;
    });

    if (!rc) {
      metraTecDevice.destroy();
      return null;
    }

    metraTecDevice.destroy();

    String fwName = revString.substring(0, 12).trim();

    switch (fwName) {
      case "DESKID_UHF":
        return DeskId();
      case "DwarfG2b_Min":
        return Ltz2b();
      case "DwarfG2_Mini":
        return Ltz2();
      default:
        print("Unknown device: $fwName");
        return null;
    }
  }

  /// Destroy the UhfDevice.
  void destroy() {
    metraTecDevice?.destroy();
    metraTecDevice = null;
  }

  /// Query the revision from the device.
  ///
  /// Returns the revision string on success. Otherwise null is returned.
  Future<String?> queryRev() async {
    if (metraTecDevice == null) {
      return null;
    }

    String revString = "";

    bool rc = await metraTecDevice!.sendCmd("REV", 2000, (List<String> rx) {
      revString = rx.first;
      return MetraTecCommandRc.commandRcOk;
    });

    if (!rc) {
      return null;
    }

    return revString;
  }

  /// Query a single inventory from the uhf device.
  /// Returns a list of tags on success, null otherwise.
  Future<List<String>?> singleInventory() async {
    if (metraTecDevice == null) {
      return null;
    }

    List<String> inv = [];

    bool rc = await metraTecDevice!.sendCmd("INV", 2000, (List<String> rx) {
      if (rx.last.contains("IVF")) {
        return MetraTecCommandRc.commandRcOk;
      }

      inv.add(rx.last);
      return MetraTecCommandRc.commandRcAgain;
    });

    if (!rc) {
      return null;
    }

    return inv;
  }

  /// Query the inventory continously.
  /// To stop querying cancel the stream subscription.
  Stream<List<String>>? continousInventory() {
    if (metraTecDevice == null || _contInvCtrl != null) {
      return null;
    }

    Stream<String>? stream =
        metraTecDevice!.sendContinousCommand("CNR INV", "BRK");
    if (stream == null) {
      return null;
    }

    _contInv.clear();

    _contInvCtrl = StreamController.broadcast(onCancel: () {
      _contSubscription?.cancel();
      _contSubscription = null;
      _contInvCtrl?.close();
      _contInvCtrl = null;
    });

    _contSubscription = stream.listen((event) {
      if (event.contains("IVF")) {
        _contInvCtrl!.add(List<String>.from(_contInv));
        _contInv.clear();
      } else {
        _contInv.add(event);
      }
    });

    return _contInvCtrl!.stream;
  }

  /// Set the uhf [region].
  /// Returns true on success, false otherwise.
  Future<bool> setRegion(UhfStandard region);

  /// Set the transmit [power] level.
  /// Returns true on success, false otherwise.
  Future<bool> setTxPower(int power);
}
