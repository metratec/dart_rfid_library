import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_gen2.dart';

class DeskIdUhfV2FReaderSettings extends UhfGen2ReaderSettings {
  DeskIdUhfV2FReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});
}

class ReaderDeskIdUhfV2F extends UhfReaderGen2 {
  ReaderDeskIdUhfV2F(CommInterface commInterface)
      : super(
            commInterface,
            DeskIdUhfV2FReaderSettings(
              possibleRegionValues: [UhfReaderRegion.fcc.protocolString],
              possiblePowerValues: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            ));
}
