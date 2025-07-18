import 'package:dart_rfid_library/reader_library.dart';
import 'package:dart_rfid_library/src/reader_hf/reader_hf_ascii.dart';

class QuasarMxReaderSettings extends HfAsciiReaderSettings {
  QuasarMxReaderSettings();
}

class ReaderQuasarMx extends HfReaderAscii {
  ReaderQuasarMx(CommInterface commInterface) : super(commInterface, QuasarMxReaderSettings());
}
