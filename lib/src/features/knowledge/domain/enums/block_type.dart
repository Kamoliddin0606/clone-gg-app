/// Knowledge document content block types.
///
/// `unknown` is the forward-compat fallback when the backend introduces a
/// new block type — `BlockTypeX.fromString` maps unrecognised wire values
/// to it, and the renderer treats it as a no-op so the app does not crash.
enum BlockType {
  paragraph,
  heading,
  list,
  quote,
  callout,
  image,
  embed,
  code,
  table,
  divider,
  file,
  unknown;

  String get wireValue => switch (this) {
        BlockType.paragraph => 'PARAGRAPH',
        BlockType.heading => 'HEADING',
        BlockType.list => 'LIST',
        BlockType.quote => 'QUOTE',
        BlockType.callout => 'CALLOUT',
        BlockType.image => 'IMAGE',
        BlockType.embed => 'EMBED',
        BlockType.code => 'CODE',
        BlockType.table => 'TABLE',
        BlockType.divider => 'DIVIDER',
        BlockType.file => 'FILE',
        BlockType.unknown => 'UNKNOWN',
      };
}

extension BlockTypeX on BlockType {
  static BlockType fromString(String? raw) {
    if (raw == null) return BlockType.unknown;
    return BlockType.values.firstWhere(
      (e) => e.wireValue == raw,
      orElse: () => BlockType.unknown,
    );
  }
}
