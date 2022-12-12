import 'dart:async';
import 'package:string_validator/string_validator.dart';

import 'package:uhf_devices/uhf_devices.dart';

enum UhfStandard { etsi, isr, fcc }

abstract class UhfDevice {
  MetraTecDevice? metraTecDevice;

  /// Continous mode stream members.
  StreamController<List<String>>? _contInvCtrl;
  StreamSubscription? _contSubscription;
  final List<String> _contInv = [];

  // UhfDevice();

  /// Probes the device.
  ///
  /// In order to connect to the device you need to give the [commInterface]
  /// and the [dev] to this function.
  Future<bool> connect(CommInterface commInterface, CommDevice dev) async {
    if (metraTecDevice != null) {
      return true;
    }

    metraTecDevice = MetraTecDevice(commInterface);
    if (!await metraTecDevice!.probe(dev)) {
      print("Could not probe");
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

    bool returnValue =
        await metraTecDevice.sendCmd("RFW", 2000, (List<String> rx) {
      revString = rx.first;
      return MetraTecCommandRc.commandRcOk;
    });

    if (!returnValue) {
      await metraTecDevice.destroy();
      return null;
    }

    // some devices (like RP2040 based) can have noise on the UART which leads to an "UCO" with the first command - just try again
    if (revString == 'UCO') {
      bool returnValue =
          await metraTecDevice.sendCmd("RFW", 2000, (List<String> rx) {
        revString = rx.first;
        return MetraTecCommandRc.commandRcOk;
      });

      if (!returnValue) {
        await metraTecDevice.destroy();
        return null;
      }
    }

    await metraTecDevice.destroy();

    if (revString.length < 16) {
      print("Illegal device response: $revString");
      return null;
    }

    String fwName = revString.substring(0, 12).trim();
    switch (fwName) {
      case "DESKID_UHF":
        return DeskId();
      case "LTZ2b":
        return Ltz2b();
      case "DwarfG2_Mini":
        return Ltz2();
      default:
        print("Unknown device: $fwName");
        return null;
    }
  }

  /// Destroy the UhfDevice.
  Future<void> destroy() async {
    await metraTecDevice?.destroy();
    metraTecDevice = null;
    print("device destroyed");
  }

  /// Query the revision from the device.
  ///
  /// Returns the revision string on success. Otherwise null is returned.
  Future<String?> queryRev() async {
    if (metraTecDevice == null) {
      return null;
    }

    String revString = "";

    bool rc = await metraTecDevice!.sendCmd("RFW", 2000, (List<String> rx) {
      revString = rx.first;
      return MetraTecCommandRc.commandRcOk;
    });

    if (!rc) {
      return null;
    }

    return revString;
  }

  /// Set the Q Value
  Future<bool> setQValue(int qValue) async {
    if (metraTecDevice == null) {
      return false;
    }
    if (qValue < 0 || qValue > 15 || metraTecDevice == null) {
      return false;
    }

    return metraTecDevice!.sendCmdExpectRsp("SQV $qValue", "OK!", 2000);
  }

  /// Set inventory retry value
  Future<bool> setInventoryRetry(int retryValue) async {
    if (metraTecDevice == null) {
      return false;
    }
    if (retryValue < 0 || retryValue > 10 || metraTecDevice == null) {
      return false;
    }

    return metraTecDevice!.sendCmdExpectRsp("SIR $retryValue", "OK!", 2000);
  }

  /// Set the channel mask
  Future<bool> setChannelMask(int channelMask) async {
    if (metraTecDevice == null) {
      return false;
    }
    if (channelMask < 0 || channelMask > 8 || metraTecDevice == null) {
      return false;
    }
    return metraTecDevice!
        .sendCmdExpectRsp("SRI MSK $channelMask", "OK!", 2000);
  }

  /// Set the Rx Gain
  Future<bool> setRxGain(int rxGain) async {
    if (metraTecDevice == null) {
      return false;
    }
    if (rxGain < 0 || rxGain > 70 || metraTecDevice == null) {
      return false;
    }
    return metraTecDevice!.sendCmdExpectRsp("CFG RXG $rxGain", "OK!", 2000);
  }

  /// Set the Rx Wait Time
  Future<bool?> setRxWaitTime(int rwTime) async {
    if (metraTecDevice == null) {
      return null;
    }
    if (rwTime < 0 || rwTime > 255 || metraTecDevice == null) {
      return false;
    }
    return metraTecDevice!.sendCmdExpectRsp("CFG RWT $rwTime", "OK!", 2000);
  }

  /// Set the Rx Wait Time
  Future<bool?> setRxWaitTimeLong(int rwTimeLong) async {
    if (metraTecDevice == null) {
      return null;
    }
    if (rwTimeLong < 0 || rwTimeLong > 20000 || metraTecDevice == null) {
      return false;
    }
    return metraTecDevice!.sendCmdExpectRsp("CFG RWL $rwTimeLong", "OK!", 2000);
  }

  /// Set the Rx Wait Time
  Future<bool> rampDown() async {
    if (metraTecDevice == null) {
      return false;
    }

    return metraTecDevice!.sendCmdExpectRsp("SRI OFF", "OK!", 2000);
  }

  /// Set the Rx Wait Time
  Future<bool> rampUp() async {
    if (metraTecDevice == null) {
      return false;
    }

    return metraTecDevice!.sendCmdExpectRsp("SRI ON", "OK!", 2000);
  }

  /// Write the EPC
  Future<List<String>?> writeEpc(String data) async {
    if (metraTecDevice == null) {
      return null;
    }
    //check for hex characters and length (divisible by 4)
    if (!isHexadecimal(data)) {
      print("not hex");
      return null;
    }
    if (data.length > 16 || (data.length % 4) != 0) {
      print("wrong data length");
      return null;
    }

    // return metraTecDevice!.sendCmdExpectRsp("WDT EPC 2 $data", "OK!", 2000);

    List<String> resultList = [];

    bool rc = await metraTecDevice!.sendCmd("WDT EPC 2 $data", 2000,
        (List<String> rx) {
      print(rx);
      if (rx.last.contains("IVF")) {
        return MetraTecCommandRc.commandRcOk;
      }

      if (rx.last.startsWith('TOE') ||
          rx.last.startsWith('TNR') ||
          rx.last.startsWith('CER') ||
          rx.last.startsWith('TOR') ||
          rx.last.startsWith('HBE')) {
        //ignore error message for now
      } else {
        resultList.add(rx.last);
      }

      return MetraTecCommandRc.commandRcAgain;
    });

    if (!rc) {
      return null;
    }

    return resultList;
  }

  /// Write the PC
  Future<bool?> writePc(int pcLength) async {
    if (metraTecDevice == null) {
      return null;
    }

    //check for length
    if (pcLength < 0 || pcLength > 31 || metraTecDevice == null) {
      return false;
    }

    return metraTecDevice!.sendCmdExpectRsp("WDT LEN $pcLength", "OK!", 2000);
  }

  /// Query a single inventory from the uhf device.
  /// Returns a list of tags on success, null otherwise.
  Future<List<String>?> singleInventory() async {
    if (metraTecDevice == null) {
      return null;
    }

    List<String> inv = [];

    bool rc = await metraTecDevice!.sendCmd("INV", 2000, (List<String> rx) {
      print(rx);
      if (rx.last.contains("IVF")) {
        return MetraTecCommandRc.commandRcOk;
      }

      if (rx.last.startsWith('TOE') ||
          rx.last.startsWith('TNR') ||
          rx.last.startsWith('CER') ||
          rx.last.startsWith('HBE')) {
        //ignore error message for now
      } else {
        inv.add(rx.last);
      }

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
        //TODO ad check for error codes
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
