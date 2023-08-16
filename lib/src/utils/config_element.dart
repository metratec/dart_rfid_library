abstract class ConfigElement<T> {
  final String name;
  Future<void> Function(T) setter;
  final Iterable<T>? possibleValues;
  final bool isEnum;
  final String? group;
  T? value;

  ConfigElement({
    required this.name,
    required this.setter,
    this.possibleValues,
    this.isEnum = false,
    this.value,
    this.group,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "value": value,
        "possibleValues": possibleValues,
        "isEnum": isEnum,
        "group": group,
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
    super.group,
  });

  @override
  StringConfigElement copy() {
    return StringConfigElement(
      name: name,
      value: value,
      possibleValues: possibleValues != null ? List.of(possibleValues!) : null,
      isEnum: isEnum,
      group: group,
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
    super.group,
  });

  @override
  NumConfigElement copy() {
    return NumConfigElement<T>(
      name: name,
      value: value,
      possibleValues: possibleValues != null ? List.of(possibleValues!) : null,
      isEnum: isEnum,
      group: group,
      setter: setter,
    );
  }
}

class BoolConfigElement extends ConfigElement<bool> {
  BoolConfigElement({
    required super.name,
    required super.setter,
    super.group,
    super.value,
  });

  @override
  BoolConfigElement copy() {
    return BoolConfigElement(
      name: name,
      value: value,
      group: group,
      setter: setter,
    );
  }
}
