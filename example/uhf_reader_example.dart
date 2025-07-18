import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_rfid_utils/dart_rfid_utils.dart';
import 'package:dart_rfid_library/reader_library.dart';
import 'package:dart_rfid_library/src/reader_uhf/at-proto/deskid_uhf_v2_e.dart';

void main() async {
  SerialSettings serialSettings = SerialSettings("/dev/ttyACM0");
  CommInterface commInterface = SerialInterface(serialSettings);

  // UhfReader reader = ReaderPulsarLR(commInterface);
  UhfReader reader = ReaderDeskIdUhfV2E(commInterface);

  print("Trying to connect to reader");

  if (await reader.connect(onError: (ex, stack) => reader.disconnect()) == false) {
    print("Failed to connect");
    return;
  }

  print("Reader connected");

  try {
    stdout.write("Setting power... ");
    await reader.setOutputPower([9]);
    stdout.writeln("Done!");

    stdout.write("Running inventory... ");
    await reader.setInventorySettings(UhfInvSettings(false, true, true, false));
    List<InventoryResult> inventory = await reader.inventory();
    stdout.writeln("Done!");
    print(inventory);

    Uint8List data = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF]);
    stdout.write("Writing data to USR: $data... ");
    List<UhfRwResult> writeRes = await reader.write(UhfMemoryBank.usr.protocolString, 0, data.toHexString());
    stdout.writeln("Done!");
    stdout.writeln(writeRes);

    stdout.write("Reading data from USR... ");
    List<UhfRwResult> readRes = await reader.read(UhfMemoryBank.usr.protocolString, 0, 4);
    stdout.writeln("Done!");
    stdout.writeln(readRes);

    stdout.write("Setting mask to 0x2993... ");
    await reader.setByteMask(UhfMemoryBank.epc.protocolString, 10, Uint8List.fromList([0x29, 0x93]).toHexString());
    stdout.writeln("Done!");

    stdout.write("Running inventory... ");
    inventory = await reader.inventory();
    stdout.writeln("Done!");
    print(inventory);

    stdout.write("Clearing mask... ");
    await reader.clearByteMask();
    stdout.writeln("Done!");

    await _cinvTest(reader);
    await _heartbeatTest(reader);
  } on ReaderTimeoutException catch (e) {
    print(e);
  } on ReaderCommException catch (e) {
    print(e);
  } on ReaderException catch (e) {
    print(e);
  }

  // disconnect the reader
  await reader.disconnect();
}

bool _printCinv = true;
Future<void> _cinvTest(UhfReader reader) async {
  _printCinv = true;
  StreamSubscription sub = reader.getInvStream().listen((event) {
    if (_printCinv) {
      print(event);
    }
  });

  try {
    stdout.write("Starting continuous inventory... ");
    await reader.startContinuousInventory();
    stdout.writeln("Done!");
    await Future.delayed(Duration(seconds: 5));
    _printCinv = false;
    stdout.write("Stopping continuous inventory... ");
    await reader.stopContinuousInventory();
    stdout.writeln("Done!");
    unawaited(sub.cancel());
  } catch (e) {
    unawaited(sub.cancel());
    rethrow;
  }
}

Future<void> _heartbeatTest(UhfReader reader) async {
  stdout.write("Starting heartbeat... ");
  await reader.startHeartBeat(3, () {
    print("Heartbeat received");
  }, () {
    print("Heartbeat timed out!");
  });
  stdout.writeln("Done!");

  await Future.delayed(Duration(seconds: 10));

  stdout.write("Stopping heartbeat... ");
  await reader.stopHeartBeat();
  stdout.writeln("Done!");
}
