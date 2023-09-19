import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_hf/reader_hf_gen2.dart';

class DeskIdNfcReaderSettings extends HfGen2ReaderSettings {
  DeskIdNfcReaderSettings();

  @override
  bool get hasBeeper => true;
}

class ReaderDeskIdNfc extends HfReaderGen2 {
  ReaderDeskIdNfc(CommInterface commInterface) : super(commInterface, DeskIdNfcReaderSettings());
}
