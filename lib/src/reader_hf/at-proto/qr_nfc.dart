import 'package:dart_rfid_library/reader_library.dart';
import 'package:dart_rfid_library/src/reader_hf/reader_hf_at.dart';

class QrNfcReaderSettings extends HfAtReaderSettings {
  QrNfcReaderSettings();
}

class ReaderQrNfc extends HfReaderAt {
  ReaderQrNfc(CommInterface commInterface) : super(commInterface, QrNfcReaderSettings());
}
