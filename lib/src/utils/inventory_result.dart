/// Classes which implement this should have a static getTableHeaders function
/// of type List<String>.
/// It should define the names which are used by compareTo to
/// check which field to compare.
abstract class InventoryResult {
  DateTime timestamp;
  int count = 1;

  InventoryResult({
    required this.timestamp,
    this.count = 1,
  });

  InventoryResult copyWith({
    DateTime? timestamp,
    int? count,
  });

  static List<String> getTableHeaders() => ["Timestamp", "Count"];

  /// Used for displaying the data in an [InventoryTable]
  ///
  /// The returned list should have the same length as the
  /// length of [selectedColumns]
  ///
  /// If [selectedColumns] is null every element should be returned
  List<String> toTableData({List<String>? selectedColumns});

  /// Used for sorting in an [InventoryTable]
  ///
  /// The compareBy parameter should be one of the element
  /// names of the static getTableHeaders function.
  ///
  /// If the compareBy parameter is not one of the titles of the header
  /// the method should return 0
  int compareTo(InventoryResult b, String compareBy);
}
