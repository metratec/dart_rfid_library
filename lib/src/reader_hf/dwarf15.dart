import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_hf/reader_hf_gen1.dart';

class Dwarf15ReaderSettings extends HfGen1ReaderSettings {
  Dwarf15ReaderSettings();
}

class ReaderDwarf15 extends HfReaderGen1 {
  ReaderDwarf15(CommInterface commInterface) : super(commInterface, Dwarf15ReaderSettings());
}
