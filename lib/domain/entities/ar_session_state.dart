sealed class ARSessionState {}

class NotStartedState extends ARSessionState {}

class InitializingState extends ARSessionState {}

class ReadyState extends ARSessionState {}

class FailedState extends ARSessionState {
  final String error;

  FailedState(this.error);
}

class InvalidStateException implements Exception {
  final String message;

  InvalidStateException(this.message);

  @override
  String toString() => 'InvalidStateException: $message';
}
