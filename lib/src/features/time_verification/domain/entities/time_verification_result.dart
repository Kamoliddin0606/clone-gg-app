import 'package:equatable/equatable.dart';

/// Enum representing the status of time verification
enum VerificationStatus {
  /// User has valid access, can continue
  valid,
  
  /// Time limit has expired, user should be blocked
  expired,
  
  /// No time limit stored in preferences (first-time user offline)
  noTimeLimit,
  
  /// Network error occurred during verification
  networkError,
}

/// Result of time verification process
/// 
/// Contains status, optional message, and whether user should be blocked
class TimeVerificationResult extends Equatable {
  /// Status of the verification
  final VerificationStatus status;
  
  /// Optional message describing the result (for UI display)
  final String? message;
  
  /// Whether user should be blocked from accessing the app
  final bool shouldBlock;
  
  /// Optional exception that occurred during verification
  final Exception? exception;

  const TimeVerificationResult({
    required this.status,
    this.message,
    required this.shouldBlock,
    this.exception,
  });

  /// Factory for successful verification (user can access)
  factory TimeVerificationResult.valid({String? message}) {
    return TimeVerificationResult(
      status: VerificationStatus.valid,
      message: message,
      shouldBlock: false,
    );
  }

  /// Factory for expired time limit (user should be blocked)
  factory TimeVerificationResult.expired({String? message}) {
    return TimeVerificationResult(
      status: VerificationStatus.expired,
      message: message,
      shouldBlock: true,
    );
  }

  /// Factory for missing time limit (first-time user offline)
  factory TimeVerificationResult.noTimeLimit({String? message}) {
    return TimeVerificationResult(
      status: VerificationStatus.noTimeLimit,
      message: message,
      shouldBlock: true,
    );
  }

  /// Factory for network error during verification
  factory TimeVerificationResult.networkError({
    String? message,
    Exception? exception,
  }) {
    return TimeVerificationResult(
      status: VerificationStatus.networkError,
      message: message,
      shouldBlock: false,
      exception: exception,
    );
  }

  @override
  List<Object?> get props => [status, message, shouldBlock, exception];

  @override
  String toString() {
    return 'TimeVerificationResult(status: $status, shouldBlock: $shouldBlock, message: $message)';
  }

  /// Check if verification was successful
  bool get isValid => status == VerificationStatus.valid;

  /// Check if verification failed due to expiration
  bool get isExpired => status == VerificationStatus.expired;

  /// Check if verification failed due to missing time limit
  bool get hasNoTimeLimit => status == VerificationStatus.noTimeLimit;

  /// Check if verification failed due to network error
  bool get hasNetworkError => status == VerificationStatus.networkError;
}
