class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.text,
    required this.date,
    required this.defaultImage,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String text;
  final DateTime date;
  final int defaultImage;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntry copyWith({
    int? id,
    String? text,
    DateTime? date,
    int? defaultImage,
    String? imagePath,
    bool clearImagePath = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      text: text ?? this.text,
      date: date ?? this.date,
      defaultImage: defaultImage ?? this.defaultImage,
      imagePath: clearImagePath ? null : (imagePath ?? this.imagePath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
