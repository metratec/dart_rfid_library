class ReaderCommException extends ReaderException {
  ReaderCommException(super.cause);
}

class ReaderTimeoutException extends ReaderException {
  ReaderTimeoutException(super.cause);
}

class ReaderNoTagsException extends ReaderException {
  ReaderNoTagsException(super.cause);
}

class ReaderException implements Exception {
  String cause;
  ReaderException(this.cause);

  @override
  String toString() {
    return cause;
  }
}
