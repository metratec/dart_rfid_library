import 'dart:async';

import 'package:reader_library/reader_library.dart';
import 'package:logger/logger.dart';
import 'package:reader_library/src/at_reader/at_reader_common.dart';
import 'package:reader_library/src/at_reader/desk_id_nfc.dart';

void main() async {
  SerialSettings serialSettings = SerialSettings("/dev/ttyACM0");
  CommInterface commInterface = SerialInterface(serialSettings);

  //Logger.level = Level.error;

  DeskIdNfc reader = DeskIdNfc(commInterface);

  print("Connecting reader");

  if (await reader.connect() == false) {
    print("Failed to connect");
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
    await reader.setMode(DeskIdNfcMode.iso14a);
    Inventory inv = await reader.inventory();
    if (inv.uids.isNotEmpty) {
      reader.selectTag(inv.uids.first);
      reader.mfcAuth(5, "FFFFFFFFFFFF", MfcKeyType.A);
      reader.writeBlock(5, "000102030405060708090A0B0C0D0E0F");
    }
  } catch (e) {
    print("Something went wrong!");
  }

  await reader.startContinuousInventory();
  await Future.delayed(Duration(seconds: 5));
  await reader.stopContinuousInventory();
  cinvSub.cancel();

  reader.disconnect();
}
