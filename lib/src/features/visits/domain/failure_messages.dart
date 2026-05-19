import 'failures.dart';

/// Human-readable copy for the `visits_*` error codes shipped by the
/// backend (changelog § 10). The strings live in code rather than `.arb`
/// because:
///   * the wire codes are stable identifiers we want to grep for,
///   * fallback uz/ru/en strings are short enough to inline without
///     dragging the localisation engine into the failure path, and
///   * the BLoC needs a synchronous string when emitting a
///     `VisitSessionError` — `AppLocalizations.of(context)` requires a
///     BuildContext we don't have inside the dispatcher.
///
/// Real product copy can override this at the screen layer; the helper
/// is the safety net so we never show the user a bare `VISITS_*` code.
class VisitFailureCopy {
  const VisitFailureCopy._();

  /// Returns a user-facing message for the failure in [locale]
  /// (`'uz'` / `'ru'` / `'en'`). Unknown codes fall back to the
  /// `Failure.message` string the dispatcher attached.
  static String localize(Failure failure, {String locale = 'uz'}) {
    final code = failure.code;
    final entry = code == null ? null : _table[code];
    if (entry == null) return failure.message;
    return entry[locale] ?? entry['en'] ?? failure.message;
  }

  static const _table = <String, Map<String, String>>{
    'VISITS_GEOFENCE_VIOLATION': {
      'uz': 'Mijoz manzilidan uzoqdasiz — yaqinroq joydan urinib ko\'ring',
      'ru': 'Вы слишком далеко от клиента — подойдите ближе',
      'en': 'Too far from the customer — get closer and retry',
    },
    'VISITS_CLOCK_DRIFT': {
      'uz': 'Telefon vaqti noto\'g\'ri — sozlamalardan avtomatik vaqtni yoqing',
      'ru': 'Часы телефона сбиты — включите автоопределение времени',
      'en': 'Phone clock is off — turn on automatic time in settings',
    },
    'VISITS_VALIDATION_FAILED': {
      'uz': 'Forma to\'liq emas — qizil maydonlarni to\'ldiring',
      'ru': 'Форма заполнена не до конца — проверьте красные поля',
      'en': 'Form is incomplete — check the highlighted fields',
    },
    'VISITS_PHOTO_MISSING': {
      'uz': 'Foto yuklashda xato — qayta urinib ko\'ring',
      'ru': 'Ошибка загрузки фото — попробуйте ещё раз',
      'en': 'Photo upload failed — try again',
    },
    'VISITS_IDEMPOTENCY_MISMATCH': {
      'uz': 'Ichki xato — qo\'llab-quvvatlashga murojaat qiling',
      'ru': 'Внутренняя ошибка — обратитесь в поддержку',
      'en': 'Internal error — please contact support',
    },
    'VISITS_CONFLICT': {
      'uz': 'Bu tashrif allaqachon yakunlangan',
      'ru': 'Этот визит уже завершён',
      'en': 'This visit is already finished',
    },
    'VISITS_NOT_FOUND': {
      'uz': 'Tashrif topilmadi',
      'ru': 'Визит не найден',
      'en': 'Visit not found',
    },
    'VISITS_DEVICE_COMPROMISED': {
      'uz': 'Qurilma xavfsiz emas — boshqa telefondan urinib ko\'ring',
      'ru': 'Устройство небезопасно — попробуйте на другом телефоне',
      'en': 'Device flagged as compromised — use a different phone',
    },
  };
}
