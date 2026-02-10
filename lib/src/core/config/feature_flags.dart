/// Feature flags for controlling application behavior
/// 
/// Used for gradual rollout of new features and A/B testing
class FeatureFlags {
  /// Enable GetUserEx SOAP method instead of GetUser
  /// 
  /// When true, authentication will use GetUserEx which includes app version
  /// When false, uses legacy GetUser method (backward compatible)
  /// 
  /// Rollout plan:
  /// - Phase 1: false (current behavior)
  /// - Phase 2: true for testing (10% users)
  /// - Phase 3: true for all users
  /// - Phase 4: Remove GetUser code
  static const bool useGetUserEx = false;
  
  /// Enable verbose logging for authentication
  /// 
  /// When true, prints detailed SOAP request/response for debugging
  static const bool verboseAuthLogging = false;
  
  /// Enable version validation before sending to server
  /// 
  /// When true, validates version format before making SOAP request
  /// Throws error if version is invalid
  static const bool strictVersionValidation = true;
}
