enum PhotoCategory { front, side, back }

extension PhotoCategoryX on PhotoCategory {
  String get dbValue => name;
  String get label => name.toUpperCase();

  static PhotoCategory fromDb(String value) =>
      PhotoCategory.values.firstWhere((c) => c.name == value, orElse: () => PhotoCategory.front);
}

class ProgressPhoto {
  final int? id;
  final String date;
  final PhotoCategory category;
  final String filePath;

  const ProgressPhoto({this.id, required this.date, required this.category, required this.filePath});

  factory ProgressPhoto.fromMap(Map<String, dynamic> m) => ProgressPhoto(
        id: m['id'] as int?,
        date: m['date'] as String,
        category: PhotoCategoryX.fromDb(m['category'] as String),
        filePath: m['file_path'] as String,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'date': date,
        'category': category.dbValue,
        'file_path': filePath,
      };
}
