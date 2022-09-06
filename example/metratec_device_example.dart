// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:metratec_device/metratec_device.dart';
// import 'package:metratec_device/src/command.dart';

// StreamSubscription? subscription;

// void main() async {
//   SerialInterface iface = SerialInterface();

//   List<CommDevice> devices = await iface.listDevices();

//   for (int i = 0; i < devices.length; i++) {
//     CommDevice dev = devices[i];
//     print("$i: ${dev.name} | ${dev.addr}");
//   }

//   if (devices.isEmpty) {
//     print("No devices found!");
//     return;
//   }

//   print("Choose interface number: ");

//   int num = int.parse(stdin.readLineSync()!);
//   if (num < 0 || num >= devices.length) {
//     print("No such interface!");
//     return;
//   }

//   MetraTecDevice metraTecDevice = MetraTecDevice(iface);
//   if (!await metraTecDevice.probe(devices[num])) {
//     print("Could not probe device!");
//     metraTecDevice.destroy();
//     return;
//   }

//   print("Device ready...");

//   bool rc = await metraTecDevice.sendCmdExpectRsp("MOD STD ETS", "OK!", 1000);
//   if (!rc) {
//     print("Failed to set STD!");
//   } else {
//     print("Standart set");
//   }

//   print("Testing single inventory...");

//   rc = await metraTecDevice.sendCmd("INV", 1000, _invHandler);
//   if (!rc) {
//     print("INV failed!");
//   }

//   print("Testing continous mode...");

//   Stream<String>? stream =
//       metraTecDevice.sendContinousCommand("CNR INV", "BRK");
//   if (stream == null) {
//     print("No stream returned!");
//   } else {
//     int counter = 0;
//     subscription = stream.listen((data) {
//       print("$counter: $data");
//       if (counter++ > 100) {
//         subscription?.cancel();

//         metraTecDevice.destroy();
//         print("Device destroyed");
//       }
//     });
//   }
// }

// MetraTecCommandRc _invHandler(List<String> rsp) {
//   print(rsp.last);

//   if (rsp.last.contains("IVF")) {
//     return MetraTecCommandRc.commandRcOk;
//   }

//   return MetraTecCommandRc.commandRcAgain;
// }
