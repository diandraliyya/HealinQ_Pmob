class LyricContentModel {
  final String id;
  final String title;
  final String artist;
  final String lyricExcerpt;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LyricContentModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.lyricExcerpt,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LyricContentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return LyricContentModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      artist: map['artist']?.toString() ?? '',
      lyricExcerpt:
          map['lyric_excerpt']?.toString() ?? '',
      isActive: map['is_active'] == true,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }
}

class JarItemContentModel {
  final String id;
  final String itemType;
  final String content;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const JarItemContentModel({
    required this.id,
    required this.itemType,
    required this.content,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JarItemContentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return JarItemContentModel(
      id: map['id']?.toString() ?? '',
      itemType:
          map['item_type']?.toString() ??
              'affirmation',
      content: map['content']?.toString() ?? '',
      isActive: map['is_active'] == true,
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }
}

class PassionCategoryContentModel {
  final String id;
  final String code;
  final String name;
  final String emoji;
  final String? description;
  final bool isActive;

  const PassionCategoryContentModel({
    required this.id,
    required this.code,
    required this.name,
    required this.emoji,
    required this.description,
    required this.isActive,
  });

  factory PassionCategoryContentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return PassionCategoryContentModel(
      id: map['id']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      emoji: map['emoji']?.toString() ?? '',
      description:
          _nullableString(map['description']),
      isActive: map['is_active'] == true,
    );
  }
}

class PassionQuestionContentModel {
  final String id;
  final String questionText;
  final bool isActive;
  final int sortOrder;
  final String categoryId;
  final String categoryCode;
  final String categoryName;
  final String categoryEmoji;
  final DateTime createdAt;
  final DateTime updatedAt;

  int? answerValue;

  PassionQuestionContentModel({
    required this.id,
    required this.questionText,
    required this.isActive,
    required this.sortOrder,
    required this.categoryId,
    required this.categoryCode,
    required this.categoryName,
    required this.categoryEmoji,
    required this.createdAt,
    required this.updatedAt,
    this.answerValue,
  });

  factory PassionQuestionContentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final dynamic rawCategory =
        map['passion_categories'];

    Map<String, dynamic> category =
        <String, dynamic>{};

    if (rawCategory is Map) {
      category = Map<String, dynamic>.from(
        rawCategory,
      );
    } else if (rawCategory is List &&
        rawCategory.isNotEmpty &&
        rawCategory.first is Map) {
      category = Map<String, dynamic>.from(
        rawCategory.first as Map,
      );
    }

    return PassionQuestionContentModel(
      id: map['id']?.toString() ?? '',
      questionText:
          map['question_text']?.toString() ?? '',
      isActive: map['is_active'] == true,
      sortOrder: _parseInt(map['sort_order']),
      categoryId:
          map['category_id']?.toString() ??
              category['id']?.toString() ??
              '',
      categoryCode:
          category['code']?.toString() ?? '',
      categoryName:
          category['name']?.toString() ?? '',
      categoryEmoji:
          category['emoji']?.toString() ?? '',
      createdAt: _parseDate(map['created_at']),
      updatedAt: _parseDate(map['updated_at']),
    );
  }
}

class PassionResultContentModel {
  final String categoryCode;
  final String categoryName;
  final String categoryEmoji;
  final double normalizedScore;
  final int resultRank;

  const PassionResultContentModel({
    required this.categoryCode,
    required this.categoryName,
    required this.categoryEmoji,
    required this.normalizedScore,
    required this.resultRank,
  });

  factory PassionResultContentModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return PassionResultContentModel(
      categoryCode:
          map['category_code']?.toString() ?? '',
      categoryName:
          map['category_name']?.toString() ?? '',
      categoryEmoji:
          map['category_emoji']?.toString() ?? '',
      normalizedScore:
          _parseDouble(map['normalized_score']),
      resultRank:
          _parseInt(map['result_rank']),
    );
  }

  String get displayLabel {
    final String cleanName =
        categoryName.trim().isEmpty
            ? categoryCode
            : categoryName;

    return categoryEmoji.trim().isEmpty
        ? cleanName
        : '$cleanName $categoryEmoji';
  }
}

DateTime _parseDate(dynamic value) {
  return DateTime.tryParse(
            value?.toString() ?? '',
          )?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  return int.tryParse(
        value?.toString() ?? '',
      ) ??
      0;
}

double _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();

  return double.tryParse(
        value?.toString() ?? '',
      ) ??
      0;
}

String? _nullableString(dynamic value) {
  final String text =
      value?.toString().trim() ?? '';

  return text.isEmpty ? null : text;
}
