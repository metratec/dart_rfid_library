class ReaderCommException implements Exception {
  String cause;
  ReaderCommException(this.cause);

  @override
  String toString() {
    return cause;
  }
}

class ReaderTimeoutException implements Exception {
  String cause;
  ReaderTimeoutException(this.cause);

  @override
  String toString() {
    return cause;
  }
}

class ReaderException implements Exception {
  String cause;
  ReaderException(this.cause);

  @override
  String toString() {
    return cause;
  }
}
