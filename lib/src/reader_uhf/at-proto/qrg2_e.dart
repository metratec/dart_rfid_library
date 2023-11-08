import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_at.dart';

class QRG2EReaderSettings extends UhfAtReaderSettings {
  QRG2EReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get supportsOutputs => false;

  @override
  bool get supportsInputs => false;
}

class ReaderQRG2E extends UhfReaderAt {
  ReaderQRG2E(CommInterface commInterface)
      : super(
            commInterface,
            QRG2EReaderSettings(
              possibleRegionValues: [UhfReaderRegion.etsi.protocolString],
              possiblePowerValues: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            ));
}
