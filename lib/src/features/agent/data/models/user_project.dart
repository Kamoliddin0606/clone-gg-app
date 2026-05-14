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

  /// V2 backend Project.id (UUID). Preferred value for `X-Project-Id`.
  /// Null until the backend exposes the field on `GetProjectsUser` or a
  /// dedicated `/api/mobile/v2/projects/` endpoint.
  final String? idUuid;

  /// 1C numeric ref (`00-0001`-style). Accepted by the backend as a
  /// fallback for `X-Project-Id` when [idUuid] is unavailable.
  final String? id1c;

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
    this.idUuid,
    this.id1c,
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
      idUuid: map['id_uuid'] as String?,
      id1c: map['id_1c'] as String?,
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
      'id_uuid': idUuid,
      'id_1c': id1c,
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
    String? idUuid,
    String? id1c,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProject(
      id: id ?? this.id,
      userCode: userCode ?? this.userCode,
      code: code ?? this.code,
      name: name ?? this.name,
      idUuid: idUuid ?? this.idUuid,
      id1c: id1c ?? this.id1c,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Returns the best identifier to send in `X-Project-Id` header.
  /// Preference order: UUID → 1C ref → SOAP `code` (last-resort).
  String? get headerValue {
    if (idUuid != null && idUuid!.isNotEmpty) return idUuid;
    if (id1c != null && id1c!.isNotEmpty) return id1c;
    if (code.isNotEmpty) return code;
    return null;
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
