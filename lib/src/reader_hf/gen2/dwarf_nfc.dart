import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_hf/reader_hf_gen2.dart';

class DwarfNfcReaderSettings extends HfGen2ReaderSettings {
  DwarfNfcReaderSettings();
}

class ReaderDwarfNfc extends HfReaderGen2 {
  ReaderDwarfNfc(CommInterface commInterface) : super(commInterface, DwarfNfcReaderSettings());
}
