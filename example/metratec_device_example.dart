import 'dart:async';
import 'dart:io';

import 'package:metratec_device/metratec_device.dart';
import 'package:uhf_devices/uhf_devices.dart';

StreamSubscription? sub;

void main() async {
  CommInterface commInterface = SerialInterface();

  List<CommDevice> devices = await commInterface.listDevices();
  if (devices.isEmpty) {
    print("No devices found!");
    return;
  }

  for (int i = 0; i < devices.length; i++) {
    CommDevice dev = devices[i];
    print("$i: ${dev.name} | ${dev.addr}");
  }

  int num = int.parse(stdin.readLineSync()!);
  if (num < 0 || num >= devices.length) {
    print("No such interface!");
    return;
  }

  UhfDevice? uhfDevice = await UhfDevice.create(commInterface, devices[num]);
  if (uhfDevice == null) {
    print("No compatible UHF device found!");
    return;
  }

  if (!await uhfDevice.probe(commInterface, devices[num])) {
    print("Failed to probe device!");
    return;
  }

  print("Found UHF device: ${await uhfDevice.queryRev()}");
  print("Setting power: ${await uhfDevice.setTxPower(5)}");
  print("Setting standard: ${await uhfDevice.setStandard(UhfStandard.ets)}");
  print("Single inventory: ${await uhfDevice.inventory()}");
  print("Continous inventory:");

  Stream<List<String>>? contInv = uhfDevice.continousInventory();
  if (contInv != null) {
    int counter = 0;
    sub = contInv.listen((event) {
      print("$counter: $event");
      if (counter++ >= 99) {
        sub?.cancel();
        uhfDevice.destroy();
      }
    });
  } else {
    uhfDevice.destroy();
  }
}
