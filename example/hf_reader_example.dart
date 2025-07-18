import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:dart_rfid_utils/dart_rfid_utils.dart';
import 'package:logger/logger.dart';
import 'package:dart_rfid_library/reader_library.dart';
import 'package:dart_rfid_library/src/reader_hf/reader_hf_at.dart';

Future<void> _readTest(HfReader reader) async {
  stdout.write("Setting mode to iso14a... ");
  await reader.setMode(HfReaderMode.iso14a.protocolString);
  stdout.writeln("Done!");

  stdout.write("Scanning for tags... ");
  List<HfInventoryResult> inv = await reader.inventory();
  if (inv.isEmpty) {
    stdout.writeln("No tags found!");
    return;
  }
  stdout.writeln("Done!");

  stdout.write("Selecting tag... ");
  await reader.selectTag(inv.first.tag);
  stdout.writeln("Done!");

  stdout.write("Authenticating with default key...");
  Uint8List mfcKey = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);
  await reader.authMfc(6, mfcKey.toHexString(), MfcKeyType.A);
  stdout.writeln("Done!");

  Uint8List data = Uint8List.fromList(
      [0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF]);

  stdout.write("Writing data: $data... ");
  await reader.write(6, data.toHexString());
  stdout.writeln("Done!");

  stdout.write("Reading back data... ");
  String readBack = await reader.read(6);
  stdout.writeln(readBack);

  if (data.toHexString() != readBack) {
    stderr.writeln("Data and read back data differs!");
  }
}

bool _printCinv = true;
Future<void> _cinvTest(HfReader reader) async {
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

Future<void> _heartbeatTest(HfReader reader) async {
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

void main() async {
  SerialSettings serialSettings = SerialSettings("/dev/ttyACM0");
  CommInterface commInterface = SerialInterface(serialSettings);

  Logger.level = Level.error;

  HfReader reader = HfReaderAt(commInterface, HfAtReaderSettings());

  print("Connecting reader");

  if (await reader.connect(onError: (ex, stack) => reader.disconnect()) == false) {
    print("Failed to connect");
    return;
  }

  print("Connected");

  try {
    await _readTest(reader);
    await _cinvTest(reader);
    await _heartbeatTest(reader);
  } on ReaderTimeoutException catch (e) {
    print(e);
  } on ReaderCommException catch (e) {
    print(e);
  } on ReaderException catch (e) {
    print(e);
  }

  await reader.disconnect();
}
