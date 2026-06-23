class DetectedTextBlock {
  final String text;
  // Normalized coordinates: [ymin, xmin, ymax, xmax] (0 to 1000)
  final List<int> box2d;

  DetectedTextBlock({
    required this.text,
    required this.box2d,
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

    return DetectedTextBlock(
      text: json['text'] as String? ?? '',
      box2d: parsedBox.sublist(0, 4),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'box_2d': box2d,
    };
  }
}
