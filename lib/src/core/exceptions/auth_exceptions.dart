/// Thrown by `AuthRepository.establish1cSession` when the V2-authenticated
/// user is not present in 1C. The bloc catches this and emits a typed
/// [OneCUserNotFoundFailure] so the UI can show a localized banner.
class OneCUserNotFoundException implements Exception {
  final String username;
  const OneCUserNotFoundException({required this.username});

  @override
  String toString() => 'OneCUserNotFoundException(username=$username)';
}
