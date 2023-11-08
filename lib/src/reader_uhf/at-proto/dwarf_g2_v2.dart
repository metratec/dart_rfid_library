import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_at.dart';

class DwarfG2V2ReaderSettings extends UhfAtReaderSettings {
  DwarfG2V2ReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get supportsOutputs => true;

  @override
  bool get supportsInputs => true;
}

class ReaderDwarfG2V2 extends UhfReaderAt {
  ReaderDwarfG2V2(CommInterface commInterface)
      : super(
            commInterface,
            DwarfG2V2ReaderSettings(
              possiblePowerValues: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21],
            ));
}
