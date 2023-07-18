abstract class ConfigElement<T> {
  final String name;
  Future<void> Function(T) setter;
  final Iterable<T>? possibleValues;
  final bool isEnum;
  T? value;

  ConfigElement({
    required this.name,
    required this.setter,
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
    required super.setter,
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
      setter: setter,
    );
  }
}

class NumConfigElement<T extends num> extends ConfigElement<T> {
  NumConfigElement({
    required super.name,
    required super.setter,
    super.possibleValues,
    super.isEnum = false,
    super.value,
  });

  @override
  NumConfigElement copy() {
    return NumConfigElement<T>(
      name: name,
      value: value,
      possibleValues: possibleValues != null ? List.of(possibleValues!) : null,
      isEnum: isEnum,
      setter: setter,
    );
  }
}

class BoolConfigElement extends ConfigElement<bool> {
  BoolConfigElement({
    required super.name,
    required super.setter,
    super.value,
  });

  @override
  BoolConfigElement copy() {
    return BoolConfigElement(
      name: name,
      value: value,
      setter: setter,
    );
  }
}
