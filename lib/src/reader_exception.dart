class ReaderCommException extends ReaderException {
  ReaderCommException(super.cause, {super.inner});
}

class ReaderTimeoutException extends ReaderException {
  ReaderTimeoutException(super.cause, {super.inner});
}

class ReaderNoTagsException extends ReaderException {
  ReaderNoTagsException(super.cause, {super.inner});
}

class ReaderRangeException extends ReaderException {
  ReaderRangeException(super.cause, {required RangeError inner}) : super(inner: inner);
}

class ReaderException implements Exception {
  String cause;
  Object? inner;
  ReaderException(this.cause, {this.inner});

  @override
  String toString() {
    return cause;
  }
}
