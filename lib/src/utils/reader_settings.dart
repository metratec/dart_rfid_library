import 'package:reader_library/src/reader.dart';
import 'package:reader_library/src/utils/config_element.dart';

abstract class ReaderSettings<T extends Reader> {
  int antennaCount = 1;

  List<bool> outputStates = [];
  List<bool> inputStates = [];

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

  /// Returns a list of [ConfigElement] that define their possible values
  /// but have no value set.
  /// They must be filled with the current config settings afterwards.
  ///
  /// The returned config elements should be copied before being filled
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
