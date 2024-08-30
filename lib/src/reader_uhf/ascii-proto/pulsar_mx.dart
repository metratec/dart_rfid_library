import 'package:dart_rfid_library/reader_library.dart';
import 'package:dart_rfid_library/src/reader_uhf/reader_uhf_ascii.dart';

class PulsarMxReaderSettings extends UhfAsciiReaderSettings {
  PulsarMxReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});
}

class ReaderPulsarMx extends UhfReaderAscii {
  ReaderPulsarMx(CommInterface commInterface) : super(commInterface, PulsarMxReaderSettings());
}
