import 'package:dart_rfid_library/reader_library.dart';
import 'package:dart_rfid_library/src/reader_uhf/reader_uhf_at.dart';

class PlrmReaderSettings extends UhfAtReaderSettings {
  PlrmReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get supportsOutputs => true;

  @override
  bool get supportsInputs => false;
}

class ReaderPlrm extends UhfReaderAt {
  ReaderPlrm(CommInterface commInterface)
      : super(commInterface, PlrmReaderSettings(possiblePowerValues: Iterable.generate(34)));
}
