import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_at.dart';

class DeskIdUhfV2EReaderSettings extends UhfAtReaderSettings {
  DeskIdUhfV2EReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get hasBeeper => true;
}

class ReaderDeskIdUhfV2E extends UhfReaderAt {
  ReaderDeskIdUhfV2E(CommInterface commInterface)
      : super(
            commInterface,
            DeskIdUhfV2EReaderSettings(
              possibleRegionValues: [UhfReaderRegion.etsi.protocolString],
              possiblePowerValues: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            ));
}
