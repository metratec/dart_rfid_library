import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_gen2.dart';

class ReaderQRG2 extends UhfReaderGen2 {
  ReaderQRG2(CommInterface commInterface)
      : super(
            commInterface,
            UhfGen2ReaderSettings(
              possibleRegionValues: [UhfReaderRegion.etsi.protocolString],
            ));
}
