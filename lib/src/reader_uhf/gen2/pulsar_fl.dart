import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_gen2.dart';

class PulsarFlReaderSettings extends UhfGen2ReaderSettings {
  PulsarFlReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get supportsOutputs => true;

  @override
  bool get supportsInputs => true;
}

class ReaderPulsarFL extends UhfReaderGen2 {
  ReaderPulsarFL(CommInterface commInterface)
      : super(commInterface, PulsarFlReaderSettings(possiblePowerValues: Iterable.generate(31)));
}
