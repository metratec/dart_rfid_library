import 'package:reader_library/src/reader.dart';
import 'package:reader_library/src/utils/config_element.dart';

abstract class ReaderSettings<T extends Reader> {
  int antennaCount = 1;

  /// Returns a list of [ConfigElement] that define their possible values
  /// but have no value set.
  /// They must be filled with the current config settings afterwards.
  ///
  /// The returned config elements should be copied before being filled
  List<ConfigElement> getConfigElements(T reader);
}
