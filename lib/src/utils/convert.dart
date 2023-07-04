import 'dart:typed_data';

String uint8ListToString(Uint8List list) {
  return list
      .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
      .join('');
}

Uint8List stringToUint8List(String str) {
  List<int> data = [];

  for (int i = 0; i < str.length ~/ 2; i++) {
    data.add(int.parse(str.substring(2 * i, 2 * (i + 1)), radix: 16));
  }

  return Uint8List.fromList(data);
}
