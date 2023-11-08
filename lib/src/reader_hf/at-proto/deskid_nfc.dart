import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_hf/reader_hf_at.dart';

class DeskIdNfcReaderSettings extends HfAtReaderSettings {
  DeskIdNfcReaderSettings();

  @override
  bool get hasBeeper => true;
}

class ReaderDeskIdNfc extends HfReaderAt {
  ReaderDeskIdNfc(CommInterface commInterface) : super(commInterface, DeskIdNfcReaderSettings());
}
