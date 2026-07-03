class PageRange {
  final int start;
  final int end;

  PageRange(this.start, this.end);
}

List<PageRange> mergeRanges(List<PageRange> ranges) {
  if (ranges.isEmpty) return [];

  ranges.sort((a, b) => a.start.compareTo(b.start));

  final merged = <PageRange>[];
  var current = ranges.first;

  for (int i = 1; i < ranges.length; i++) {
    final next = ranges[i];

    if (next.start <= current.end + 1) {
      current = PageRange(
        current.start,
        next.end > current.end ? next.end : current.end,
      );
    } else {
      merged.add(current);
      current = next;
    }
  }

  merged.add(current);
  return merged;
}

List<PageRange> parseRanges(String input) {
  final parts = input.split(',');
  final ranges = <PageRange>[];

  for (final p in parts) {
    final trimmed = p.trim();

    // ===== CASE 1: SINGLE PAGE =====
    if (!trimmed.contains('-')) {
      final page = int.tryParse(trimmed);
      if (page == null || page <= 0) continue;

      final index = page - 1;
      ranges.add(PageRange(index, index));
      continue;
    }

    // ===== CASE 2: RANGE =====
    final se = trimmed.split('-');
    if (se.length != 2) continue;

    final start = int.tryParse(se[0].trim());
    final end = int.tryParse(se[1].trim());

    if (start == null || end == null) continue;

    final s = start - 1;
    final e = end - 1;

    if (s < 0 || e < s) continue;

    ranges.add(PageRange(s, e));
  }

  return ranges;
}
