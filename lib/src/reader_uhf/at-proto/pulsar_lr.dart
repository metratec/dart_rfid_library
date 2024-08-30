import 'package:dart_rfid_library/reader_library.dart';
import 'package:dart_rfid_library/src/reader_uhf/reader_uhf_at.dart';

class PulsarLrReaderSettings extends UhfAtReaderSettings {
  PulsarLrReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get supportsOutputs => true;

  @override
  bool get supportsInputs => true;
}

class ReaderPulsarLR extends UhfReaderAt {
  ReaderPulsarLR(CommInterface commInterface)
      : super(commInterface, PulsarLrReaderSettings(possiblePowerValues: Iterable.generate(31)));
}
