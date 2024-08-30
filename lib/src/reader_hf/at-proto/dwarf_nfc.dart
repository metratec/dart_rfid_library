import 'package:dart_rfid_library/reader_library.dart';
import 'package:dart_rfid_library/src/reader_hf/reader_hf_at.dart';

class DwarfNfcReaderSettings extends HfAtReaderSettings {
  DwarfNfcReaderSettings();
}

class ReaderDwarfNfc extends HfReaderAt {
  ReaderDwarfNfc(CommInterface commInterface) : super(commInterface, DwarfNfcReaderSettings());
}
