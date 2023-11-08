import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_ascii.dart';

class DwarfG2ReaderSettings extends UhfAsciiReaderSettings {
  DwarfG2ReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});
}

class ReaderDwarfG2 extends UhfReaderAscii {
  ReaderDwarfG2(CommInterface commInterface) : super(commInterface, DwarfG2ReaderSettings());
}
