import 'package:dart_rfid_library/reader_library.dart';
import 'package:dart_rfid_library/src/reader_uhf/reader_uhf_at.dart';

class DeskIdUhfV2FReaderSettings extends UhfAtReaderSettings {
  DeskIdUhfV2FReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get hasBeeper => true;
}

class ReaderDeskIdUhfV2F extends UhfReaderAt {
  ReaderDeskIdUhfV2F(CommInterface commInterface)
      : super(
            commInterface,
            DeskIdUhfV2FReaderSettings(
              possibleRegionValues: [UhfReaderRegion.fcc.protocolString],
              possiblePowerValues: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            ));
}
