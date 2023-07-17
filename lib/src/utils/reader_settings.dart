import 'package:reader_library/src/utils/config_element.dart';

abstract class ReaderSettings {
  /// Returns a list of [ConfigElement] that define their possible values
  /// but have no value set.
  /// They must be filled with the current config settings afterwards.
  ///
  /// The returned config elements should be copied before being filled
  List<ConfigElement> getConfigElements();
}
