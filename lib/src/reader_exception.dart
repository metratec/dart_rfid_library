class ReaderCommException implements Exception {
  String cause;
  ReaderCommException(this.cause);
}

class ReaderTimeoutException implements Exception {
  String cause;
  ReaderTimeoutException(this.cause);
}

class ReaderException implements Exception {
  String cause;
  ReaderException(this.cause);
}
