import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_hf/reader_hf_gen2.dart';

class QrNfcReaderSettings extends HfGen2ReaderSettings {
  QrNfcReaderSettings();
}

class ReaderQrNfc extends HfReaderGen2 {
  ReaderQrNfc(CommInterface commInterface) : super(commInterface, QrNfcReaderSettings());
}
