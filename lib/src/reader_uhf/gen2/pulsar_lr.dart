import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_gen2.dart';

class PulsarLrReaderSettings extends UhfGen2ReaderSettings {
  PulsarLrReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get supportsMultiplexer => true;
  @override
  bool get supportsImpinjSettings => true;
  @override
  bool get supportsHighOnTag => true;
  @override
  bool get supportsFastStart => true;
}

class ReaderPulsarLR extends UhfReaderGen2 {
  ReaderPulsarLR(CommInterface commInterface)
      : super(commInterface, PulsarLrReaderSettings(possiblePowerValues: Iterable.generate(31)));
}
