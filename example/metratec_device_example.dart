import 'dart:async';

import 'package:reader_library/reader_library.dart';
import 'package:logger/logger.dart';
import 'package:reader_library/src/at_reader/at_reader_common.dart';

void main() async {
  SerialSettings serialSettings = SerialSettings("/dev/ttyACM0");
  CommInterface commInterface = SerialInterface(serialSettings);

  Logger.level = Level.error;

  AtReaderCommon reader = AtReaderCommon(commInterface);

  print("Connecting reader");

  if (await reader.connect() == false) {
    print("Failed to connect");
  }

  print("Connected");

  StreamSubscription cinvSub = reader.getInventoryStream().listen((inv) {
    print(inv.uids);
  });

  await reader.startContinuousInventory();
  await Future.delayed(Duration(seconds: 5));
  await reader.stopContinuousInventory();
  cinvSub.cancel();

  reader.disconnect();
}
