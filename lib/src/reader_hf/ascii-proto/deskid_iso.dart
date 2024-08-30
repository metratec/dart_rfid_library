import 'package:dart_rfid_library/reader_library.dart';
import 'package:dart_rfid_library/src/reader_hf/reader_hf_ascii.dart';

class DeskIdIsoReaderSettings extends HfAsciiReaderSettings {
  DeskIdIsoReaderSettings();
}

class ReaderDeskIdIso extends HfReaderAscii {
  ReaderDeskIdIso(CommInterface commInterface) : super(commInterface, DeskIdIsoReaderSettings());
}
