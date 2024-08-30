import 'package:dart_rfid_utils/dart_rfid_utils.dart';
import 'package:dart_rfid_library/src/reader.dart';

abstract class ReaderSettings<T extends Reader> {
  int antennaCount = 1;

  List<bool> outputStates = [];
  List<bool> inputStates = [];

  /// The current inv antenna value. Should always be set if the reader checks the inv antenna value
  int invAntenna = 1;

  // Overwrite these getters in Settings implementations
  bool get isUhfDevice => false;
  bool get isUhfAtDevice => false;
  bool get isHfDevice => false;
  bool get isHfAtDevice => false;
  bool get supportsInventoryReport => false;
  bool get supportsOutputs => false;
  bool get supportsInputs => false;
  bool get hasBeeper => false;

  List<Membank> get readMembanks => [];
  List<Membank> get writeMembanks => [];
  List<Membank> get lockMembanks => [];

  /// Returns a list of [ConfigElement] that define the possible values
  /// and current value for each of the ReaderSettings elements.
  List<ConfigElement> getConfigElements(T reader);

  bool get isActive => true;
}
