// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Gloria Marketing';

  @override
  String get login => 'Войти';

  @override
  String get username => 'Имя пользователя';

  @override
  String get password => 'Пароль';

  @override
  String get welcome => 'Добро пожаловать!';

  @override
  String get enterCredentials => 'Пожалуйста, введите свои учетные данные';

  @override
  String get forgotPassword => 'Забыли пароль?';

  @override
  String get orders => 'Заказы';

  @override
  String get tradingPoints => 'Торговые точки';

  @override
  String get tradingPointsFilter => 'Торговые точки';

  @override
  String get warehouses => 'Склады';

  @override
  String get contracts => 'Договоры';

  @override
  String get reports => 'Отчеты';

  @override
  String get settings => 'Настройки';

  @override
  String get marketing => 'Маркетинг';

  @override
  String get promotions => 'Акции';

  @override
  String get dashboard => 'Панель управления';

  @override
  String get totalSales => 'Общий объем продаж';

  @override
  String get activeAgents => 'Активные агенты';

  @override
  String get orderCount => 'Заказы';

  @override
  String get revenue => 'Доход';

  @override
  String get logout => 'Выход';

  @override
  String get confirmLogout => 'Вы действительно хотите выйти из приложения?';

  @override
  String get cancel => 'Отмена';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get error => 'Ошибка';

  @override
  String get loading => 'Загрузка...';

  @override
  String get noData => 'Нет данных';

  @override
  String get retry => 'Повторить';

  @override
  String get search => 'Поиск';

  @override
  String get filter => 'Фильтр';

  @override
  String get dateRange => 'Диапазон дат';

  @override
  String get allDates => 'Все даты';

  @override
  String get clients => 'Клиенты';

  @override
  String get status => 'Статус';

  @override
  String get total => 'Итого';

  @override
  String get quantity => 'Количество';

  @override
  String get price => 'Цена';

  @override
  String get sum => 'Сумма';

  @override
  String get currency => 'UZS';

  @override
  String get orderDate => 'Дата заказа';

  @override
  String get clientName => 'Имя клиента';

  @override
  String get items => 'Товары';

  @override
  String get details => 'Подробности';

  @override
  String get edit => 'Редактировать';

  @override
  String get delete => 'Удалить';

  @override
  String get save => 'Сохранить';

  @override
  String get close => 'Закрыть';

  @override
  String get back => 'Назад';

  @override
  String get next => 'Далее';

  @override
  String get previous => 'Предыдущий';

  @override
  String get home => 'Главная';

  @override
  String get profile => 'Профиль';

  @override
  String get notifications => 'Уведомления';

  @override
  String get language => 'Язык';

  @override
  String get theme => 'Тема';

  @override
  String get light => 'Светлая';

  @override
  String get dark => 'Темная';

  @override
  String get system => 'Системная';

  @override
  String get english => 'Английский';

  @override
  String get russian => 'Русский';

  @override
  String get uzbek => 'Узбекский';

  @override
  String get selectLanguage => 'Выберите язык';

  @override
  String get settingsSaved => 'Настройки успешно сохранены';

  @override
  String get dataSync => 'Синхронизация данных';

  @override
  String get syncNow => 'Синхронизировать сейчас';

  @override
  String lastSync(String time) {
    return 'Последняя синхронизация: $time';
  }

  @override
  String get syncing => 'Синхронизация...';

  @override
  String get syncComplete => 'Синхронизация завершена';

  @override
  String syncError(String error) {
    return 'Ошибка синхронизации: $error';
  }

  @override
  String get noInternet => 'Нет подключения к интернету';

  @override
  String get offlineMode => 'Офлайн режим - отображаются кэшированные данные';

  @override
  String get onlineMode => 'Онлайн режим';

  @override
  String get serverError => 'Ошибка сервера';

  @override
  String get invalidCredentials => 'Неверное имя пользователя или пароль';

  @override
  String get sessionExpired => 'Сессия истекла';

  @override
  String get permissionDenied => 'Доступ запрещен';

  @override
  String get fileNotFound => 'Файл не найден';

  @override
  String get unknownError => 'Неизвестная ошибка';

  @override
  String get tryAgain => 'Пожалуйста, попробуйте еще раз';

  @override
  String get contactSupport => 'Связаться с поддержкой';

  @override
  String get version => 'Версия';

  @override
  String get about => 'О программе';

  @override
  String get help => 'Помощь';

  @override
  String get feedback => 'Обратная связь';

  @override
  String get rateApp => 'Оценить приложение';

  @override
  String get shareApp => 'Поделиться приложением';

  @override
  String get privacyPolicy => 'Политика конфиденциальности';

  @override
  String get termsOfService => 'Условия обслуживания';

  @override
  String get warehouseManagement => 'Управление складом';

  @override
  String get packingDashboard => 'Панель упаковки';

  @override
  String get collectionDashboard => 'Панель сбора';

  @override
  String get bossDashboard => 'Панель руководителя';

  @override
  String get forwarderDashboard => 'Панель экспедитора';

  @override
  String get agentDashboard => 'Панель агента';

  @override
  String get todayProductivity => 'Производительность сегодня';

  @override
  String get ordersProcessed => 'заказов обработано';

  @override
  String get totalCollected => 'Всего собрано';

  @override
  String get activeCollections => 'Активные сборы';

  @override
  String get pendingCollections => 'Ожидающие сборы';

  @override
  String get collected => 'Собрано';

  @override
  String get pending => 'Ожидает';

  @override
  String get inTransit => 'В пути';

  @override
  String get delivered => 'Доставлено';

  @override
  String get ready => 'Готово';

  @override
  String get picking => 'Сбор';

  @override
  String get packed => 'Упаковано';

  @override
  String get completed => 'Завершено';

  @override
  String get toPack => 'К упаковке';

  @override
  String get inProgress => 'В процессе';

  @override
  String get lowStock => 'Мало на складе';

  @override
  String get outOfStock => 'Нет в наличии';

  @override
  String get receiveGoods => 'Получить товары';

  @override
  String get issueGoods => 'Выдать товары';

  @override
  String get findItem => 'Найти товар';

  @override
  String get scanBarcode => 'Сканировать штрих-код';

  @override
  String get warehouseCapacity => 'Вместимость склада';

  @override
  String get used => 'использовано';

  @override
  String get incoming => 'Входящие';

  @override
  String get outgoing => 'Исходящие';

  @override
  String get supplier => 'Поставщик';

  @override
  String get customer => 'Клиент';

  @override
  String get eta => 'Ожидаемое время';

  @override
  String get due => 'Срок';

  @override
  String get productDetails => 'Детали товара';

  @override
  String get sku => 'SKU';

  @override
  String get location => 'Местоположение';

  @override
  String get pcs => 'шт';

  @override
  String get kg => 'кг';

  @override
  String get contractDetails => 'Детали договора';

  @override
  String get contractCode => 'Код контракта';

  @override
  String get active => 'Активный';

  @override
  String get inactive => 'Неактивный';

  @override
  String get dateOfContract => 'Дата контракта';

  @override
  String get termOfContract => 'Срок контракта';

  @override
  String get contractSum => 'Сумма контракта';

  @override
  String get typeOfContract => 'Тип контракта';

  @override
  String get clientCode => 'Код клиента';

  @override
  String get organization => 'Организация';

  @override
  String get responsiblePerson => 'Ответственное лицо';

  @override
  String get phone => 'Телефон';

  @override
  String get address => 'Адрес';

  @override
  String get inn => 'ИНН';

  @override
  String get region => 'Регион';

  @override
  String get district => 'Район';

  @override
  String get signboard => 'Вывеска';

  @override
  String get referencePoint => 'Ориентир';

  @override
  String get tradePointType => 'Тип торговой точки';

  @override
  String get ownerName => 'Владелец';

  @override
  String get responsiblePersonPhone => 'Телефон ответственного лица';

  @override
  String get visit => 'Посещение';

  @override
  String get visitClient => 'Посетить клиента';

  @override
  String get createOrder => 'Создать заказ';

  @override
  String get unplannedOrder => 'Незапланированный заказ';

  @override
  String get viewContracts => 'Просмотреть контракты';

  @override
  String get refusal => 'Отказ';

  @override
  String get route => 'Маршрут';

  @override
  String get refusalReason => 'Причина отказа';

  @override
  String get selectReason => 'Выберите причину отказа';

  @override
  String get other => 'Другое';

  @override
  String get specifyReason => 'Укажите причину';

  @override
  String get send => 'Отправить';

  @override
  String get visitReported => 'Посещение отмечено';

  @override
  String get orderCreated => 'Заказ создан';

  @override
  String get contractViewed => 'Контракты просмотрены';

  @override
  String get refusalSent => 'Отказ отправлен';

  @override
  String get locationPermission => 'Разрешение на местоположение';

  @override
  String get locationPermissionRequired => 'Для этой функции требуется разрешение на местоположение';

  @override
  String get requestPermission => 'Запросить разрешение';

  @override
  String get locationServicesDisabled => 'Службы определения местоположения отключены';

  @override
  String get enableLocationServices => 'Пожалуйста, включите службы определения местоположения';

  @override
  String get reportsMenu => 'Меню отчетов';

  @override
  String get selectReport => 'Выберите отчет';

  @override
  String get generateReport => 'Создать отчет';

  @override
  String get exportReport => 'Экспортировать отчет';

  @override
  String get reportGenerated => 'Отчет успешно создан';

  @override
  String get reportGenerationError => 'Ошибка создания отчета';

  @override
  String get akbSum => 'Сумма AKB';

  @override
  String get akbClient => 'Клиенты AKB';

  @override
  String get akbProduct => 'Продукты AKB';

  @override
  String get monthlyReport => 'Месячный отчет';

  @override
  String get dailyReport => 'Дневной отчет';

  @override
  String get salesReport => 'Отчет о продажах';

  @override
  String get inventoryReport => 'Инвентаризационный отчет';

  @override
  String get financialReport => 'Финансовый отчет';

  @override
  String get kpiReport => 'Отчет KPI';

  @override
  String get cash => 'Наличные';

  @override
  String get nonCash => 'Безналичные';

  @override
  String get totalOrders => 'Всего заказов';

  @override
  String get visitedPoints => 'Посещенные точки';

  @override
  String get totalRevenue => 'Общий доход';

  @override
  String get averageOrder => 'Средний заказ';

  @override
  String get growthRate => 'Темп роста';

  @override
  String get efficiency => 'Эффективность';

  @override
  String get performance => 'Производительность';

  @override
  String get targets => 'Цели';

  @override
  String get achievements => 'Достижения';

  @override
  String get plan => 'План';

  @override
  String get fact => 'Факт';

  @override
  String get percentage => 'Процент';

  @override
  String get amount => 'Сумма';

  @override
  String get date => 'Дата';

  @override
  String get time => 'Время';

  @override
  String get duration => 'Продолжительность';

  @override
  String get distance => 'Расстояние';

  @override
  String get speed => 'Скорость';

  @override
  String get temperature => 'Температура';

  @override
  String get humidity => 'Влажность';

  @override
  String get pressure => 'Давление';

  @override
  String get wind => 'Ветер';

  @override
  String get weather => 'Погода';

  @override
  String get forecast => 'Прогноз';

  @override
  String get today => 'Сегодня';

  @override
  String get tomorrow => 'Завтра';

  @override
  String get yesterday => 'Вчера';

  @override
  String get thisWeek => 'Эта неделя';

  @override
  String get thisMonth => 'Этот месяц';

  @override
  String get thisYear => 'Этот год';

  @override
  String get lastWeek => 'Прошлая неделя';

  @override
  String get lastMonth => 'Прошлый месяц';

  @override
  String get lastYear => 'Прошлый год';

  @override
  String get custom => 'Пользовательский';

  @override
  String get from => 'От';

  @override
  String get to => 'До';

  @override
  String get start => 'Начало';

  @override
  String get end => 'Конец';

  @override
  String get beginning => 'Начало';

  @override
  String get finish => 'Завершить';

  @override
  String get open => 'Открыть';

  @override
  String get closed => 'Закрыть';

  @override
  String get available => 'Доступно';

  @override
  String get unavailable => 'Недоступно';

  @override
  String get enabled => 'Включено';

  @override
  String get disabled => 'Отключено';

  @override
  String get on => 'Вкл';

  @override
  String get off => 'Выкл';

  @override
  String get booleanTrue => 'Истина';

  @override
  String get booleanFalse => 'Ложь';

  @override
  String get interfaceSettings => 'Настройки интерфейса';

  @override
  String get languageChanged => 'Язык успешно изменен';

  @override
  String get restartRequired => 'Перезапустите приложение для применения изменений языка';

  @override
  String get currentLanguage => 'Текущий язык';

  @override
  String get availableLanguages => 'Доступные языки';

  @override
  String get changeLanguage => 'Изменить язык';

  @override
  String get languageSelection => 'Выбор языка';

  @override
  String get confirmLanguageChange => 'Вы уверены, что хотите изменить язык?';

  @override
  String get languageChangeWarning => 'Изменение языка перезапустит приложение';

  @override
  String get success => 'Успех';

  @override
  String get prices => 'Цены';

  @override
  String get businessRegions => 'Бизнес Регионы';

  @override
  String get permissions => 'Разрешения';

  @override
  String get apply => 'Применить';

  @override
  String get appearance => 'Внешний вид';

  @override
  String get failure => 'Неудача';

  @override
  String get warning => 'Предупреждение';

  @override
  String get info => 'Информация';

  @override
  String get debug => 'Отладка';

  @override
  String get trace => 'Трассировка';

  @override
  String get fatal => 'Фатальный';

  @override
  String get critical => 'Критический';

  @override
  String get emergency => 'Чрезвычайная ситуация';

  @override
  String get notice => 'Уведомление';

  @override
  String get alert => 'Тревога';

  @override
  String get agentPermissions => 'Разрешения агента';

  @override
  String get userPermissionsAndVisitSteps => 'Разрешения пользователя и этапы посещения';

  @override
  String get dataValidation => 'Проверка данных';

  @override
  String get visitManagement => 'Управление посещениями';

  @override
  String get visitSteps => 'Этапы посещения';

  @override
  String get userCodeNotFound => 'Код пользователя не найден';

  @override
  String get errorLoadingPermissions => 'Ошибка загрузки разрешений';

  @override
  String get skipTINDuplicateCheck => 'Пропустить проверку дубликатов ИНН';

  @override
  String get allowCreationWithoutTIN => 'Разрешить создание без ИНН';

  @override
  String get allowCreatingPointOfSale => 'Разрешить создание точки продаж';

  @override
  String get strictSequence => 'Строгая последовательность';

  @override
  String get plannedRoute => 'Запланированный маршрут';

  @override
  String get general => 'Общее';

  @override
  String get mandatoryExecution => 'Обязательное выполнение';

  @override
  String get optional => 'Необязательный';

  @override
  String get permissionsDataNotAvailable => 'Данные разрешений недоступны';

  @override
  String get languageChangeError => 'Ошибка изменения языка';

  @override
  String get customers => 'Клиенты';

  @override
  String get debitCredit => 'Дебет-Кредит';

  @override
  String get products => 'Товары';

  @override
  String get dbView => 'DB View';

  @override
  String get darkMode => 'Темный режим';

  @override
  String get kpiDataUpdateError => 'Ошибка обновления данных KPI';

  @override
  String get onlineModeReturn => 'Вернуться в онлайн режим';

  @override
  String get onlineModeReturnConfirm => 'Хотите проверить подключение к интернету и серверу и вернуться в онлайн режим?';

  @override
  String get serverUrlNotFound => 'URL сервера не найден';

  @override
  String get serverUrl => 'URL сервера';

  @override
  String get connectionError => 'Ошибка подключения';

  @override
  String get menu => 'Меню';

  @override
  String get offline => 'Офлайн';

  @override
  String get refresh => 'Обновить';

  @override
  String get okb => 'OKB';

  @override
  String get akbPlan => 'План AKB';

  @override
  String get akbFact => 'АКБ факт';

  @override
  String get forecastPercentOfFact => 'Прогноз % от факта';

  @override
  String get totalPlan => 'Общий план';

  @override
  String get totalFact => 'Общий факт';

  @override
  String get charts => 'Графики';

  @override
  String get akbProgress => 'Прогресс AKB';

  @override
  String get planVsFact => 'План vs Факт';

  @override
  String get planCompletion => 'Выполнение плана';

  @override
  String get factVsRemaining => 'Факт vs Остаток';

  @override
  String get forecastTrend => 'Тренд прогноза';

  @override
  String get fromFactToForecast => 'От факта к прогнозу';

  @override
  String get remaining => 'Остаток';

  @override
  String get onTrack => 'По плану';

  @override
  String get atRisk => 'Под угрозой';

  @override
  String get insights => 'Аналитика';

  @override
  String get autoGeneratedHighlights => 'Автоматически созданные highlights';

  @override
  String get completion => 'Выполнение';

  @override
  String get gapToPlan => 'Разрыв с планом';

  @override
  String get akbGap => 'Разрыв AKB';

  @override
  String get forecastVsPlan => 'Прогноз vs План';

  @override
  String get todayPerformance => 'Производительность сегодня';

  @override
  String get planExecution => 'Выполнение плана';

  @override
  String get rememberMe => 'Запомнить меня';

  @override
  String get databaseView => 'Просмотр базы данных';

  @override
  String get preferenceKey => 'Ключ настройки';

  @override
  String get value => 'Значение';

  @override
  String get id => 'ID';

  @override
  String get code => 'Код';

  @override
  String get name => 'Имя';

  @override
  String get role => 'Роль';

  @override
  String get warehouseCode => 'Код склада';

  @override
  String get codeProject => 'Код проекта';

  @override
  String get baseUrl => 'Базовый URL';

  @override
  String get telegramId => 'Telegram ID';

  @override
  String get chatId => 'Chat ID';

  @override
  String get topicId => 'Topic ID';

  @override
  String get createdAt => 'Создано';

  @override
  String updatedAt(String date, String time) {
    return 'Обновлено: $date $time';
  }

  @override
  String get totalPercent => 'Общий %';

  @override
  String get forecastPercent => 'Прогноз %';

  @override
  String get akbPercent => '% AKB';

  @override
  String get updateDate => 'Дата обновления';

  @override
  String get exit => 'Выход';

  @override
  String get confirmExit => 'Вы действительно хотите выйти?';

  @override
  String get contactPerson => 'Контакт';

  @override
  String get lastVisitDate => 'Последний визит';

  @override
  String get hasOrders => 'Есть заказы';

  @override
  String get hasContracts => 'Есть контракты';

  @override
  String get isVisited => 'Посещен';

  @override
  String get hasContract => 'Есть контракт';

  @override
  String get coordinates => 'Координаты';

  @override
  String get creditLimit => 'Кредитный лимит';

  @override
  String get accumulatedCredit => 'Накопленный кредит';

  @override
  String get codeRegion => 'Код региона';

  @override
  String get maps => 'Карты';

  @override
  String get selectDefaultMap => 'Выберите карту по умолчанию';

  @override
  String get googleMaps => 'Google Карты';

  @override
  String get yandexMaps => 'Yandex Карты';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get mapProvider => 'Провайдер карт';

  @override
  String get apiKey => 'API ключ';

  @override
  String get configured => 'Настроено';

  @override
  String get notConfigured => 'Не настроено';

  @override
  String get mapSettings => 'Настройки карт';

  @override
  String get defaultMapChanged => 'Карта по умолчанию успешно изменена';

  @override
  String get currentMapProvider => 'Текущий провайдер карт';

  @override
  String get availableMaps => 'Доступные карты';

  @override
  String get mapConfiguration => 'Конфигурация карт';

  @override
  String get visitProgress => 'Прогресс визита';

  @override
  String get visitStepNumber => 'Шаг посещения';

  @override
  String get skipped => 'Пропущено';

  @override
  String get current => 'Текущий';

  @override
  String get mandatory => 'Обязательный';

  @override
  String get completedAt => 'Завершено в';

  @override
  String get skippedAt => 'Пропущено в';

  @override
  String get notes => 'Заметки';

  @override
  String get reason => 'Причина';

  @override
  String get previousStepsRequired => 'Необходимо завершить предыдущие шаги';

  @override
  String get completeStep => 'Завершить шаг';

  @override
  String get skipStep => 'Пропустить шаг';

  @override
  String get confirmCompletion => 'Подтвердите завершение';

  @override
  String get stepCompletedSuccessfully => 'Шаг успешно завершен';

  @override
  String get stepSkippedSuccessfully => 'Шаг успешно пропущен';

  @override
  String get visitCompletedSuccessfully => 'Посещение успешно завершено!';

  @override
  String get finishVisit => 'Завершить посещение';

  @override
  String get allRequiredStepsMustBeCompleted => 'Все обязательные шаги должны быть завершены';

  @override
  String get visitInfo => 'Информация о посещении';

  @override
  String get client => 'Клиент';

  @override
  String get totalSteps => 'Всего шагов';

  @override
  String get requiredSteps => 'Обязательные шаги';

  @override
  String get unknownState => 'Неизвестное состояние';

  @override
  String get cancelCompletion => 'Отменить завершение';

  @override
  String get confirmSkip => 'Подтвердить пропуск';

  @override
  String get enterNotesOptional => 'Введите заметки (необязательно)';

  @override
  String get enterSkipReason => 'Введите причину пропуска';

  @override
  String get stepCannotBeSkipped => 'Этот шаг нельзя пропустить';

  @override
  String get allRequiredStepsCompleted => 'Все обязательные шаги завершены';

  @override
  String get soapRequest => 'SOAP запрос';

  @override
  String get soapRequestCopied => 'SOAP запрос скопирован';

  @override
  String get copy => 'Копировать';

  @override
  String get orderNotFound => 'Заказ не найден';

  @override
  String get readOnly => 'Только просмотр';

  @override
  String get pageUnderDevelopment => 'Страница в разработке';

  @override
  String get stepCompletedReadOnly => 'Этот шаг завершен. Режим только чтения.';

  @override
  String get stepTypeNotImplemented => 'Для этого типа шага страница еще не реализована.';

  @override
  String get orderDetailsNavigationErrorPrefix => 'Ошибка при открытии деталей заказа';

  @override
  String get errorOccurredPrefix => 'Произошла ошибка';

  @override
  String get stepErrorPrefix => 'Ошибка шага';

  @override
  String get visitFinishErrorPrefix => 'Ошибка при завершении визита';

  @override
  String get stepsCount => 'шагов';

  @override
  String get visitFinishing => 'Завершение визита...';

  @override
  String orderNumber(String number) {
    return 'Заказ № $number';
  }

  @override
  String get dataSaveError => 'Ошибка сохранения данных';

  @override
  String get saveErrorPrefix => 'Ошибка сохранения';

  @override
  String get dataLoadError => 'Ошибка загрузки данных';

  @override
  String get productsLoadError => 'Ошибка загрузки продуктов';

  @override
  String get settingsUpdateError => 'Ошибка обновления настроек';

  @override
  String get clearOrder => 'Очистить заказ';

  @override
  String get suggestedOrders => 'Рекомендуемые заказы';

  @override
  String get productSelectionError => 'Ошибка перехода к выбору продуктов';

  @override
  String get orderDataCleared => 'Данные заказа очищены';

  @override
  String get dataClearError => 'Ошибка очистки данных';

  @override
  String get orderCreationError => 'Ошибка создания заказа';

  @override
  String get deliveryDateChangedSuccess => 'Дата доставки успешно изменена';

  @override
  String get dateChangeError => 'Ошибка изменения даты';

  @override
  String get clearOrderConfirmTitle => 'Очистить заказ';

  @override
  String get clearOrderConfirmMessage => 'Все выбранные продукты и связанные данные будут удалены. Настройки будут сохранены. Продолжить?';

  @override
  String get clientDataLoadError => 'Ошибка загрузки данных клиента';

  @override
  String get locationNotAvailable => 'Данные о местоположении недоступны. Посещение невозможно.';

  @override
  String get visitCompletedFor => 'визит успешно завершен для';

  @override
  String get contractsPageError => 'Ошибка перехода на страницу контрактов';

  @override
  String get loadingClientImages => 'Загрузка изображений клиента...';

  @override
  String get clientImagesLoaded => 'Изображения клиента загружены';

  @override
  String get imageLoadError => 'Ошибка загрузки изображения';

  @override
  String get disableVisitTodayFilter => 'Отключить фильтр сегодняшних посещений';

  @override
  String get showVisitTodayOnly => 'Показать только клиентов с посещением сегодня';

  @override
  String get newClient => 'Новый клиент';

  @override
  String get orderHistory => 'История заказов';

  @override
  String get tradingPointsNotFound => 'Торговые точки не найдены';

  @override
  String get clientCount => 'Количество клиентов';

  @override
  String get manageClientImages => 'Управление изображениями клиента';

  @override
  String ordersCount(int count) {
    return '$count заказов';
  }

  @override
  String get orderNumberPrefix => 'Заказ №';

  @override
  String get viewOrder => 'Просмотр заказа';

  @override
  String get clientOrdersFor => 'заказы клиента';

  @override
  String get locationServicesDisabledSortingNotWork => 'Службы определения местоположения отключены. Сортировка по расстоянию не будет работать.';

  @override
  String get userDataNotFound => 'Данные пользователя не найдены';

  @override
  String get phoneNumberNotSpecified => 'Номер телефона не указан';

  @override
  String get phoneCallFailed => 'Телефонный звонок не удался';

  @override
  String get connectedToInternet => 'Подключено к интернету';

  @override
  String get offlineModeActive => 'Офлайн режим';

  @override
  String get refusalReasonSent => 'Причина отказа отправлена для';

  @override
  String get viewPanel => 'Панель просмотра';

  @override
  String get sortByDistanceRequiresPermission => 'Для сортировки по расстоянию требуется разрешение на местоположение';

  @override
  String get sortByDistance => 'Сортировка по расстоянию';

  @override
  String get sortAlphabeticalAZ => 'По алфавиту (А-Я)';

  @override
  String get sortAlphabeticalZA => 'По алфавиту (Я-А)';

  @override
  String get serverSelected => 'сервер выбран';

  @override
  String get noInternetNoSavedUser => 'Нет интернета и сохраненные данные пользователя не найдены';

  @override
  String get noInternetLoginMismatch => 'Нет интернета и введенный логин не совпадает с сохраненным';

  @override
  String get savedUserServerMismatch => 'Сохраненные данные пользователя не соответствуют текущему серверу. Пожалуйста, измените сервер.';

  @override
  String get noInternetUserNotInDb => 'Нет интернета и данные пользователя не найдены в базе или не совпадают';

  @override
  String get offlineLoginError => 'Ошибка офлайн входа';

  @override
  String get noInternetAvailable => 'Интернет недоступен';

  @override
  String get offlineModeQuestion => 'Хотите войти в офлайн режим как';

  @override
  String get offlineModeDescription => 'В офлайн режиме вы можете работать с существующими данными, но не можете загружать новые.';

  @override
  String get offlineLogin => 'Офлайн вход';

  @override
  String get dataUpdating => 'Обновление данных...';

  @override
  String get errorPrefix => 'Ошибка';

  @override
  String get cacheDataUsed => 'Используются кэшированные данные';

  @override
  String get loginSuccessful => 'Вход выполнен успешно!';

  @override
  String get onlineLoginError => 'Ошибка обработки онлайн входа';

  @override
  String get unknownUserRole => 'Неизвестная роль пользователя';

  @override
  String get enterField => 'Введите';

  @override
  String get imageServiceNotAvailable => 'Сервис изображений недоступен';

  @override
  String get searchHint => 'Поиск...';

  @override
  String get pullToRefresh => 'Потяните для обновления';

  @override
  String get pullToRefreshOrSyncData => 'Если обновление не работает, используйте опцию \'синхронизировать все данные\' в меню настроек';

  @override
  String get checkingDistance => 'Проверка расстояния...';

  @override
  String get distanceRestrictionError => 'Вы слишком далеко от клиента. Подойдите ближе для завершения визита.';

  @override
  String get cancelVisit => 'Отменить визит';

  @override
  String get cancelVisitConfirmation => 'Вы уверены, что хотите отменить визит? Весь прогресс будет потерян.';

  @override
  String get syncStatusIdle => 'Ожидание';

  @override
  String get syncStatusProducts => 'Синхронизация товаров';

  @override
  String get syncStatusBalances => 'Синхронизация остатков';

  @override
  String get syncStatusOrders => 'Синхронизация заказов';

  @override
  String get syncStatusCompleted => 'Синхронизация завершена';

  @override
  String get syncStatusError => 'Ошибка синхронизации';

  @override
  String get syncInProgress => 'Синхронизация...';

  @override
  String get syncErrorUserNotFound => 'Код пользователя не найден';

  @override
  String get syncAlreadyInProgress => 'Синхронизация уже выполняется';

  @override
  String get syncCompleted => 'Данные успешно обновлены';

  @override
  String get clientBalance => 'Баланс клиента';

  @override
  String get clientBalanceDetails => 'Детали баланса';

  @override
  String clientIsDebtor(String amount) {
    return 'Клиент должник. Общий долг: $amount сум';
  }

  @override
  String clientHasOverpayment(String amount) {
    return 'Клиент переплатил. Переплата: $amount сум';
  }

  @override
  String get balanceIsZero => 'Баланс равен нулю';

  @override
  String get totalDebt => 'Общий долг';

  @override
  String get totalPayment => 'Общая оплата';

  @override
  String get totalOrder => 'Общий заказ';

  @override
  String unpaidOrders(int count) {
    return '$count неоплачено';
  }

  @override
  String overdueOrders(int count) {
    return '$count просрочено';
  }

  @override
  String get balanceStatus => 'Статус баланса';

  @override
  String get contractsTab => 'Договоры';

  @override
  String get ordersTab => 'Заказы';

  @override
  String get overviewTab => 'Обзор';

  @override
  String get paymentAndDebtRatio => 'Соотношение оплат и долгов';

  @override
  String get orderAndPaymentRatio => 'Соотношение заказов и оплат';

  @override
  String get paid => 'Оплачено';

  @override
  String get partiallyPaid => 'Частично оплачено';

  @override
  String get unpaid => 'Не оплачено';

  @override
  String overdueDays(int days) {
    return 'Просрочено $days дней';
  }

  @override
  String refreshAfterSeconds(int seconds) {
    return 'Можно обновить через $seconds секунд';
  }

  @override
  String balanceUpdated(String date) {
    return 'Обновлено';
  }

  @override
  String get noBalanceData => 'Данные баланса не найдены';

  @override
  String get balanceLoadError => 'Ошибка загрузки баланса';

  @override
  String get balanceServiceNotAvailable => 'Сервис баланса недоступен';

  @override
  String get clientInnNotFound => 'ИНН клиента не найден';

  @override
  String get statistics => 'Статистика';

  @override
  String contractsCount(int count) {
    return '$count контрактов';
  }

  @override
  String get contract => 'Договор';

  @override
  String get order => 'Заказ';

  @override
  String get overpayment => 'Переплата';

  @override
  String get debt => 'Задолженность';

  @override
  String get debtAndOverpaymentRatio => 'Соотношение долга и переплаты';

  @override
  String get debtor => 'Должник';

  @override
  String get excess => 'Излишек';

  @override
  String get orderAmountLabel => 'Заказ';

  @override
  String get paidAmountLabel => 'Оплачено';

  @override
  String get debtLabel => 'Долг';

  @override
  String get excessLabel => 'Излишек';

  @override
  String get ordersStatus => 'Статус заказов';

  @override
  String get clearBalanceCache => 'Очистить кэш баланса';

  @override
  String get clearBalanceCacheConfirm => 'Все данные баланса клиентов будут удалены. Они будут перезагружены при следующем просмотре баланса.';

  @override
  String get balanceCacheCleared => 'Кэш баланса очищен';

  @override
  String get fakturaNetworkError => 'Ошибка сети';

  @override
  String get tradePointTypesEmpty => 'Список типов торговых точек пуст. Пожалуйста, сначала добавьте торговые точки.';

  @override
  String get tradePointTypesLoadError => 'Ошибка загрузки типов торговых точек.';

  @override
  String get timeoutError => 'Время запроса истекло. Попробуйте снова.';

  @override
  String get dataNotFound => 'Данные не найдены.';

  @override
  String get invalidDataError => 'Получены некорректные данные.';

  @override
  String get unknownBalanceError => 'Произошла неизвестная ошибка.';

  @override
  String get retryButton => 'Повторить';

  @override
  String balanceFor(String name) {
    return 'Баланс: $name';
  }

  @override
  String get overviewTabShort => 'Обзор';

  @override
  String get contractsTabShort => 'Договоры';

  @override
  String get ordersTabShort => 'Заказы';

  @override
  String get totalOrdered => 'Всего заказов';

  @override
  String get totalPaid => 'Всего оплачено';

  @override
  String get contractsCountLabel => 'Количество договоров';

  @override
  String get ordersCountLabel => 'Количество заказов';

  @override
  String get unpaidOrdersLabel => 'Неоплаченные заказы';

  @override
  String get partiallyPaidLabel => 'Частично оплачено';

  @override
  String get overdueLabel => 'Просрочено';

  @override
  String contractWithCode(String code) {
    return 'Договор: $code';
  }

  @override
  String get totalSummary => 'Всего';

  @override
  String get paidSummary => 'Оплачено';

  @override
  String get partialSummary => 'Частично';

  @override
  String get unpaidSummary => 'Не оплачено';

  @override
  String get excessSummary => 'Излишек';

  @override
  String ordersWithCount(int count) {
    return 'Заказы ($count)';
  }

  @override
  String overpaymentWithCount(int count) {
    return 'Переплаты ($count)';
  }

  @override
  String orderWithNumber(String number) {
    return 'Заказ: $number';
  }

  @override
  String get noDataAvailable => 'Нет данных';

  @override
  String get noContractsFound => 'Контракты не найдены';

  @override
  String get noOrdersFound => 'Заказы не найдены';

  @override
  String get paidLabel => 'Оплачено';

  @override
  String get debtLabelChart => 'Долг';

  @override
  String get paymentLabel => 'Оплата';

  @override
  String get partialLabel => 'Частично';

  @override
  String get unpaidLabel => 'Неоплачено';

  @override
  String countItems(int count) {
    return '$count шт';
  }

  @override
  String get contractDialog => 'Контракт';

  @override
  String codeLabel(String code) {
    return 'Код: $code';
  }

  @override
  String projectLabel(String project) {
    return 'Проект: $project';
  }

  @override
  String idLabel(String id) {
    return 'ID: $id';
  }

  @override
  String get closeButton => 'Закрыть';

  @override
  String paymentAmount(String amount) {
    return 'Оплата: $amount';
  }

  @override
  String debtAmount(String amount) {
    return 'Долг: $amount';
  }

  @override
  String get securityCheck => 'Проверка безопасности';

  @override
  String get securityCheckLoading => 'Загрузка...';

  @override
  String get securityCheckVerifying => 'Проверка безопасности...';

  @override
  String get securityCheckAllowed => 'Доступ разрешен';

  @override
  String get securityCheckBlocked => 'Доступ запрещен';

  @override
  String get securityCheckError => 'Произошла ошибка';

  @override
  String get securityCheckLogin => 'Вход в систему...';

  @override
  String get accessDenied => 'Доступ запрещен';

  @override
  String get accessDeniedMessage => 'Ваш доступ к этому приложению заблокирован.';

  @override
  String get accessBlockedReasonAccountBound => 'Этот аккаунт привязан к другому устройству';

  @override
  String get accessBlockedReasonDeviceBound => 'На этом устройстве есть другой аккаунт';

  @override
  String get accessBlockedReasonHighRisk => 'Устройство не соответствует требованиям безопасности';

  @override
  String get accessBlockedReasonPolicyViolation => 'Нарушение политики безопасности';

  @override
  String get accessBlockedReasonUnknown => 'Неизвестная причина';

  @override
  String get retryCheck => 'Повторить проверку';

  @override
  String get contactSupportTeam => 'Связаться с поддержкой';

  @override
  String get logoutConfirmTitle => 'Выход';

  @override
  String get logoutConfirmMessage => 'Вы действительно хотите выйти из системы?';

  @override
  String get newContract => 'Новый договор';

  @override
  String get createContract => 'Создать контракт';

  @override
  String get createContractTitle => 'Новый контракт';

  @override
  String get createContractSubtitle => 'Заполните все поля';

  @override
  String get contractCreatedSuccess => 'Контракт успешно создан';

  @override
  String get contractCreatedError => 'Ошибка создания контракта';

  @override
  String get contractListRefreshed => 'Список контрактов обновлен';

  @override
  String get selectClient => 'Выберите клиента';

  @override
  String get selectContractType => 'Выберите тип контракта';

  @override
  String get contractTypesNotFound => 'Типы контрактов не найдены';

  @override
  String get reloadContractTypes => 'Перезагрузить';

  @override
  String get autoFilled => 'Автозаполнено';

  @override
  String get referenceNumber => 'Номер справки';

  @override
  String get referenceTermDate => 'Срок действия';

  @override
  String get certificateNumber => 'Номер сертификата';

  @override
  String get certificateTermDate => 'Срок сертификата';

  @override
  String get certificateUnlimited => 'Сертификат бессрочный';

  @override
  String get passportNumber => 'Номер паспорта';

  @override
  String get passportTermDate => 'Срок паспорта';

  @override
  String get districtName => 'Название района';

  @override
  String get districtCode => 'Код района';

  @override
  String get documentInfo => 'Информация о документах';

  @override
  String get regionInfo => 'Информация о регионе';

  @override
  String get creatingContract => 'Создание...';

  @override
  String get networkError => 'Network error';

  @override
  String get serverTimeout => 'Время подключения к серверу истекло';

  @override
  String get noInternetConnection => 'Нет подключения к интернету. Пожалуйста, подключитесь к интернету';

  @override
  String get createClientTitle => 'Новый клиент';

  @override
  String get createClientBasicInfo => 'Основная информация';

  @override
  String get createClientContactInfo => 'Контактная информация';

  @override
  String get createClientAddressInfo => 'Адрес';

  @override
  String get createClientBankInfo => 'Банковские реквизиты (необязательно)';

  @override
  String get createClientClientName => 'Название клиента';

  @override
  String get createClientClientNameHint => 'Название магазина или компании';

  @override
  String get createClientSignboard => 'Вывеска';

  @override
  String get createClientSignboardHint => 'Внешнее название';

  @override
  String get createClientInn => 'ИНН';

  @override
  String get createClientInnHint => '9 или 14 цифр';

  @override
  String get createClientTradePointType => 'Тип торговой точки';

  @override
  String get createClientSelectTradePointType => 'Выберите тип торговой точки';

  @override
  String get createClientRegion => 'Регион';

  @override
  String get createClientSelectRegion => 'Выберите регион';

  @override
  String get createClientContactPerson => 'Контактное лицо';

  @override
  String get createClientContactPersonHint => 'Имя ответственного лица';

  @override
  String get createClientPhone => 'Номер телефона';

  @override
  String get createClientPhoneHint => '+998 XX XXX XX XX';

  @override
  String get createClientResponsiblePhone => 'Телефон ответственного лица';

  @override
  String get createClientResponsiblePhoneHint => 'Дополнительный телефон (необязательно)';

  @override
  String get createClientAddress => 'Адрес';

  @override
  String get createClientAddressHint => 'Полный адрес';

  @override
  String get createClientDeliveryAddress => 'Адрес доставки';

  @override
  String get createClientDeliveryAddressHint => 'Если отличается (необязательно)';

  @override
  String get createClientLandmark => 'Ориентир';

  @override
  String get createClientLandmarkHint => 'Ближайшее известное место';

  @override
  String get createClientDirector => 'Директор';

  @override
  String get createClientDirectorHint => 'Ф.И.О';

  @override
  String get createClientMfo => 'МФО';

  @override
  String get createClientMfoHint => '5-значный код банка';

  @override
  String get createClientBankAccount => 'Расчетный счет';

  @override
  String get createClientBankAccountHint => '20 цифр';

  @override
  String get createClientLocation => 'Местоположение';

  @override
  String get createClientLocationDetecting => 'Определение...';

  @override
  String get createClientLocationNotFound => 'Местоположение не найдено';

  @override
  String get createClientRefreshLocation => 'Обновить';

  @override
  String get createClientSubmit => 'Создать клиента';

  @override
  String get createClientCreating => 'Создание...';

  @override
  String get createClientSuccess => 'Клиент создан!';

  @override
  String get createClientSyncing => 'Синхронизация данных...';

  @override
  String get createClientCode => 'Код';

  @override
  String get createClientTerritoryWarningTitle => 'Важное замечание!';

  @override
  String get createClientTerritoryWarningMessage => 'Создание клиента должно выполняться в пределах его торговой территории. В противном случае возможны проблемы при создании заказа и его доставке.';

  @override
  String get createClientAutoFilledHint => 'Автозаполнено. При необходимости измените.';

  @override
  String get createClientAddressDetected => 'Адрес определен и автозаполнен';

  @override
  String get createClientSelectRegionError => 'Пожалуйста, выберите регион';

  @override
  String get createClientSelectTypeError => 'Пожалуйста, выберите тип торговой точки';

  @override
  String get createClientLocationError => 'Данные о местоположении не найдены';

  @override
  String get createClientUserCodeError => 'Код пользователя не найден';

  @override
  String get createClientUnknownError => 'Неизвестная ошибка';

  @override
  String get labelTradingPointType => 'Тип торговой точки';

  @override
  String get labelBusinessRegion => 'Бизнес регион';

  @override
  String get labelStatus => 'Статус';

  @override
  String get labelDateRange => 'Диапазон дат';

  @override
  String get labelClients => 'Клиенты';

  @override
  String get refusalReasonTitle => 'Причина отказа';

  @override
  String selectRefusalReasonFor(String name) {
    return 'Выберите причину отказа для $name:';
  }

  @override
  String businessRegionLabel(String region) {
    return 'Бизнес регион: $region';
  }

  @override
  String contactLabel(String contact) {
    return 'Контакт: $contact';
  }

  @override
  String innLabel(String inn) {
    return 'ИНН';
  }

  @override
  String ownerLabel(String owner) {
    return 'Владелец: $owner';
  }

  @override
  String responsiblePersonLabel(String responsible) {
    return 'Ответственный: $responsible';
  }

  @override
  String responsiblePersonPhoneLabel(String phone) {
    return 'Телефон ответственного: $phone';
  }

  @override
  String typeLabel(String type) {
    return 'Тип: $type';
  }

  @override
  String regionDistrictLabel(String region, String district) {
    return '$region, $district';
  }

  @override
  String signboardLabel(String signboard) {
    return 'Вывеска: $signboard';
  }

  @override
  String landmarkLabel(String landmark) {
    return 'Ориентир: $landmark';
  }

  @override
  String get waitingForLocation => 'Ожидание данных о местоположении...';

  @override
  String get visitCompletedTitle => 'Посещение завершено';

  @override
  String stepsCompletedCount(int count) {
    return '$count шагов завершено';
  }

  @override
  String get returnToHome => 'Вернуться на главную';

  @override
  String completedAtLabel(String date) {
    return 'Завершено: $date';
  }

  @override
  String orderCaption(String id) {
    return 'Заказ $id';
  }

  @override
  String maxQuantityMessage(int stock) {
    return 'Максимальное количество: $stock шт';
  }

  @override
  String get productPriceZeroError => 'Нельзя добавить товар с ценой 0 или меньше';

  @override
  String get quantityUpdateError => 'Ошибка обновления количества';

  @override
  String get confirmationError => 'Ошибка подтверждения выбора';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get productSelectionTitle => 'Выбор товара';

  @override
  String productsSelectedCount(int count) {
    return '$count товаров выбрано';
  }

  @override
  String get noProductsAvailable => 'Товары отсутствуют';

  @override
  String get clear => 'Очистить';

  @override
  String totalProductsCount(int count) {
    return 'Всего товаров: $count';
  }

  @override
  String totalAmount(String amount) {
    return 'Общая сумма: $amount';
  }

  @override
  String errorOccurred(String error) {
    return 'Произошла ошибка';
  }

  @override
  String get cameraPermissionDenied => 'Разрешение на камеру не предоставлено';

  @override
  String cameraInitError(String error) {
    return 'Ошибка инициализации камеры: $error';
  }

  @override
  String cameraError(String error) {
    return 'Ошибка камеры: $error';
  }

  @override
  String get cameraInUseMessage => 'Камера используется другим приложением. Попытка переподключения...';

  @override
  String get imageSavedSuccessfully => 'Изображение успешно сохранено';

  @override
  String imageSaveError(String error) {
    return 'Ошибка сохранения изображения: $error';
  }

  @override
  String get cameraNotReady => 'Камера не готова';

  @override
  String get cameraNotAvailable => 'Камера недоступна или не работает';

  @override
  String imageCounter(int current, int total) {
    return '$current / $total';
  }

  @override
  String get imageCapturedSuccessfully => 'Изображение успешно получено';

  @override
  String imageCaptureError(String error) {
    return 'Ошибка получения изображения: $error';
  }

  @override
  String get xmlRequestLabel => 'XML запрос';

  @override
  String get xmlCopied => 'XML скопирован';

  @override
  String get enterNumberHint => 'Введите номер';

  @override
  String get balanceStatusTitle => 'Статус баланса';

  @override
  String productNotFoundMessage(String code) {
    return 'Информация о товаре не найдена: $code';
  }

  @override
  String get clientCreatedSuccessfully => 'Новый клиент успешно создан!';

  @override
  String get callClientTitle => 'Позвонить клиенту';

  @override
  String callClientConfirmation(String phone) {
    return 'Вы хотите позвонить клиенту?\n$phone';
  }

  @override
  String get dialerNotAvailable => 'Звонок недоступен';

  @override
  String get updateCoordinatesNotImplemented => 'Обновление координат - функция будет реализована';

  @override
  String get osmNotLoadedFallback => 'OpenStreetMap не загружен. Используется Google Maps.';

  @override
  String get confirmLocationTitle => 'Подтвердить местоположение';

  @override
  String get orderDetailsNotFound => 'Детали заказа не найдены.';

  @override
  String get unknown => 'Неизвестно';

  @override
  String get locationPermissionDenied => 'Разрешение на местоположение не предоставлено';

  @override
  String permissionCheckError(String error) {
    return 'Ошибка проверки разрешения: $error';
  }

  @override
  String locationDetectionError(String error) {
    return 'Ошибка определения местоположения: $error';
  }

  @override
  String get userLocationNotFound => 'Местоположение пользователя не найдено';

  @override
  String routeInfo(String distance, String time) {
    return 'Маршрут: $distance км, примерно $time';
  }

  @override
  String routeCreationError(String error) {
    return 'Ошибка создания маршрута: $error';
  }

  @override
  String cameraMoveError(String error) {
    return 'Ошибка перемещения камеры: $error';
  }

  @override
  String permissionsCheckError(String error) {
    return 'Ошибка проверки разрешений: $error';
  }

  @override
  String get locationUpdating => 'Обновление местоположения...';

  @override
  String get clientLocationUpdated => 'Местоположение клиента успешно обновлено';

  @override
  String locationUpdateError(String error) {
    return 'Ошибка обновления местоположения: $error';
  }

  @override
  String get calculatingRoute => 'Расчет маршрута...';

  @override
  String regionsLoadError(String error) {
    return 'Ошибка загрузки регионов: $error';
  }

  @override
  String locationGetError(String error) {
    return 'Ошибка получения местоположения: $error';
  }

  @override
  String get apiKeySavedSuccessfully => 'API ключ успешно сохранен';

  @override
  String get minimumInterval60Minutes => 'Минимальный интервал составляет 60 минут';

  @override
  String pageLoadError(String error) {
    return 'Ошибка загрузки страницы: $error';
  }

  @override
  String get imageSetAsPrimary => 'Изображение установлено как основное';

  @override
  String imagesUploadedCount(int count) {
    return '$count изображений успешно загружено';
  }

  @override
  String serverImagesLoadError(String error) {
    return 'Ошибка загрузки изображений с сервера: $error';
  }

  @override
  String gallerySelectionError(String error) {
    return 'Ошибка выбора из галереи: $error';
  }

  @override
  String cameraCaptureError(String error) {
    return 'Ошибка получения с камеры: $error';
  }

  @override
  String get imagesUploadedSuccessfully => 'Изображения успешно загружены';

  @override
  String imagesUploadError(String error) {
    return 'Ошибка загрузки изображений: $error';
  }

  @override
  String orderDraftSaved(String fileName) {
    return 'Черновик заказа сохранен: $fileName';
  }

  @override
  String get tablesLabel => 'Таблицы';

  @override
  String tableColumns(String tableName) {
    return 'Колонки $tableName';
  }

  @override
  String get orderDetailsTitle => 'Детали заказа';

  @override
  String get camera => 'Камера';

  @override
  String get gallery => 'Галерея';

  @override
  String clientImagesTitle(String clientName) {
    return '$clientName - Изображения';
  }

  @override
  String tradingPointImagesTitle(String pointName) {
    return '$pointName - Изображения';
  }

  @override
  String uploadToServer(int count) {
    return 'Отправить на сервер ($count изображений)';
  }

  @override
  String get kpiDashboardTitle => 'KPI Панель';

  @override
  String get reportSentTitle => 'Отчет отправлен';

  @override
  String get editFeatureComingSoon => 'Функция редактирования скоро появится';

  @override
  String get sendPdf => 'Отправить PDF';

  @override
  String get printFeatureComingSoon => 'Функция печати скоро появится';

  @override
  String get print => 'Печать';

  @override
  String stepCompleted(String stepName) {
    return '$stepName завершен';
  }

  @override
  String stepSkip(String stepName) {
    return 'Пропуск $stepName';
  }

  @override
  String get syncWithDependencies => 'Синхронизировать с зависимостями';

  @override
  String get recommended => 'Рекомендуется';

  @override
  String get syncTableOnly => 'Синхронизировать только таблицу';

  @override
  String get syncWarning => 'Может не удаться, если зависимости не синхронизированы';

  @override
  String get tableOnly => 'Только таблица';

  @override
  String get withDependencies => 'С зависимостями';

  @override
  String get syncEntireGroup => 'Синхронизировать всю группу';

  @override
  String get statusNew => 'Новый';

  @override
  String get retail => 'Розничная';

  @override
  String get continueAction => 'Продолжить';

  @override
  String get previousStepsMustBeCompleted => 'Предыдущие шаги должны быть завершены';

  @override
  String get reload => 'Перезагрузить';

  @override
  String get imageDeleted => 'Изображение удалено';

  @override
  String imageDeleteError(String error) {
    return 'Ошибка удаления изображения: $error';
  }

  @override
  String get deleteImageTitle => 'Удалить изображение';

  @override
  String get deleteImageConfirmation => 'Вы уверены, что хотите удалить это изображение?';

  @override
  String get photoAfterTitle => 'Фото ПОСЛЕ (Facing correction)';

  @override
  String get photoBeforeTitle => 'Фото ДО (Facing correction)';

  @override
  String get photosNotLoadedYet => 'Фотографии еще не загружены';

  @override
  String get timeUnknown => 'Время неизвестно';

  @override
  String get unitOfMeasure => 'Единица измерения';

  @override
  String get category => 'Категория';

  @override
  String get brand => 'Бренд';

  @override
  String get series => 'Серия';

  @override
  String get barcode => 'Штрих-код';

  @override
  String get vendorCode => 'Артикул';

  @override
  String get warehouseInformation => 'Информация о складе';

  @override
  String get reserved => 'Зарезервировано';

  @override
  String get physicalProperties => 'Физические свойства';

  @override
  String get weight => 'Вес';

  @override
  String get volume => 'Объем';

  @override
  String get productsNotFound => 'Товары не найдены';

  @override
  String get bonusesNotFound => 'Бонусы не найдены';

  @override
  String get classInformationNotFound => 'Информация о классе не найдена';

  @override
  String get searchResultsNotFound => 'Результаты поиска не найдены';

  @override
  String get promotionConditions => 'Условия акции';

  @override
  String minimalProductCount(int count) {
    return 'Минимальное количество товара: $count';
  }

  @override
  String bonusCount(int count) {
    return 'Количество бонусов: $count';
  }

  @override
  String get readOnlyMode => 'Только чтение';

  @override
  String get shelfAuditTitle => 'Аудит полки (остатки)';

  @override
  String get pageInDevelopment => 'Страница находится в разработке';

  @override
  String apiKeyLabel(String status) {
    return 'API Ключ: $status';
  }

  @override
  String get apiKeyConfigured => 'Настроено';

  @override
  String get apiKeyNotRequired => 'Ключ не требуется';

  @override
  String get apiKeyNotConfigured => 'Не настроено';

  @override
  String get editInformation => 'Редактировать информацию';

  @override
  String get editClientCoordinates => 'Редактировать координаты клиента';

  @override
  String get clientPhotosTitle => 'Фото клиента';

  @override
  String clientPhotosDescription(String name) {
    return 'Здесь отображаются фотографии, относящиеся к клиенту $name';
  }

  @override
  String get notSent => 'Не отправлено';

  @override
  String sendToServer(int count) {
    return 'Отправить на сервер ($count фото)';
  }

  @override
  String get mainImage => 'Основное изображение';

  @override
  String get image => 'Изображение';

  @override
  String get noImagesAvailable => 'Изображения недоступны';

  @override
  String get clickPlusToAddImage => 'Нажмите кнопку +, чтобы добавить изображение';

  @override
  String get setAsMainImage => 'Установить как основное';

  @override
  String get clientNameLabel => 'Имя клиента';

  @override
  String get orderNumberLabel => 'Номер заказа';

  @override
  String get orderDateLabel => 'Дата заказа';

  @override
  String get orderTotalLabel => 'Сумма заказа';

  @override
  String get mainStatusLabel => 'Основной статус';

  @override
  String get statusCodeLabel => 'Код статуса';

  @override
  String get totalProductsLabel => 'Всего товаров';

  @override
  String get productNameLabel => 'Наименование товара';

  @override
  String get articleLabel => 'Артикул';

  @override
  String get quantityLabel => 'Количество';

  @override
  String get priceLabel => 'Цена';

  @override
  String get amountLabel => 'Сумма';

  @override
  String get priceTypeLabel => 'Тип цены';

  @override
  String get noProductsInOrder => 'Нет товаров в заказе';

  @override
  String get productListEmpty => 'Список товаров пуст';

  @override
  String get productsNotSelected => 'Товары не выбраны';

  @override
  String get clickPlusToAddProduct => 'Нажмите кнопку +, чтобы добавить товар';

  @override
  String get reportPeriod => 'Период отчёта';

  @override
  String get monthlyOKB => 'Ежемесячный OKB';

  @override
  String get selectPeriod => 'Выберите период';

  @override
  String get creatingLocation => 'Определение...';

  @override
  String get locationNotFound => 'Местоположение не найдено';

  @override
  String get createClient => 'Создать клиента';

  @override
  String get swipeToRefresh => 'Попробуйте потянуть вниз для обновления!';

  @override
  String get ifSwipeNotWorking => 'Если потягивание вниз не работает, выполните действие \"обновить все данные\", расположенное в меню настроек';

  @override
  String imageCountLabel(int count) {
    return '$count фото';
  }

  @override
  String photosNotLoadedDescription(String clientName) {
    return 'Здесь отображаются фотографии, относящиеся к клиенту $clientName';
  }

  @override
  String get totalLabel => 'Итого:';

  @override
  String get articleLabelShort => 'Арт.:';

  @override
  String get availableLabel => 'В наличии:';

  @override
  String get pieces => 'шт.';

  @override
  String get shippingDate => 'Дата доставки';

  @override
  String get changeShippingDate => 'Изменить дату доставки';

  @override
  String get totalValueLabel => 'Общая стоимость';

  @override
  String get productsLabel => 'Товары';

  @override
  String get addProduct => 'Добавить товар';

  @override
  String get creating => 'Создание...';

  @override
  String get refreshLabel => 'Обновить';

  @override
  String get refreshing => 'Обновление...';

  @override
  String get changePeriod => 'Изменить период';

  @override
  String get server => 'Сервер';

  @override
  String get addImage => 'Добавить изображение';

  @override
  String get takePhoto => 'Сделать фото';

  @override
  String get deleteImage => 'Удалить изображение';

  @override
  String get deleteImageConfirm => 'Вы уверены, что хотите удалить это изображение?';

  @override
  String get noReportsAvailable => 'Отчеты недоступны';

  @override
  String get tables => 'Таблицы';

  @override
  String get sendPdfLabel => 'Отправить PDF';

  @override
  String get warehouse => 'Склад';

  @override
  String get takePhotoTooltip => 'Сделать фото';

  @override
  String get changeShippingDateTooltip => 'Изменить дату доставки';

  @override
  String get sendReportViaTelegram => 'Отправить отчет через Telegram бот';

  @override
  String get fullscreen => 'Полный экран';

  @override
  String get updateCoordinates => 'Обновить координаты';

  @override
  String get list => 'Список';

  @override
  String get grid => 'Сетка';

  @override
  String get every1Hour => 'Каждый 1 час';

  @override
  String get every4Hours => 'Каждые 4 часа';

  @override
  String get every6Hours => 'Каждые 6 часов';

  @override
  String get every12Hours => 'Каждые 12 часов';

  @override
  String get daily24h => 'Ежедневно (24ч)';

  @override
  String get weekly1Week => 'Еженедельно (1 неделя)';

  @override
  String get customIntervalMinutes => 'Пользовательский интервал (минуты)';

  @override
  String get organizationLabel => 'Организация';

  @override
  String get codeLabel2 => 'Код';

  @override
  String get regionsLoading => 'Загрузка регионов...';

  @override
  String get cyclingRegular => 'Обычный велосипед';

  @override
  String get cyclingRoad => 'Шоссейный велосипед';

  @override
  String get cyclingMountain => 'Горный велосипед';

  @override
  String get cyclingSafe => 'Безопасный велосипед';

  @override
  String get productsPage => 'Страница товаров';

  @override
  String quantityHint(int stock) {
    return 'От 0 до $stock';
  }

  @override
  String get minimum60Minutes => 'Минимум 60 минут';

  @override
  String get enterQuantity => 'Введите количество';

  @override
  String maxAvailable(int stock) {
    return 'Максимально доступно: $stock шт.';
  }

  @override
  String imageNumber(int number) {
    return 'Изображение $number';
  }

  @override
  String get selectPriceType => 'Выберите тип цены';

  @override
  String get selectPriceTypeHint => 'Нажмите кнопку фильтра выше, чтобы выбрать тип цены из панели фильтров';

  @override
  String productsCount(int count) {
    return 'Количество товаров: $count';
  }

  @override
  String get categories => 'Категории';

  @override
  String get selectBrandFirst => 'Сначала выберите бренд';

  @override
  String get reportsSection => 'Раздел отчетов';

  @override
  String get tasks => 'Задачи';

  @override
  String locationError(String error) {
    return 'Ошибка получения местоположения: $error';
  }

  @override
  String get addressDetected => 'Адрес определен и автоматически заполнен';

  @override
  String get pleaseSelectRegion => 'Пожалуйста, выберите регион';

  @override
  String get pleaseSelectTradePointType => 'Пожалуйста, выберите тип торговой точки';

  @override
  String get locationDataNotFound => 'Данные о местоположении не найдены';

  @override
  String get all => 'Все';

  @override
  String get closeEditMode => 'Закрыть режим редактирования';

  @override
  String get activeClients => 'Активные клиенты';

  @override
  String get activeClientsTooltip => 'Клиенты с активными заказами сегодня';

  @override
  String get cashless => 'Безналичные';

  @override
  String get ordersTotal => 'Общая сумма заказов';

  @override
  String get visitedTradingPoints => 'Посещённые торговые точки';

  @override
  String get visitedTradingPointsTooltip => 'Количество посещённых торговых точек';

  @override
  String get territoryOKB => 'Территория OKB';

  @override
  String get territoryOKBTooltip => 'Охват клиентской базы по территории';

  @override
  String get todayMainIndicators => 'Сегодня — основные показатели';

  @override
  String get last7Days => 'Последние 7 дней';

  @override
  String get last30Days => 'Последние 30 дней';

  @override
  String get monthlyPlanFactForecast => 'Ежемесячный План / Факт / Прогноз';

  @override
  String get monthlyOkbAkb => 'Ежемесячный OKB/AKB';

  @override
  String get contractsNotFound => 'Контракты не найдены';

  @override
  String get contractsListRefreshed => 'Список контрактов обновлён';

  @override
  String get contractAmount => 'Сумма контракта';

  @override
  String get contractDocument => 'Документ контракта';

  @override
  String clientOrders(String name) {
    return 'Заказы клиента $name';
  }

  @override
  String get filterApplyError => 'Ошибка применения фильтра';

  @override
  String get main => 'Основное';

  @override
  String get contents => 'Содержимое';

  @override
  String get mainReports => 'Основные отчеты';

  @override
  String get mainReportsDescription => 'KPI показатели и основная статистика';

  @override
  String get visitsReport => 'Отчет о визитах';

  @override
  String get visitsReportDescription => 'Информация о визитах к клиентам';

  @override
  String get completedVisits => 'Выполненные визиты';

  @override
  String get plannedVisits => 'Запланированные визиты';

  @override
  String get visitEfficiency => 'Эффективность визитов';

  @override
  String get lastVisits => 'Последние визиты';

  @override
  String get dataLoading => 'Загрузка данных...';

  @override
  String get successful => 'Успешно';

  @override
  String get orderPlaced => 'Заказ размещен';

  @override
  String get rejected => 'Отклонено';

  @override
  String get reportDataRefreshed => 'Данные отчёта успешно обновлены';

  @override
  String get apiKeySaved => 'API ключ успешно сохранен';

  @override
  String saveError(String error) {
    return 'Ошибка сохранения: $error';
  }

  @override
  String userDataLoadError(String error) {
    return 'Ошибка загрузки данных пользователя: $error';
  }

  @override
  String warehouseDataLoadError(String error) {
    return 'Ошибка загрузки данных склада: $error';
  }

  @override
  String get justSaved => 'Только что сохранено';

  @override
  String savedMinutesAgo(int minutes) {
    return 'Сохранено $minutes минут назад';
  }

  @override
  String savedHoursAgo(int hours) {
    return 'Сохранено $hours часов назад';
  }

  @override
  String get notSaved => 'Не сохранено';

  @override
  String get selectDateRange => 'Выберите диапазон дат';

  @override
  String get selectPeriodTitle => 'Выберите период';

  @override
  String get selectedPeriod => 'Выбранный период';

  @override
  String get selectTable => 'Выберите таблицу';

  @override
  String get selectRegionValidator => 'Выберите регион';

  @override
  String get selectTradePointTypeValidator => 'Выберите тип торговой точки';

  @override
  String get currentMonth => 'Текущий месяц';

  @override
  String get selectReportDatesHint => 'Укажите даты начала и окончания для отчета';

  @override
  String get offlineCannotRefresh => 'Невозможно обновить данные в офлайн режиме';

  @override
  String distanceRequirementMessage(String name) {
    return 'Вам нужно соответствовать требованию расстояния для посещения $name.';
  }

  @override
  String requiredDistance(int distance) {
    return 'Требуемое расстояние: $distanceм';
  }

  @override
  String get orderStatusDelivered => 'Доставлен';

  @override
  String get orderStatusInProcess => 'В процессе';

  @override
  String get orderStatusReturn => 'Возврат';

  @override
  String get orderStatusExpired => 'Просрочен';

  @override
  String get contractStatusActive => 'Действует';

  @override
  String get contractStatusExpired => 'Истек';

  @override
  String get contractStatusCancelled => 'Отменен';

  @override
  String get contractStatusPending => 'Не согласован';

  @override
  String get contractStatusSuspended => 'Приостановлен';

  @override
  String get contractTabAll => 'Все';

  @override
  String get appPreparing => 'Подготовка приложения...';

  @override
  String get permissionsChecking => 'Проверка разрешений...';

  @override
  String get permissionsCheckTitle => 'Проверка разрешений';

  @override
  String get permissionsCheckDescription => 'Для полной работы приложения требуются следующие разрешения:';

  @override
  String get permissionFileStorage => 'Хранение файлов';

  @override
  String get permissionFileStorageDesc => 'Для сохранения данных';

  @override
  String get permissionLocation => 'Местоположение';

  @override
  String get permissionLocationDesc => 'Для карт и расчёта расстояния';

  @override
  String get permissionCamera => 'Камера';

  @override
  String get permissionCameraDesc => 'Для съёмки фото';

  @override
  String get permissionMicrophone => 'Микрофон';

  @override
  String get permissionMicrophoneDesc => 'Для записи аудио';

  @override
  String get permissionNotifications => 'Уведомления';

  @override
  String get permissionNotificationsDesc => 'Для показа сообщений';

  @override
  String get permissionAudio => 'Музыка и аудио';

  @override
  String get permissionAudioDesc => 'Для работы с аудиофайлами';

  @override
  String get permissionPhotosVideos => 'Фото и видео';

  @override
  String get permissionPhotosVideosDesc => 'Для работы с медиафайлами';

  @override
  String get permissionsLimitedWarning => 'Без разрешений приложение будет работать в ограниченном режиме.';

  @override
  String get startButton => 'Начать';

  @override
  String get permissionStorageTitle => 'Разрешение на хранение файлов';

  @override
  String get permissionStorageDescAndroid13 => 'Выберите папку для сохранения данных приложения';

  @override
  String get permissionStorageDescOther => 'Для сохранения и загрузки данных приложения';

  @override
  String get permissionStoragePurposeAndroid13 => 'Выберите папку для сохранения фото, документов и данных';

  @override
  String get permissionStoragePurposeOther => 'Для сохранения фото, документов и данных';

  @override
  String get permissionLocationTitle => 'Разрешение на местоположение';

  @override
  String get permissionLocationDescription => 'Для сортировки торговых точек по расстоянию';

  @override
  String get permissionLocationPurpose => 'Для показа местоположения на карте и расчёта расстояния';

  @override
  String get permissionLocationAlwaysTitle => 'Разрешение на фоновое местоположение';

  @override
  String get permissionLocationAlwaysDescription => 'Для определения местоположения в фоновом режиме';

  @override
  String get permissionLocationAlwaysPurpose => 'Фоновые сервисы и уведомления';

  @override
  String get permissionCameraTitle => 'Разрешение на камеру';

  @override
  String get permissionCameraDescription => 'Для съёмки фото и сканирования штрих-кодов';

  @override
  String get permissionCameraPurpose => 'Для фотографирования товаров и торговых точек';

  @override
  String get permissionMicrophoneTitle => 'Разрешение на микрофон';

  @override
  String get permissionMicrophoneDescription => 'Для записи голоса и аудиосообщений';

  @override
  String get permissionMicrophonePurpose => 'Голосовые заметки и аудиозаписи';

  @override
  String get permissionNotificationTitle => 'Разрешение на уведомления';

  @override
  String get permissionNotificationDescription => 'Для показа важных сообщений';

  @override
  String get permissionNotificationPurpose => 'Напоминания, новости и уведомления';

  @override
  String get permissionAudioTitle => 'Разрешение на музыку и аудио';

  @override
  String get permissionAudioDescription => 'Для работы с аудиофайлами';

  @override
  String get permissionAudioPurpose => 'Музыка, аудиосообщения и голосовые файлы';

  @override
  String get permissionPhotosVideosTitle => 'Разрешение на фото и видео';

  @override
  String get permissionPhotosVideosDescription => 'Для работы с медиафайлами';

  @override
  String get permissionPhotosVideosPurpose => 'Фото, видео и медиафайлы';

  @override
  String permissionRequired(String permission) {
    return 'Требуется $permission';
  }

  @override
  String permissionRequiredSettings(String description) {
    return '$description. Пожалуйста, предоставьте разрешение в настройках приложения.';
  }

  @override
  String get laterButton => 'Позже';

  @override
  String get goToSettings => 'Перейти в настройки';

  @override
  String permissionPurpose(String purpose) {
    return 'Цель: $purpose';
  }

  @override
  String get allowPermissionQuestion => 'Хотите предоставить разрешение?';

  @override
  String get grantPermission => 'Предоставить разрешение';

  @override
  String get checking => 'Проверка...';

  @override
  String get initializingSyncEngine => 'Инициализация системы синхронизации...';

  @override
  String get dataSynchronization => 'Синхронизация данных';

  @override
  String tablesSynced(int synced, int total) {
    return '$synced из $total таблиц синхронизировано';
  }

  @override
  String get syncAllData => 'Синхронизировать все данные';

  @override
  String get syncAllTablesInOrder => 'Это синхронизирует все таблицы в порядке зависимостей';

  @override
  String get dataGroups => 'Группы данных';

  @override
  String get backgroundAutoSync => 'Фоновая авто-синхронизация';

  @override
  String get backgroundSyncDescription => 'Держите данные актуальными даже когда приложение закрыто. Требуется подключение к интернету.';

  @override
  String get syncInterval => 'Интервал синхронизации';

  @override
  String get customIntervalNote => '* Пользовательский интервал имеет приоритет, если установлен 60 или более';

  @override
  String get clientBalanceCache => 'Кэш баланса клиентов';

  @override
  String clientBalancesCached(int count) {
    return '$count балансов клиентов в кэше';
  }

  @override
  String get balanceCacheDescription => 'Данные баланса клиентов хранятся в локальном кэше. Вы можете очистить кэш, если данные устарели.';

  @override
  String get clearing => 'Очистка...';

  @override
  String get clearCache => 'Очистить кэш';

  @override
  String get backgroundSyncEnabled => 'Фоновая синхронизация включена';

  @override
  String get backgroundSyncDisabled => 'Фоновая синхронизация отключена';

  @override
  String get minimumIntervalIs60 => 'Минимальный интервал 60 минут';

  @override
  String get justNow => 'Только что';

  @override
  String minutesAgo(int minutes) {
    return '$minutes мин назад';
  }

  @override
  String hoursAgo(int hours) {
    return '$hours ч назад';
  }

  @override
  String daysAgo(int days) {
    return '$days дней назад';
  }

  @override
  String weeksAgo(int weeks) {
    return '$weeks недель назад';
  }

  @override
  String get unknownProduct => 'Неизвестный продукт';

  @override
  String get errorOccurredTitle => 'Произошла ошибка';

  @override
  String get akbClientReport => 'Отчет по клиентам АКБ';

  @override
  String get akbClients => 'Клиенты АКБ';

  @override
  String get akbPercentage => 'Процент АКБ';

  @override
  String get akbClientsList => 'Список клиентов АКБ';

  @override
  String daysAgoShort(int days) {
    return '$days дней назад';
  }

  @override
  String get locationPermissionNeeded => 'Требуется разрешение на местоположение';

  @override
  String get locationPermissionRequestMessage => 'Для сортировки торговых точек по расстоянию и отображения на карте требуется ваше местоположение. Разрешить?';

  @override
  String get later => 'Позже';

  @override
  String get locationSettingsMessage => 'Для сортировки по расстоянию и функций карты требуется разрешение на местоположение. Пожалуйста, предоставьте разрешение в настройках приложения.';

  @override
  String get enableLocationServicesMessage => 'Службы определения местоположения должны быть включены для сортировки по расстоянию и функций карты. Пожалуйста, включите службы определения местоположения.';

  @override
  String get locationSettings => 'Настройки местоположения';

  @override
  String get dataRefreshError => 'Ошибка обновления данных';

  @override
  String dateFromTo(String start, String end) {
    return 'с $start по $end';
  }

  @override
  String get akbByRegions => 'AKB по регионам';

  @override
  String get akbByProductCategories => 'AKB по категориям товаров';

  @override
  String get tradingPointAbbr => 'т.т.';

  @override
  String get footerNoteText => 'Данные импортированы из отчёта Telegram. Вы можете изменить текст для переключения на новый источник — UI будет обновлён.';

  @override
  String get syncStepCheckingUser => 'Проверка пользователя...';

  @override
  String get syncStepClearingData => 'Очистка старых данных...';

  @override
  String get syncStepSyncingKpi => 'Загрузка данных KPI...';

  @override
  String get syncStepSyncingClients => 'Загрузка списка клиентов...';

  @override
  String get syncStepSyncingProducts => 'Загрузка товаров...';

  @override
  String get syncStepSyncingPriceTypes => 'Загрузка типов цен...';

  @override
  String get syncStepSyncingBusinessRegions => 'Загрузка бизнес-регионов...';

  @override
  String get syncStepSyncingUserWarehouses => 'Загрузка складов пользователя...';

  @override
  String get syncStepSyncingProductPrices => 'Загрузка цен товаров...';

  @override
  String get syncStepSyncingProductBalances => 'Загрузка остатков товаров...';

  @override
  String get syncStepSyncingClientContracts => 'Загрузка контрактов клиентов...';

  @override
  String get syncStepUpdatingClientContractStatus => 'Обновление статусов контрактов...';

  @override
  String get syncStepSyncingOrderStatuses => 'Загрузка статусов заказов...';

  @override
  String get syncStepSyncingOrders => 'Загрузка заказов...';

  @override
  String get syncStepSyncingSalesReqPermissions => 'Загрузка разрешений агента...';

  @override
  String get syncStepSyncingPlannedRoutes => 'Загрузка запланированных маршрутов...';

  @override
  String get syncStepSyncingUserOrganizations => 'Загрузка организаций пользователя...';

  @override
  String get syncStepSyncingPromotions => 'Загрузка акций...';

  @override
  String get syncStepSyncingMapTokens => 'Загрузка токенов карт...';

  @override
  String get syncStepSyncingReports => 'Загрузка отчётов...';

  @override
  String get syncStepSyncingThumbnails => 'Загрузка изображений...';

  @override
  String get syncStepCompleted => 'Данные обновлены!';

  @override
  String get syncStepError => 'Произошла ошибка';

  @override
  String get syncSuccessTitle => 'Успешно!';

  @override
  String get syncUpdatingTitle => 'Обновление данных...';

  @override
  String get paymentRequiredError => 'Требуется оплата. Проверьте вашу подписку.';

  @override
  String get authenticationError => 'Ошибка аутентификации. Войдите заново.';

  @override
  String get accessForbiddenError => 'Доступ запрещён. У вас нет разрешения.';

  @override
  String get serviceNotFoundError => 'Сервис не найден. Обратитесь в поддержку.';

  @override
  String get serverUnavailableError => 'Сервер недоступен. Попробуйте позже.';

  @override
  String get dataUpdateError => 'Ошибка обновления данных. Используются кэшированные данные.';

  @override
  String get syncStatusErrors => 'Ошибки';

  @override
  String get syncStatusSynced => 'Синхронизировано';

  @override
  String get syncStatusPartial => 'Частично';

  @override
  String get syncStatusNotSynced => 'Не синхронизировано';

  @override
  String tablesOfTotalSynced(int synced, int total) {
    return '$synced из $total таблиц синхронизировано';
  }

  @override
  String get tablesInThisGroup => 'Таблицы в этой группе';

  @override
  String get yesterdayText => 'Вчера';

  @override
  String get neverSynced => 'Никогда не синхронизировано';

  @override
  String get tableEmpty => 'Таблица пуста';

  @override
  String recordsCount(int count) {
    return '$count записей';
  }

  @override
  String lastSyncLabel(String time) {
    return 'Последняя синхронизация: $time';
  }

  @override
  String get syncTable => 'Синхронизировать таблицу';

  @override
  String get dependencies => 'Зависимости';

  @override
  String get willCascadeTo => 'Будет каскадировано на';

  @override
  String get tradingPointsLabel => 'Торговые точки';

  @override
  String get tradingPointsNotAvailable => 'Торговые точки недоступны';

  @override
  String get dateRangeLabel => 'Диапазон дат';

  @override
  String get allDatesLabel => 'Все даты';

  @override
  String get clearLabel => 'Очистить';

  @override
  String get statusLabel => 'Статус';

  @override
  String get statusAll => 'Все';

  @override
  String get statusActive => 'Активный';

  @override
  String get statusInactive => 'Неактивный';

  @override
  String get statusExpired => 'Истёк';

  @override
  String get statusPending => 'Ожидает';

  @override
  String clientContractsCount(String name, int count) {
    return 'Контракты клиента $name ($count)';
  }

  @override
  String refreshError(String error) {
    return 'Ошибка обновления';
  }

  @override
  String get dataTab => 'Данные';

  @override
  String get documentTab => 'Документ';

  @override
  String clientLabel(String name) {
    return 'Клиент: $name';
  }

  @override
  String get startDateLabel => 'Дата начала';

  @override
  String get endDateLabel => 'Дата окончания';

  @override
  String get unknownDate => 'Неизвестно';

  @override
  String get statusAndType => 'Статус и тип';

  @override
  String get typeLabel2 => 'Тип';

  @override
  String get additionalInfo => 'Дополнительная информация';

  @override
  String get certificateLimited => 'Сертификат ограничен';

  @override
  String get yesText => 'Да';

  @override
  String get noText => 'Нет';

  @override
  String get referenceNumberLabel => 'Номер справки';

  @override
  String get certificateNumberLabel => 'Номер сертификата';

  @override
  String get passportNumberLabel => 'Номер паспорта';

  @override
  String get districtCodeLabel => 'Код района';

  @override
  String get districtNameLabel => 'Название района';

  @override
  String get projectCodeLabel => 'Код проекта';

  @override
  String get creditLabel => 'Кредит';

  @override
  String get fullPaymentLabel => '100% оплата';

  @override
  String get uzbekLanguage => 'Узбекский';

  @override
  String get russianLanguage => 'Русский';

  @override
  String get pdfPreparing => 'Подготовка PDF...';

  @override
  String get tapToReveal => 'Нажмите';

  @override
  String get warehousesTitle => 'Склады';

  @override
  String get warehousesNotFound => 'Склады не найдены';

  @override
  String warehousesCount(int count) {
    return 'Количество складов: $count';
  }

  @override
  String createdLabel(String date) {
    return 'Создано: $date';
  }

  @override
  String updatedLabel(String date) {
    return 'Обновлено: $date';
  }

  @override
  String get visitCompletedToday => 'Визит выполнен сегодня';

  @override
  String get visitExpectedToday => 'Визит ожидается сегодня';

  @override
  String get visitNotPlannedToday => 'Визит не запланирован на сегодня';

  @override
  String visitOrderLabel(int number) {
    return 'Порядок визита: $number';
  }

  @override
  String get selectClientTitle => 'Выберите клиента';

  @override
  String clientsAvailable(int count) {
    return '$count клиентов доступно';
  }

  @override
  String get searchByNameCodeInn => 'Имя, код, ИНН, телефон, тип...';

  @override
  String get searchInCyrillicOrLatin => 'Поиск на кириллице или латинице';

  @override
  String foundCount(int count) {
    return '$count найдено';
  }

  @override
  String get clientNotFound => 'Клиент не найден';

  @override
  String get tryDifferentSearch => 'Попробуйте другой поисковый запрос';

  @override
  String get confirmButton => 'Подтвердить';

  @override
  String get cancelButton => 'Отмена';

  @override
  String get newContractTitle => 'Новый контракт';

  @override
  String get fillAllFields => 'Заполните все поля';

  @override
  String get contractTypesLoadError => 'Ошибка загрузки типов контрактов';

  @override
  String get pleaseSelectClient => 'Пожалуйста, выберите клиента';

  @override
  String get pleaseSelectContractType => 'Пожалуйста, выберите тип контракта';

  @override
  String get contractCreatedSuccessfully => 'Контракт успешно создан';

  @override
  String get contractCreationError => 'Ошибка создания контракта';

  @override
  String get documentInfoSection => 'Информация о документе';

  @override
  String get regionInfoSection => 'Информация о регионе';

  @override
  String get referenceNumberField => 'Номер справки';

  @override
  String get termLabel => 'Срок';

  @override
  String get certificateNumberField => 'Номер сертификата';

  @override
  String get certificateUnlimitedField => 'Сертификат бессрочный';

  @override
  String get passportNumberField => 'Номер паспорта';

  @override
  String get clientCodeLabel => 'Код клиента';

  @override
  String get organizationCodeLabel => 'Код организации';

  @override
  String get courierLabel => 'Курьер';

  @override
  String get vehicleLabel => 'Транспорт';

  @override
  String get licensePlateLabel => 'Номер машины';

  @override
  String get supervisorCommentLabel => 'Комментарий супервайзера';

  @override
  String get logistCommentLabel => 'Комментарий логиста';

  @override
  String get agentCommentLabel => 'Комментарий агента';

  @override
  String get networkErrorMessage => 'Ошибка сети. Проверьте интернет-соединение.';

  @override
  String get serverTimeoutMessage => 'Время ожидания сервера истекло.';

  @override
  String get orderDetailsLoadError => 'Ошибка загрузки деталей заказа.';

  @override
  String dataLoadFailed(String error) {
    return 'Ошибка загрузки данных: $error';
  }

  @override
  String get brands => 'Бренды';

  @override
  String get fileStoragePermission => 'Разрешение на хранение файлов';

  @override
  String get fileStorageDescriptionAndroid13 => 'Выберите папку для сохранения данных приложения';

  @override
  String get fileStorageDescription => 'Для сохранения и загрузки данных приложения';

  @override
  String get fileStoragePurposeAndroid13 => 'Выберите папку для сохранения фото, документов и данных';

  @override
  String get fileStoragePurpose => 'Сохранение фото, документов и данных';

  @override
  String get locationPermissionTitle => 'Разрешение на местоположение';

  @override
  String get locationPermissionDescription => 'Для сортировки торговых точек по расстоянию';

  @override
  String get locationPermissionPurpose => 'Показ местоположения на карте и расчет расстояния';

  @override
  String get alwaysLocationPermissionTitle => 'Разрешение на постоянное местоположение';

  @override
  String get alwaysLocationPermissionDescription => 'Для определения местоположения в фоновом режиме';

  @override
  String get alwaysLocationPermissionPurpose => 'Фоновый сервис и уведомления';

  @override
  String get cameraPermissionTitle => 'Разрешение на камеру';

  @override
  String get cameraPermissionDescription => 'Для фотосъемки и сканирования штрих-кодов';

  @override
  String get cameraPermissionPurpose => 'Фотосъемка товаров и торговых точек';

  @override
  String get microphonePermissionTitle => 'Разрешение на микрофон';

  @override
  String get microphonePermissionDescription => 'Для записи голоса и аудио сообщений';

  @override
  String get microphonePermissionPurpose => 'Голосовые заметки и аудио записи';

  @override
  String get notificationPermissionTitle => 'Разрешение на уведомления';

  @override
  String get notificationPermissionDescription => 'Для показа важных сообщений';

  @override
  String get notificationPermissionPurpose => 'Напоминания, новости и уведомления';

  @override
  String get audioPermissionTitle => 'Разрешение на музыку и аудио';

  @override
  String get audioPermissionDescription => 'Для работы с аудио файлами';

  @override
  String get audioPermissionPurpose => 'Музыка, аудио сообщения и голосовые файлы';

  @override
  String get photosAndVideosPermissionTitle => 'Разрешение на фото и видео';

  @override
  String get photosAndVideosPermissionDescription => 'Для работы с медиа файлами';

  @override
  String get photosAndVideosPermissionPurpose => 'Работа с фото, видео и медиа файлами';

  @override
  String permissionRequiredMessage(String description) {
    return '$description. Пожалуйста, предоставьте разрешение в настройках приложения.';
  }

  @override
  String get goToSettingsButton => 'Перейти в настройки';

  @override
  String get grantPermissionButton => 'Дать разрешение';

  @override
  String get checkingPermission => 'Проверка...';

  @override
  String get permissionCheckTitle => 'Проверка разрешений';

  @override
  String get permissionCheckMessage => 'Для корректной работы приложению необходимы следующие разрешения:';

  @override
  String get permissionSaveData => 'Сохранение данных';

  @override
  String get permissionMapDistance => 'Карта и расчет расстояния';

  @override
  String get permissionTakePhotos => 'Фотосъемка';

  @override
  String get permissionRecordVoice => 'Запись голоса';

  @override
  String get permissionShowMessages => 'Показ сообщений';

  @override
  String get permissionLimitedMode => 'Без разрешений приложение будет работать в ограниченном режиме.';

  @override
  String purposeLabel(String purpose) {
    return 'Цель: $purpose';
  }

  @override
  String get grantPermissionQuestion => 'Хотите дать разрешение?';

  @override
  String get serviceInitError => 'Ошибка инициализации сервисов';

  @override
  String get clientInnNotAvailable => 'ИНН клиента недоступен';

  @override
  String get clientBalanceZero => 'Баланс клиента равен нулю.';

  @override
  String get balanceDataNotFound => 'Данные баланса не найдены';

  @override
  String updatedAtTime(String time) {
    return 'Обновлено: $time';
  }

  @override
  String get clientDebtorStatus => 'Клиент должник';

  @override
  String get overpaymentStatus => 'Переплата';

  @override
  String get balanceZeroStatus => 'Баланс равен нулю';

  @override
  String get savingStatus => 'Сохранение...';

  @override
  String get unsavedChangesStatus => 'Несохраненные изменения';

  @override
  String get offlineStatus => 'Офлайн';

  @override
  String pendingSyncCount(int count) {
    return '$count ожидает синхронизации';
  }

  @override
  String get allSyncedStatus => 'Все синхронизировано';

  @override
  String get autoSaving => 'Автосохранение...';

  @override
  String get savingStepData => 'Сохранение данных шага...';

  @override
  String get mandatoryLabel => 'Обязательно';

  @override
  String get optionalLabel => 'Необязательно';

  @override
  String get currentLabel => 'Текущий';

  @override
  String get completedLabel => 'Завершено';

  @override
  String get skippedLabel => 'Пропущено';

  @override
  String notesLabel(String notes) {
    return 'Заметки: $notes';
  }

  @override
  String reasonLabel(String reason) {
    return 'Причина: $reason';
  }

  @override
  String get reasonHint => 'Причина';

  @override
  String get syncStarting => 'Начало синхронизации...';

  @override
  String get weekdayMon => 'Пн';

  @override
  String get weekdayTue => 'Вт';

  @override
  String get weekdayWed => 'Ср';

  @override
  String get weekdayThu => 'Чт';

  @override
  String get weekdayFri => 'Пт';

  @override
  String get weekdaySat => 'Сб';

  @override
  String get weekdaySun => 'Вс';

  @override
  String get copyLabel => 'Копировать';

  @override
  String get reloadLabel => 'Перезагрузить';

  @override
  String get refreshContractTypesAndRegions => 'Обновить типы контрактов и регионы';

  @override
  String get orderStatusNew => 'Новый';

  @override
  String get orderStatusConfirmed => 'Подтверждён';

  @override
  String get orderStatusDelivering => 'В доставке';

  @override
  String get orderStatusReturnRequested => 'Запрос на возврат';

  @override
  String get orderStatusCancelled => 'Отменён';

  @override
  String get orderStatusDeliveredUnpaid => 'Доставлен, не оплачен';

  @override
  String get orderStatusDeliveredPartiallyPaid => 'Доставлен, частично оплачен';

  @override
  String get orderStatusUnknown => 'Неизвестно';

  @override
  String get filterTooltip => 'Фильтр';

  @override
  String get fullscreenTooltip => 'Полный экран';

  @override
  String get refusalReasonClientNotAvailable => 'Клиент недоступен';

  @override
  String get refusalReasonNoTime => 'Нет времени';

  @override
  String get refusalReasonProductNotNeeded => 'Товар не нужен';

  @override
  String get refusalReasonPriceNotSuitable => 'Цена не подходит';

  @override
  String get refusalReasonWorksWithOtherSupplier => 'Работает с другим поставщиком';

  @override
  String get refusalReasonOther => 'Другая причина';

  @override
  String get apiKeyStatusConfigured => 'настроен';

  @override
  String get apiKeyStatusNotConfigured => 'не настроен';

  @override
  String get visited => 'Посещено';

  @override
  String get plannedForToday => 'Запланировано на сегодня';

  @override
  String get additionalInformation => 'Дополнительная информация';

  @override
  String get locationInformation => 'Информация о местоположении';

  @override
  String get businessInformation => 'Бизнес информация';

  @override
  String get apiKeyStatusNotRequired => 'ключ не требуется';

  @override
  String get apiKeyStatusError => 'ошибка';

  @override
  String get fakturaFetchCompanyData => 'Загрузить';

  @override
  String get fakturaRefreshCompanyData => 'Обновить';

  @override
  String get fakturaEnterInn => 'Пожалуйста, введите ИНН';

  @override
  String get fakturaInvalidInnFormat => 'Неверный формат ИНН. Должно быть 9 или 14 цифр';

  @override
  String fakturaCompanyDataLoaded(String companyName) {
    return 'Данные организации успешно загружены: $companyName';
  }

  @override
  String fakturaRegionNotFound(String regionName) {
    return 'Регион не найден: $regionName. Пожалуйста, выберите вручную';
  }

  @override
  String get fakturaAuthError => 'Ошибка аутентификации';

  @override
  String get fakturaAuthErrorRetry => 'Ошибка аутентификации. Пожалуйста, попробуйте еще раз';

  @override
  String get fakturaCompanyNotFound => 'Организация не найдена. Проверьте ИНН';

  @override
  String get fakturaInvalidRequest => 'Неверный запрос. Проверьте формат ИНН';

  @override
  String fakturaServerError(String statusCode) {
    return 'Ошибка сервера: $statusCode';
  }

  @override
  String get fakturaInnEmpty => 'ИНН не может быть пустым';

  @override
  String get fakturaTokenRefreshError => 'Ошибка обновления токена';

  @override
  String get reportMenuTitle => 'Меню отчетов';

  @override
  String get reportAlreadySent => 'Отчет уже отправлен в вашу группу Telegram. Хотите отправить снова?';

  @override
  String get reportSentSuccess => 'Отчет отправлен';

  @override
  String get resendReport => 'Отправить снова';

  @override
  String get toggleHeaderShow => 'Показать заголовок';

  @override
  String get toggleHeaderHide => 'Скрыть заголовок';

  @override
  String get periodNotSelected => 'Период не выбран';

  @override
  String get dataSyncing => 'Синхронизация данных...';

  @override
  String get reportsUpdated => 'Отчеты обновлены';

  @override
  String get applyButton => 'Применить';

  @override
  String get reportMainEvyap => 'Основные отчеты(для EVYAP)';

  @override
  String get reportMainEvyapDesc => 'Показатели KPI и основная статистика';

  @override
  String get reportVisits => 'Отчет по визитам';

  @override
  String get reportVisitsDesc => 'Информация о визитах к клиентам';

  @override
  String get reportAkbClient => 'AKB Client';

  @override
  String get reportAkbClientDesc => 'Отчет по клиентам AKB';

  @override
  String get reportAkbSum => 'AKB Sum';

  @override
  String get reportAkbSumDesc => 'Финансовый отчет по суммам AKB';

  @override
  String get reportAkbProduct => 'AKB Product';

  @override
  String get reportAkbProductDesc => 'Отчет по продуктам AKB';

  @override
  String get reportCategory => 'Отчеты по категориям';

  @override
  String get reportCategoryDesc => 'Анализ продаж по категориям';

  @override
  String get reportMonthlyResults => 'Месячные результаты';

  @override
  String get reportMonthlyResultsDesc => 'Результаты продаж и тенденции за месяц';

  @override
  String get reportMonthlyKpi => 'Месячный KPI (зарплата)';

  @override
  String get reportMonthlyKpiDesc => 'Выполнение месячного KPI и отчет по зарплате';

  @override
  String get akbAmount => 'Сумма AKB';

  @override
  String get akbProducts => 'Продукты AKB';

  @override
  String get productTypes => 'Типы продуктов';

  @override
  String get categoriesCount => 'Количество категорий';

  @override
  String get topSelling => 'Самые продаваемые';

  @override
  String get monthlySales => 'Месячные продажи';

  @override
  String get monthlyGrowth => 'Месячный рост';

  @override
  String get kpiCompletion => 'Выполнение KPI';

  @override
  String get salaryAmount => 'Сумма зарплаты';

  @override
  String get scannerTitle => 'Сканер документов';

  @override
  String get scannerSubtitle => 'Сканируйте сертификат для автозаполнения';

  @override
  String get scannerTakePhoto => 'Снять фото';

  @override
  String get scannerChoosePhoto => 'Галерея';

  @override
  String get scannerProcessing => 'Анализ документа...';

  @override
  String get scannerPleaseWait => 'ИИ извлекает данные из изображения';

  @override
  String scannerDataExtracted(int count) {
    return 'Извлечено $count полей';
  }

  @override
  String get scannerCameraError => 'Ошибка доступа к камере. Проверьте разрешения';

  @override
  String get scannerGalleryError => 'Ошибка доступа к галерее. Проверьте разрешения';

  @override
  String get scannerImageEmpty => 'Выбранное изображение пустое или повреждено';

  @override
  String get scannerNetworkError => 'Ошибка сети. Проверьте интернет-соединение';

  @override
  String get scannerAuthError => 'Ошибка аутентификации ИИ. Попробуйте снова';

  @override
  String get scannerRateLimitError => 'Слишком много запросов. Подождите немного';

  @override
  String get scannerNoDataExtracted => 'Не удалось извлечь данные. Попробуйте более четкое изображение';

  @override
  String get scannerParseError => 'Ошибка обработки ответа ИИ. Попробуйте снова';

  @override
  String get scannerUnknownError => 'Произошла непредвиденная ошибка. Попробуйте снова';

  @override
  String get scannerFormUpdated => 'Форма обновлена отсканированными данными';

  @override
  String get scannerVerifyingWithFaktura => 'Проверка данных через Faktura.uz...';

  @override
  String get scannerDataVerified => 'Данные проверены и обновлены из Faktura.uz';

  @override
  String scannerDataMismatch(int count) {
    return '$count полей обновлено из Faktura.uz';
  }

  @override
  String get faqPageTitle => 'Регламент';

  @override
  String get faqSupervisorSubtitle => 'Обязанности супервайзера';

  @override
  String get faqSalesRepSubtitle => 'Регламент торгового представителя';

  @override
  String get faqRoleSupervisor => 'Супервайзер';

  @override
  String get faqRoleSalesRep => 'Торговый представитель';

  @override
  String get faqSectionsCount => 'разделов';

  @override
  String get faqSvGpsTitle => 'GPS-мониторинг';

  @override
  String get faqSvGpsMorningTitle => 'Утренний отчет (до 9:15)';

  @override
  String get faqSvGpsMorningContent => 'Ежедневно до 9:15 утра супервайзер обязан направлять в рабочую группу отчёт о статусе выхода торговых представителей на маршрут, с указанием, кто вышел вовремя, а кто нет.';

  @override
  String get faqSvGpsEveningTitle => 'Вечерний отчет (до 18:00)';

  @override
  String get faqSvGpsEveningContent => 'До 18:00 — отправляется итоговый GPS-отчёт по завершению рабочего дня.';

  @override
  String get faqSvSalesTitle => 'Отчёт по продажам';

  @override
  String get faqSvSalesInterimTitle => 'Промежуточный отчет (до 13:00)';

  @override
  String get faqSvSalesInterimContent => 'До 13:00 — направляется промежуточный отчёт с суммой и количеством собранных заказов.';

  @override
  String get faqSvSalesFinalTitle => 'Финальный отчет (до 18:00)';

  @override
  String get faqSvSalesFinalContent => 'До 18:00 — финальный отчёт, включающий:\n• итоговую сумму продаж за день\n• количество заказов\n• план выезда и прогноз заказов на следующий день\n• отчёт по возвратам (если имеются)';

  @override
  String get faqSvKpiTitle => 'KPI и планирование';

  @override
  String get faqSvKpiMondayTitle => 'Офисный день (понедельник)';

  @override
  String get faqSvKpiMondayContent => 'Каждый понедельник — офисный день.';

  @override
  String get faqSvKpiAnalysisTitle => 'Анализ и задачи';

  @override
  String get faqSvKpiAnalysisContent => 'Проводится подведение итогов за прошедшую неделю, анализ KPI и постановка задач на текущую неделю.';

  @override
  String get faqSvTravelTitle => 'Travel Plans';

  @override
  String get faqSvTravelMonthlyTitle => 'Ежемесячное планирование';

  @override
  String get faqSvTravelMonthlyContent => 'Ежемесячно, 30–31 числа, супервайзеры направляют личным сообщением региональному менеджеру индивидуальные Travel Plans на следующий месяц.';

  @override
  String get faqSvTimeTitle => 'Учёт рабочего времени';

  @override
  String get faqSvTimeWeeklyTitle => 'Еженедельный табель';

  @override
  String get faqSvTimeWeeklyContent => 'Табель составляется на еженедельной основе (по понедельникам) с указанием количества отработанных дней торговыми представителями.';

  @override
  String get faqSvTimeMonthlyTitle => 'Месячный табель';

  @override
  String get faqSvTimeMonthlyContent => 'Финальный табель за месяц предоставляется в последний день календарного месяца.';

  @override
  String get faqSvSalaryTitle => 'Зарплата и KPI';

  @override
  String get faqSvSalaryKpiTitle => 'Итоги по KPI';

  @override
  String get faqSvSalaryKpiContent => 'Ежемесячно, в период с 1 по 3 число (в зависимости от выходных), супервайзер обязан подвести итоги за весь месяц по KPI.';

  @override
  String get faqSvSalaryCalcTitle => 'Расчёт зарплаты';

  @override
  String get faqSvSalaryCalcContent => 'Подготовить и передать расчёт заработной платы торговых представителей EVYAP на основании выполненных показателей.';

  @override
  String get faqTpGeneralTitle => 'Общие положения';

  @override
  String get faqTpGeneralPurposeTitle => 'Цель документа';

  @override
  String get faqTpGeneralPurposeContent => 'Настоящий регламент устанавливает правила организации и выполнения обязанностей торговыми представителями ООО «Gloriya Global». Цель документа — обеспечение дисциплины, прозрачности и эффективности работы торговых представителей.';

  @override
  String get faqTpHoursTitle => 'Рабочее время и маршрут';

  @override
  String get faqTpHoursScheduleTitle => 'График работы';

  @override
  String get faqTpHoursScheduleContent => 'Рабочий день начинается в 9:00 и заканчивается в 18:00.';

  @override
  String get faqTpHoursRouteTitle => 'Выход на маршрут';

  @override
  String get faqTpHoursRouteContent => 'Торговый представитель обязан вовремя выходить на маршрут согласно утверждённому графику.';

  @override
  String get faqTpHoursDelayTitle => 'Опоздания';

  @override
  String get faqTpHoursDelayContent => 'Опоздание более чем на 15 минут без уважительной причины фиксируется как нарушение трудовой дисциплины.';

  @override
  String get faqTpVisitsTitle => 'Посещение торговых точек';

  @override
  String get faqTpVisitsDailyTitle => 'Ежедневные визиты';

  @override
  String get faqTpVisitsDailyContent => 'Каждый торговый представитель обязан ежедневно посещать все торговые точки согласно маршруту.';

  @override
  String get faqTpVisitsChangesTitle => 'Изменения маршрута';

  @override
  String get faqTpVisitsChangesContent => 'В случае изменения маршрута (отсутствие клиента, закрытие точки и т.д.) необходимо сообщить в рабочий чат с указанием причины.';

  @override
  String get faqTpVisitsPhotoTitle => 'Фото/видео отчёт';

  @override
  String get faqTpVisitsPhotoContent => 'По каждой точке необходимо предоставить фото- или видеоотчёт (выкладка, активность, заказ).';

  @override
  String get faqTpVideoTitle => 'Видеоотчёты (Telegram)';

  @override
  String get faqTpVideoMorningTitle => 'Утренний видеоотчёт';

  @override
  String get faqTpVideoMorningContent => 'В начале рабочего дня (до 9:30) торговый представитель обязан отправить видеосообщение («кружок») в общий чат Telegram, где указать:\n• что вышел на маршрут\n• район или направление на день\n• основные задачи';

  @override
  String get faqTpVideoDuringTitle => 'Отчёты в течение дня';

  @override
  String get faqTpVideoDuringContent => 'В течение дня приветствуется отправка коротких видеосообщений с торговых точек — демонстрация выкладки, новинок или активностей.';

  @override
  String get faqTpVideoEndTitle => 'Итоговый видеоотчёт';

  @override
  String get faqTpVideoEndContent => 'В конце дня рекомендуется краткий видеоотчёт с итогами.';

  @override
  String get faqTpReportingTitle => 'Отчётность';

  @override
  String get faqTpReportingRealTimeTitle => 'Отправка в реальном времени';

  @override
  String get faqTpReportingRealTimeContent => 'Все фото, видео и комментарии по маршруту должны быть отправлены в момент визита.';

  @override
  String get faqTpReportingConsequenceTitle => 'Последствия невыполнения';

  @override
  String get faqTpReportingConsequenceContent => 'Невыполнение ежедневной отчётности расценивается как невыход в маршрут или отсутствие активности.';

  @override
  String get faqTpResponsibilityTitle => 'Ответственность';

  @override
  String get faqTpResponsibilityRulesTitle => 'Дисциплинарная ответственность';

  @override
  String get faqTpResponsibilityRulesContent => 'Несоблюдение настоящего регламента влечёт дисциплинарную ответственность в соответствии с внутренними правилами компании.';

  @override
  String get faqTpResponsibilityMeasuresTitle => 'Меры взыскания';

  @override
  String get faqTpResponsibilityMeasuresContent => 'Меры ответственности: предупреждение → выговор → удержание премии.';

  @override
  String get productImageLoading => 'Загрузка изображения...';

  @override
  String get productImageError => 'Не удалось загрузить изображение';

  @override
  String get productNoImage => 'Изображение недоступно';

  @override
  String productImageSyncProgress(int current, int total) {
    return 'Синхронизация изображений: $current/$total';
  }

  @override
  String get productImageSyncComplete => 'Синхронизация изображений завершена';

  @override
  String get productImageSyncFailed => 'Ошибка синхронизации изображений';

  @override
  String get productImageTapToView => 'Нажмите для просмотра';

  @override
  String productImageCount(int count) {
    return '$count изображений';
  }

  @override
  String get productBasicInfo => 'Основная информация';

  @override
  String get productPricingInfo => 'Информация о ценах';

  @override
  String get productStockInfo => 'Информация о складе';

  @override
  String get productAdditionalInfo => 'Дополнительная информация';

  @override
  String get productCode => 'Код товара';

  @override
  String get productVendorCode => 'Артикул';

  @override
  String get productBarcode => 'Штрих-код';

  @override
  String get productCategory => 'Категория';

  @override
  String get productSeries => 'Серия';

  @override
  String get productPriceType => 'Тип цены';

  @override
  String get productPrice => 'Цена';

  @override
  String get productPriceValidFrom => 'Действует с';

  @override
  String get productPriceValidTo => 'Действует до';

  @override
  String get productWarehouse => 'Склад';

  @override
  String get productStock => 'Остаток';

  @override
  String get productQuantity => 'Общее количество';

  @override
  String get productReserved => 'Зарезервировано';

  @override
  String get productAvailable => 'Доступно';

  @override
  String get productUnit => 'Единица измерения';

  @override
  String get productWeight => 'Вес';

  @override
  String get productCapacity => 'Объём';

  @override
  String get productBrand => 'Бренд';

  @override
  String get productProject => 'Код проекта';

  @override
  String get copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get productInfoCopied => 'Информация о товаре скопирована';

  @override
  String get checkingCache => 'Проверка кэша...';

  @override
  String get loadingFromDatabase => 'Загрузка из базы данных...';

  @override
  String get syncingFromServer => 'Синхронизация с сервером...';

  @override
  String get databaseEmpty => 'Заказы не найдены локально';

  @override
  String get databaseEmptyDescription => 'Хотите синхронизировать заказы с сервера?';

  @override
  String get syncFromServer => 'Синхронизировать';

  @override
  String get refreshingData => 'Обновление данных...';

  @override
  String get dataLoadedFromCache => 'Данные загружены из кэша';

  @override
  String get dataLoadedFromDatabase => 'Данные загружены из базы';

  @override
  String get dataSyncedFromServer => 'Заказы успешно синхронизированы';

  @override
  String get syncFailed => 'Ошибка синхронизации. Попробуйте снова.';

  @override
  String get noInternetForSync => 'Нет подключения к интернету. Проверьте сеть.';

  @override
  String get retrySync => 'Повторить';

  @override
  String lastUpdated(String time) {
    return 'Обновлено: $time';
  }

  @override
  String get connectionRestored => 'Соединение восстановлено';

  @override
  String get youAreOffline => 'Вы не в сети';

  @override
  String get lineTotal => 'Сумма строки';

  @override
  String get totalMismatchWarning => 'Расчётная сумма отличается от значения на сервере';

  @override
  String get bonus => 'Подарок';

  @override
  String get unitPrice => 'Цена за единицу';

  @override
  String get orderTotalMismatch => 'Обнаружено несоответствие общей суммы заказа';
}
