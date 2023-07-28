import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_hf/reader_hf_gen1.dart';

class DeskIdIsoReaderSettings extends HfGen1ReaderSettings {
  DeskIdIsoReaderSettings();
}

class ReaderDeskIdIso extends HfReaderGen1 {
  ReaderDeskIdIso(CommInterface commInterface) : super(commInterface, DeskIdIsoReaderSettings());
}
