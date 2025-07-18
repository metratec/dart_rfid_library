import 'package:dart_rfid_library/reader_library.dart';
import 'package:dart_rfid_library/src/reader_uhf/reader_uhf_ascii.dart';

class DeskIdUhfReaderSettings extends UhfAsciiReaderSettings {
  DeskIdUhfReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get hasBeeper => true;
}

class ReaderDeskIdUhf extends UhfReaderAscii {
  ReaderDeskIdUhf(CommInterface commInterface) : super(commInterface, DeskIdUhfReaderSettings());
}
