import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_at.dart';

class QRG2FCCReaderSettings extends UhfAtReaderSettings {
  QRG2FCCReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get supportsOutputs => false;

  @override
  bool get supportsInputs => false;
}

class ReaderQRG2FCC extends UhfReaderAt {
  ReaderQRG2FCC(CommInterface commInterface)
      : super(
            commInterface,
            QRG2FCCReaderSettings(
              possibleRegionValues: [UhfReaderRegion.fcc.protocolString],
              possiblePowerValues: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            ));
}
