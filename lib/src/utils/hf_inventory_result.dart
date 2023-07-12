import 'package:reader_library/src/utils/inventory_result.dart';

class HfTag {
  String uid;
  String? tagType;

  HfTag(this.uid, this.tagType);

  HfTag copy() => HfTag(uid, tagType);

  @override
  String toString() {
    return "{uid: $uid, tagType: $tagType}";
  }
}

class HfInventoryResult extends InventoryResult {
  HfTag tag;

  HfInventoryResult({
    required this.tag,
    required super.timestamp,
    super.count = 1,
  });

  static List<String> getTableHeaders() => ["UID", "Tag Type", "Timestamp", "Count"];

  @override
  HfInventoryResult copyWith({
    HfTag? tag,
    DateTime? timestamp,
    int? count,
  }) {
    return HfInventoryResult(
      tag: tag ?? this.tag.copy(),
      timestamp: timestamp ?? this.timestamp,
      count: count ?? this.count,
    );
  }

  @override
  List<String> toTableData({List<String>? selectedColumns}) => List.generate(
        selectedColumns?.length ?? 4,
        (index) {
          return selectedColumns != null
              ? switch (selectedColumns[index]) {
                  "UID" => tag.uid,
                  "Tag Type" => tag.tagType ?? "",
                  "Timestamp" => timestamp.toIso8601String(),
                  "Count" => count.toString(),
                  _ => "",
                }
              : switch (index) {
                  0 => tag.uid,
                  1 => tag.tagType ?? "",
                  2 => timestamp.toIso8601String(),
                  3 => count.toString(),
                  _ => "",
                };
        },
      );

  @override
  int compareTo(InventoryResult b, String compareBy) {
    if (b is! HfInventoryResult) {
      return 0;
    }

    switch (compareBy) {
      case "UID":
        return tag.uid.compareTo(b.tag.uid);
      case "Timestamp":
        return timestamp.compareTo(b.timestamp);
      case "Tag Type":
        return tag.tagType?.compareTo(b.tag.tagType ?? "") ?? 0;
      case "Count":
        return count.compareTo(b.count);
      default:
        return 0;
    }
  }

  @override
  String toString() {
    return "{tag: $tag, timestamp: $timestamp, count: $count}";
  }
}
