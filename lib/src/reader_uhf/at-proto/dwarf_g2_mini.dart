import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_at.dart';

class DwarfG2MiniV2ReaderSettings extends UhfAtReaderSettings {
  DwarfG2MiniV2ReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get supportsOutputs => true;

  @override
  bool get supportsInputs => true;
}

class ReaderDwarfG2MiniV2 extends UhfReaderAt {
  ReaderDwarfG2MiniV2(CommInterface commInterface)
      : super(
            commInterface,
            DwarfG2MiniV2ReaderSettings(
              possiblePowerValues: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            ));
}
