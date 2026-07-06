/// A simple Result type for propagating success/failure without throwing
/// raw exceptions across service boundaries.
///
/// Usage:
///   final result = await resumeService.getResumes();
///   result.when(
///     success: (resumes) => ...,
///     failure: (msg) => ScaffoldMessenger.of(context).showSnackBar(...),
///   );
sealed class Result<T> {
  const Result();

  /// Whether this result represents a successful outcome.
  bool get isSuccess => this is Success<T>;

  /// Whether this result represents a failure.
  bool get isFailure => this is Failure<T>;

  /// Returns the data value if [Success], otherwise null.
  T? get dataOrNull => isSuccess ? (this as Success<T>).data : null;

  /// Handle both cases and return a value.
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) {
    return switch (this) {
      Success<T> s => success(s.data),
      Failure<T> f => failure(f.userMessage),
    };
  }

  // ── Convenience constructors ─────────────────────────────────────────────

  static Result<T> ok<T>(T data) => Success<T>(data);

  static Result<T> fail<T>(String userMessage, {Object? cause}) =>
      Failure<T>(userMessage, cause: cause);

  /// The user lost connectivity or the server took too long.
  static Result<T> networkError<T>({Object? cause}) => Failure<T>(
        'Connection failed. Check your internet and try again.',
        cause: cause,
      );

  /// The user was signed out between operations.
  static Result<T> authError<T>({Object? cause}) => Failure<T>(
        'Your session has expired. Please sign in again.',
        cause: cause,
      );

  /// DeepSeek returned HTTP 429.
  static Result<T> rateLimitError<T>({Object? cause}) => Failure<T>(
        'AI rate limit reached. Please wait a moment and try again.',
        cause: cause,
      );

  /// The AI returned something we couldn't parse.
  static Result<T> parseError<T>({Object? cause}) => Failure<T>(
        'The AI returned an unexpected response. Please try again.',
        cause: cause,
      );
}

/// A successful result carrying the return value.
final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;
}

/// A failed result carrying a user-friendly message and optional cause for logging.
final class Failure<T> extends Result<T> {
  const Failure(this.userMessage, {this.cause});
  final String userMessage;
  final Object? cause;
}
