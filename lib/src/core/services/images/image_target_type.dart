/// Canonical image-target keys.
///
/// The mobile widgets always speak these strings; the repository
/// translates between the canonical key and the wire format the
/// backend actually expects (e.g. Django ContentType emits
/// `projectproduct` for products).
class ImageTargetType {
  ImageTargetType._();

  static const String product = 'product';
  static const String customer = 'customer';
  static const String project = 'project';

  /// Wire alias for products on the new backend — Django reports the
  /// content-type model as `projectproduct`. The repository uses the
  /// logical key `product` going forward, but accepts the legacy
  /// alias when parsing responses for forward-compatibility.
  static const String productWireAlias = 'projectproduct';
}
