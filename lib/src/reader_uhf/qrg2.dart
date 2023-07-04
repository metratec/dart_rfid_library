import 'package:reader_library/reader_library.dart';

class ReaderQrg2 extends UhfReaderGen2 {
  ReaderQrg2(CommInterface commInterface)
      : super(commInterface, UhfReaderSettings(0, 9));
}
