class DetectedTextBlock {
  final String text;
  // Normalized coordinates: [ymin, xmin, ymax, xmax] (0 to 1000)
  final List<int> box2d;
  final String? translatedText;

  DetectedTextBlock({
    required this.text,
    required this.box2d,
    this.translatedText,
  });

  factory DetectedTextBlock.fromJson(Map<String, dynamic> json) {
    // Handle coordinates that might be double or int
    final boxList = json['box_2d'] as List<dynamic>? ?? [];
    final List<int> parsedBox = boxList
        .map((e) => (e is num) ? e.round() : 0)
        .toList();

    // Ensure it has exactly 4 elements: [ymin, xmin, ymax, xmax]
    while (parsedBox.length < 4) {
      parsedBox.add(0);
    }

    final y1 = parsedBox[0];
    final x1 = parsedBox[1];
    final y2 = parsedBox[2];
    final x2 = parsedBox[3];

    final ymin = (y1 < y2 ? y1 : y2).clamp(0, 1000);
    final ymax = (y1 > y2 ? y1 : y2).clamp(0, 1000);
    final xmin = (x1 < x2 ? x1 : x2).clamp(0, 1000);
    final xmax = (x1 > x2 ? x1 : x2).clamp(0, 1000);

    return DetectedTextBlock(
      text: json['text']?.toString() ??
          json['text_content']?.toString() ??
          json['name']?.toString() ??
          '',
      box2d: [ymin, xmin, ymax, xmax],
      translatedText: json['translated_text']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'box_2d': box2d, 'translated_text': translatedText};
  }
}
