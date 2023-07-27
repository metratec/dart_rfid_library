import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_gen2.dart';

class DeskIdUhfV2EReaderSettings extends UhfGen2ReaderSettings {
  DeskIdUhfV2EReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});
}

class ReaderDeskIdUhfV2E extends UhfReaderGen2 {
  ReaderDeskIdUhfV2E(CommInterface commInterface) : super(commInterface, DeskIdUhfV2EReaderSettings());
}
