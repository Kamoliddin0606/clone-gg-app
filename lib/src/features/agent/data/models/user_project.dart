/// Модель проекта пользователя / Foydalanuvchi loyihasi modeli / User project model
///
/// Хранит данные проектов, полученных с сервера через SOAP API метод GetProjectsUser.
/// Serverdan GetProjectsUser SOAP API metodi orqali olingan loyiha ma'lumotlarini saqlaydi.
/// Stores project data retrieved from the server via GetProjectsUser SOAP API method.
///
/// Связи / Bog'lanishlar / Relationships:
/// - user_code → users.code (принадлежит пользователю / foydalanuvchiga tegishli / belongs to user)
/// - code → уникальный код проекта / loyihaning noyob kodi / unique project code
class UserProject {
  /// Уникальный идентификатор записи в БД
  /// Bazadagi yozuv uchun noyob identifikator
  /// Unique identifier for the record in database
  final int? id;

  /// Код пользователя, которому принадлежит проект
  /// Loyiha tegishli bo'lgan foydalanuvchi kodi
  /// User code this project belongs to
  final String userCode;

  /// Уникальный код проекта
  /// Loyihaning noyob kodi
  /// Unique code identifier for the project
  final String code;

  /// Название проекта
  /// Loyiha nomi
  /// Display name of the project
  final String name;

  /// Время создания записи локально
  /// Yozuv lokal yaratilgan vaqti
  /// Timestamp when this record was created locally
  final DateTime? createdAt;

  /// Время последнего обновления записи локально
  /// Yozuv lokal yangilangan oxirgi vaqti
  /// Timestamp when this record was last updated locally
  final DateTime? updatedAt;

  UserProject({
    this.id,
    required this.userCode,
    required this.code,
    required this.name,
    this.createdAt,
    this.updatedAt,
  });

  /// Создать UserProject из Map (БД)
  /// Map (DB) dan UserProject yaratish
  /// Create UserProject from database map
  factory UserProject.fromMap(Map<String, dynamic> map) {
    return UserProject(
      id: map['id'] as int?,
      userCode: map['user_code'] as String,
      code: map['code'] as String,
      name: map['name'] as String,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  /// Преобразовать в Map для сохранения в БД
  /// DB ga saqlash uchun Map ga aylantirish
  /// Convert to database map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_code': userCode,
      'code': code,
      'name': name,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Создать копию с обновлёнными полями
  /// Yangilangan maydonlar bilan nusxa yaratish
  /// Create a copy with optional field updates
  UserProject copyWith({
    int? id,
    String? userCode,
    String? code,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProject(
      id: id ?? this.id,
      userCode: userCode ?? this.userCode,
      code: code ?? this.code,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProject &&
        other.code == code &&
        other.userCode == userCode;
  }

  @override
  int get hashCode => code.hashCode ^ userCode.hashCode;

  @override
  String toString() {
    return 'UserProject(code: $code, name: $name, userCode: $userCode)';
  }
}
