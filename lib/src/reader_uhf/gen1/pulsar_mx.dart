import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_gen1.dart';

class PulsarMxReaderSettings extends UhfGen1ReaderSettings {
  PulsarMxReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});
}

class ReaderPulsarMx extends UhfReaderGen1 {
  ReaderPulsarMx(CommInterface commInterface) : super(commInterface, PulsarMxReaderSettings());
}
