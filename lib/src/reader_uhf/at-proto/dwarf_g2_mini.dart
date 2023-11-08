import 'package:reader_library/reader_library.dart';
import 'package:reader_library/src/reader_uhf/reader_uhf_at.dart';

class DwarfG2MiniReaderSettings extends UhfAtReaderSettings {
  DwarfG2MiniReaderSettings({super.possiblePowerValues, super.possibleQValues, super.possibleRegionValues});

  @override
  bool get supportsOutputs => true;

  @override
  bool get supportsInputs => true;
}

class ReaderDwarfG2Mini extends UhfReaderAt {
  ReaderDwarfG2Mini(CommInterface commInterface)
      : super(
            commInterface,
            DwarfG2MiniReaderSettings(
              possiblePowerValues: const [0, 1, 2, 3, 4, 5, 6, 7, 8, 9],
            ));
}
