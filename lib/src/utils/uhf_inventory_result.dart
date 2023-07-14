import 'package:reader_library/src/utils/inventory_result.dart';

class UhfTag {
  String epc;
  String tid;
  int rssi;

  UhfTag(this.epc, this.tid, this.rssi);

  UhfTag copy() => UhfTag(epc, tid, rssi);

  @override
  String toString() {
    return "{EPC:$epc, TID:$tid, RSSI:$rssi}";
  }
}

class UhfInventoryResult extends InventoryResult {
  UhfTag tag;
  int lastAntenna;

  UhfInventoryResult({
    required this.tag,
    required this.lastAntenna,
    required super.timestamp,
    super.count = 1,
  });

  static List<String> getTableHeaders({bool withTid = false, bool withRssi = false, bool withAntenna = false,}) => [
        "EPC",
        if (withTid) "TID",
        if (withRssi) "RSSI",
        "Timestamp",
        if (withAntenna) "Last Antenna",
        "Count",
      ];

  @override
  UhfInventoryResult copyWith({
    UhfTag? tag,
    DateTime? timestamp,
    int? lastAntenna,
    int? count,
  }) {
    return UhfInventoryResult(
      tag: tag ?? this.tag.copy(),
      timestamp: timestamp ?? this.timestamp,
      lastAntenna: lastAntenna ?? this.lastAntenna,
      count: count ?? this.count,
    );
  }

  @override
  List<String> toTableData({List<String>? selectedColumns}) => List.generate(
        selectedColumns?.length ?? 6,
        (index) {
          return selectedColumns != null
              ? switch (selectedColumns[index]) {
                  "EPC" => tag.epc,
                  "TID" => tag.tid,
                  "RSSI" => tag.rssi.toString(),
                  "Timestamp" => timestamp.toIso8601String(),
                  "Last Antenna" => lastAntenna.toString(),
                  "Count" => count.toString(),
                  _ => "",
                }
              : switch (index) {
                  0 => tag.epc,
                  1 => tag.tid,
                  2 => tag.rssi.toString(),
                  3 => timestamp.toIso8601String(),
                  4 => lastAntenna.toString(),
                  5 => count.toString(),
                  _ => "",
                };
        },
      );

  @override
  int compareTo(InventoryResult b, String compareBy) {
    if (b is! UhfInventoryResult) {
      return 0;
    }

    switch (compareBy) {
      case "EPC":
        return tag.epc.compareTo(b.tag.epc);
      case "Timestamp":
        return timestamp.compareTo(b.timestamp);
      case "TID":
        return tag.tid.compareTo(b.tag.tid);
      case "RSSI":
        return tag.rssi.compareTo(b.tag.rssi);
      case "Last Antenna":
        return lastAntenna.compareTo(b.lastAntenna);
      case "Count":
        return count.compareTo(b.count);
      default:
        return 0;
    }
  }

  @override
  String toString() {
    return "{tag: $tag, timestamp: $timestamp, lastAntenna: $lastAntenna, count: $count}";
  }
}
