/// Converts text copied from rich text sources to readable plain text.
String toPlainText(String? source) {
  if (source == null || source.trim().isEmpty) return '';

  var text = source
      .replaceAll(
          RegExp(r'<(script|style)\b[^>]*>[\s\S]*?</\1>', caseSensitive: false),
          '')
      .replaceAll(RegExp(r'<\s*br\s*/?\s*>', caseSensitive: false), '\n')
      .replaceAll(
          RegExp(r'</\s*(p|div|li|h[1-6]|tr)\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), ' ');

  const entities = <String, String>{
    '&nbsp;': ' ',
    '&amp;': '&',
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
  };
  entities.forEach((entity, value) {
    text = text.replaceAll(RegExp(entity, caseSensitive: false), value);
  });
  text = text.replaceAllMapped(
    RegExp(r'&#(x[\da-f]+|\d+);?', caseSensitive: false),
    (match) {
      final raw = match.group(1)!;
      final codePoint = raw.toLowerCase().startsWith('x')
          ? int.tryParse(raw.substring(1), radix: 16)
          : int.tryParse(raw);
      if (codePoint == null || codePoint < 0 || codePoint > 0x10ffff) {
        return match.group(0)!;
      }
      return String.fromCharCode(codePoint);
    },
  );

  return text
      .replaceAll(RegExp(r'[ \t\u00a0]+'), ' ')
      .replaceAll(RegExp(r' *\n *'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}
