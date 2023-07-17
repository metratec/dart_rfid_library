abstract class ConfigElement<T> {
  final String name;
  final Iterable<T>? possibleValues;
  final bool isEnum;
  T? value;

  ConfigElement({
    required this.name,
    this.possibleValues,
    this.isEnum = false,
    this.value,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "value": value,
        "possibleValues": possibleValues,
        "isEnum": isEnum,
      };

  ConfigElement copy();

  @override
  String toString() => toJson().toString();
}

class StringConfigElement extends ConfigElement<String> {
  StringConfigElement({
    required super.name,
    super.possibleValues,
    super.isEnum = true,
    super.value,
  });

  @override
  StringConfigElement copy() {
    return StringConfigElement(
      name: name,
      value: value,
      possibleValues: possibleValues != null ? List.of(possibleValues!) : null,
      isEnum: isEnum,
    );
  }
}

class NumConfigElement<T extends num> extends ConfigElement<T> {
  NumConfigElement({
    required super.name,
    super.possibleValues,
    super.isEnum = false,
    super.value,
  });

  @override
  NumConfigElement copy() {
    return NumConfigElement(
      name: name,
      value: value,
      possibleValues: possibleValues != null ? List.of(possibleValues!) : null,
      isEnum: isEnum,
    );
  }
}

class BoolConfigElement extends ConfigElement<bool> {
  BoolConfigElement({
    required super.name,
    super.value,
  });

  @override
  BoolConfigElement copy() {
    return BoolConfigElement(
      name: name,
      value: value,
    );
  }
}
