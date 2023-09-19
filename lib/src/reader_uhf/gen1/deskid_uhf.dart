import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_gen1.dart';

class DeskIdUhfReaderSettings extends UhfGen1ReaderSettings {
  DeskIdUhfReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get hasBeeper => true;
}

class ReaderDeskIdUhf extends UhfReaderGen1 {
  ReaderDeskIdUhf(CommInterface commInterface) : super(commInterface, DeskIdUhfReaderSettings());
}
