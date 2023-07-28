import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_hf/reader_hf_gen1.dart';

class QuasarMxReaderSettings extends HfGen1ReaderSettings {
  QuasarMxReaderSettings();
}

class ReaderQuasarMx extends HfReaderGen1 {
  ReaderQuasarMx(CommInterface commInterface) : super(commInterface, QuasarMxReaderSettings());
}
