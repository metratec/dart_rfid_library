import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_gen2.dart';

class ReaderPulsarLR extends UhfReaderGen2 {
  ReaderPulsarLR(CommInterface commInterface)
      : super(commInterface, UhfGen2ReaderSettings(possiblePowerValues: Iterable.generate(31)));
}
