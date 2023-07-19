import 'package:reader_library/reader_library.dart';

class ReaderPulsarLR extends UhfReaderGen2 {
  ReaderPulsarLR(CommInterface commInterface)
      : super(commInterface, UhfReaderSettings(possiblePowerValues: Iterable.generate(31)));
}
