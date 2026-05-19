/// Stitches an asterisk onto a label when the field is required.
///
/// Lives in its own file because every leaf renderer needs it and the
/// alternative (a mixin or a global helper) would muddy the dispatch table.
String? fieldLabel(String? label, bool required) {
  if (label == null) return null;
  return required ? '$label *' : label;
}
