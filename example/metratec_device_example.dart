import 'dart:async';
import 'dart:io';

import 'package:reader_library/reader_library.dart';
import 'package:logger/logger.dart';
import 'package:reader_library/src/reader_exception.dart';

void main() async {
  SerialSettings serialSettings = SerialSettings("/dev/ttyACM0");
  CommInterface commInterface = SerialInterface(serialSettings);

  Logger.level = Level.error;

  DeskIdNfc reader = DeskIdNfc(commInterface);

  print("Connecting reader");

  if (await reader.connect() == false) {
    print("Failed to connect");
    return;
  }

  print("Connected");

  StreamSubscription cinvSub = reader.getInventoryStream().listen((inv) {
    print(inv.uids);
  });

  AtReaderInfo info = await reader.queryInfo();
  print("FW : ${info.fwName}:${info.fwRevision}");
  print("HW : ${info.hwName}:${info.hwRevision}");
  print("SER: ${info.serial}");

  try {
    await reader.setHeartBeat(5, () {
      print("No heartbeat received! Device dead?");
    });
  } catch (e) {
    print("Setting heartbeat failed!");
    return;
  }

  try {
    print("Mfc test:");
    stdout.write("Setting mode to ISO14A... ");
    await reader.setMode(DeskIdNfcMode.iso14a);
    print("Done!");
    stdout.write("Scanning for tags... ");
    Inventory inv = await reader.inventory();
    if (inv.uids.isNotEmpty) {
      print("Found ${inv.uids.first}!");
      stdout.write("Selecting ${inv.uids.first}...");
      await reader.selectTag(inv.uids.first);
      print("Done!");
      stdout.write("Authenticating... ");
      await reader.mfcAuth(5, "FFFFFFFFFFFF", MfcKeyType.A);
      print("Done!");
      stdout.write("Writing data... ");
      String wrtData = "000102030405060708090A0B0C0D0E0F";
      await reader.writeBlock(5, wrtData);
      print("Done!");
      stdout.write("Reading back data... ");
      String readData = await reader.readBlock(5);
      print("Done!");
      if (wrtData != readData) {
        print("Read data differs from written: $wrtData != $readData");
      }
    } else {
      print("");
      print("No tags found!");
    }
  } on ReaderCommException catch (e) {
    print(e.cause);
  } on ReaderTimeoutException catch (e) {
    print(e.cause);
  } on ReaderException catch (e) {
    print(e.cause);
  } catch (e) {
    print("Something went wrong!");
  }

  await reader.startContinuousInventory();
  await Future.delayed(Duration(seconds: 10));
  await reader.stopContinuousInventory();
  cinvSub.cancel();

  await reader.stopHeartBeat();

  reader.disconnect();
}
