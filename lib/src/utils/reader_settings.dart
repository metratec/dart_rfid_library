import 'package:reader_library/src/reader.dart';
import 'package:reader_library/src/utils/config_element.dart';

abstract class ReaderSettings<T extends Reader> {
  int antennaCount = 1;

  List<bool> outputStates = [];
  List<bool> inputStates = [];

  /// The current inv antenna value. Should always be set if the reader checks the inv antenna value
  int invAntenna = 1;

  // Overwrite these getters in Settings implementations
  bool get isUhfDevice => false;
  bool get isUhfGen2Device => false;
  bool get isHfDevice => false;
  bool get isHfGen2Device => false;
  bool get supportsTagType => false;
  bool get supportsInventoryReport => false;
  List<Membank> get readMembanks => [];
  List<Membank> get writeMembanks => [];
  List<Membank> get lockMembanks => [];

  /// Returns a list of [ConfigElement] that define the possible values
  /// and current value for each of the ReaderSettings elements.
  List<ConfigElement> getConfigElements(T reader);
}

enum Membank {
  none,
  epc,
  tid,
  user,
  pc,
  lock,
  kill;

  @override
  String toString() => switch (this) {
        Membank.epc => "EPC",
        Membank.tid => "TID",
        Membank.pc => "PC",
        Membank.user => "User",
        Membank.none => "None",
        Membank.lock => "Lock Pwd",
        Membank.kill => "Kill Pwd",
      };

  String get protocolString => switch (this) {
        Membank.epc => "EPC",
        Membank.tid => "TID",
        Membank.pc => "PC",
        Membank.user => "USR",
        Membank.none => "None",
        Membank.lock => "LCK",
        Membank.kill => "KILL",
      };
}
