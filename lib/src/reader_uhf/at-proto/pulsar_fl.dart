import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_at.dart';

class PulsarFlReaderSettings extends UhfAtReaderSettings {
  PulsarFlReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get supportsOutputs => true;

  @override
  bool get supportsInputs => true;
}

class ReaderPulsarFL extends UhfReaderAt {
  ReaderPulsarFL(CommInterface commInterface)
      : super(commInterface, PulsarFlReaderSettings(possiblePowerValues: Iterable.generate(31)));
}
