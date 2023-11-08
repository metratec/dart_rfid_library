import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_hf/reader_hf_ascii.dart';

class Dwarf15ReaderSettings extends HfAsciiReaderSettings {
  Dwarf15ReaderSettings();
}

class ReaderDwarf15 extends HfReaderAscii {
  ReaderDwarf15(CommInterface commInterface) : super(commInterface, Dwarf15ReaderSettings());
}
