import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:logger/logger.dart';
import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_exception.dart';
import 'package:reader_library/src/reader_hf/reader_hf.dart';

Future<void> _readTest(HfReader reader) async {
  stdout.write("Setting mode to iso14a... ");
  await reader.setMode(HfReaderMode.iso14a);
  stdout.writeln("Done!");

  stdout.write("Scanning for tags... ");
  List<HfTag> inv = await reader.inventory();
  if (inv.isEmpty) {
    stdout.writeln("No tags found!");
    return;
  }
  stdout.writeln("Done!");

  stdout.write("Selecting tag... ");
  await reader.selectTag(inv.first);
  stdout.writeln("Done!");

  stdout.write("Authenticating with default key...");
  Uint8List mfcKey = Uint8List.fromList([0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]);
  await reader.mfcAuth(6, mfcKey, MfcKeyType.A);
  stdout.writeln("Done!");

  Uint8List data = Uint8List.fromList(
      [0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF, 0xDE, 0xAD, 0xBE, 0xEF]);

  stdout.write("Writing data: $data... ");
  await reader.write(data, 6);
  stdout.writeln("Done!");

  stdout.write("Reading back data... ");
  Uint8List readBack = await reader.read(6);
  stdout.writeln("$readBack");

  if (ListEquality().equals(data, readBack) == false) {
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
    sub.cancel();
  } catch (e) {
    sub.cancel();
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

  HfReader reader = HfReaderGen2(commInterface, HfReaderSettings());

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
  } on ReaderException catch (e) {
    print(e);
  } on ReaderTimeoutException catch (e) {
    print(e);
  } on ReaderCommException catch (e) {
    print(e);
  }

  await reader.disconnect();
}
