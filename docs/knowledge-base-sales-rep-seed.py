"""Sales-rep Knowledge Base seed content.

Ready-to-port Python module. Copy this file verbatim to:
    src/apps/knowledge/data/sales_rep_seed.py

Consumed by:
    src/apps/knowledge/management/commands/seed_sales_rep_knowledge.py

Tree shape: 5 root categories x 2-3 documents x 2-3 sections x 2-4 blocks.
Trilingual (uz/ru/en). Every IMAGE block carries a placeholder_key so
the /dev/knowledge-authoring/ UI can highlight it for screenshot upload.

This content was authored against the mobile app's actual UX
(login, settings, projects, customers, visits, sync, reports) so
sales reps can read it in-app and recognise every step.
"""

from __future__ import annotations

from dataclasses import dataclass, field

# NOTE for backend team:
# If your apps.knowledge.enums uses lowercase BlockType (.paragraph,
# .heading, ...) and DocType (.manual, .training, ...), the imports
# below will still resolve — Python enum members are case-sensitive
# but Django convention is typically uppercase. If you hit an
# AttributeError, swap the constants in this file to match.
from apps.knowledge.enums import BlockType, DocType


@dataclass(frozen=True)
class SeedBlock:
    type: BlockType
    data: dict
    placeholder_key: str | None = None


@dataclass(frozen=True)
class SeedSection:
    anchor: str
    title: dict
    blocks: list[SeedBlock]


@dataclass(frozen=True)
class SeedDocument:
    slug: str
    doc_type: DocType
    title: dict
    summary: dict | None
    is_pinned: bool
    sections: list[SeedSection]


@dataclass(frozen=True)
class SeedCategory:
    slug: str
    name: dict
    description: dict | None
    icon: str | None
    color: str | None
    order: int
    children: list["SeedCategory"] = field(default_factory=list)
    documents: list[SeedDocument] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Helper factories — mirror the mobile SeedBlock.* convenience constructors
# so the content tree stays compact and readable.
# ---------------------------------------------------------------------------

def _paragraph(markdown: dict) -> SeedBlock:
    return SeedBlock(type=BlockType.PARAGRAPH, data={"markdown_i18n": markdown})


def _heading(level: int, text: dict) -> SeedBlock:
    return SeedBlock(type=BlockType.HEADING, data={"level": level, "text_i18n": text})


def _callout(variant: str, markdown: dict) -> SeedBlock:
    return SeedBlock(
        type=BlockType.CALLOUT,
        data={"variant": variant, "markdown_i18n": markdown},
    )


def _list(items: dict, style: str = "bullet") -> SeedBlock:
    return SeedBlock(
        type=BlockType.LIST,
        data={"style": style, "items_i18n": items},
    )


def _image_placeholder(key: str, caption: dict | None = None) -> SeedBlock:
    data: dict = {"placeholder_key": key, "fit": "contain"}
    if caption is not None:
        data["caption_i18n"] = caption
    return SeedBlock(type=BlockType.IMAGE, data=data, placeholder_key=key)


# ---------------------------------------------------------------------------
# SALES_REP_SEED_V1 — top-level export consumed by the management command.
# ---------------------------------------------------------------------------

SALES_REP_SEED_V1: list[SeedCategory] = [
    # =====================================================================
    # 1. Getting started
    # =====================================================================
    SeedCategory(
        slug="savdo-vakili-boshlash",
        icon="🚀",
        color=None,
        order=1,
        name={
            "uz": "Boshlash",
            "ru": "Начало работы",
            "en": "Getting started",
        },
        description={
            "uz": "Ilovaga kirish, sozlamalar va birinchi qadamlar",
            "ru": "Вход в приложение, настройки и первые шаги",
            "en": "App login, initial settings, and first steps",
        },
        documents=[
            SeedDocument(
                slug="login-va-kirish",
                doc_type=DocType.MANUAL,
                is_pinned=True,
                title={
                    "uz": "Ilovaga kirish (login)",
                    "ru": "Вход в приложение",
                    "en": "Logging in to the app",
                },
                summary={
                    "uz": "Login, parol va serverni tanlash bo'yicha qadamlar",
                    "ru": "Шаги по логину, паролю и выбору сервера",
                    "en": "Steps for username, password, and server selection",
                },
                sections=[
                    SeedSection(
                        anchor="login-overview",
                        title={"uz": "Umumiy ko'rinish", "ru": "Обзор", "en": "Overview"},
                        blocks=[
                            _paragraph({
                                "uz": "Ilova ochilganda **Login** sahifasi paydo bo'ladi. Bu yerda admin tomonidan berilgan login va parolingizni kiritasiz, kerakli serverni tanlaysiz va **Kirish** tugmasini bosasiz.",
                                "ru": "При запуске приложения откроется страница **Вход**. Введите логин и пароль, выданные администратором, выберите нужный сервер и нажмите **Войти**.",
                                "en": "When the app opens, the **Login** page appears. Enter the credentials issued by your admin, pick the right server, and tap **Sign in**.",
                            }),
                            _image_placeholder(
                                "screenshot_login_form",
                                caption={"uz": "Login sahifasi", "ru": "Страница входа", "en": "Login screen"},
                            ),
                        ],
                    ),
                    SeedSection(
                        anchor="login-steps",
                        title={"uz": "Qadamlar", "ru": "Шаги", "en": "Steps"},
                        blocks=[
                            _list({
                                "uz": [
                                    "Login maydoniga kodingizni kiriting (masalan 100123)",
                                    "Parolingizni kiriting",
                                    "Server pastdagi tugmadan tanlanadi: Production / Staging",
                                    "«Eslab qoling» belgilangan bo'lsa, keyingi safar avtomatik to'ldiriladi",
                                    "Kirish tugmasini bosing",
                                ],
                                "ru": [
                                    "Введите код в поле логин (например 100123)",
                                    "Введите пароль",
                                    "Сервер выбирается ниже: Production / Staging",
                                    "Если установлен «Запомнить меня», следующий раз поля заполнятся автоматически",
                                    "Нажмите «Войти»",
                                ],
                                "en": [
                                    "Enter your code in the login field (e.g. 100123)",
                                    "Enter your password",
                                    "Pick a server below: Production / Staging",
                                    'If "Remember me" is checked, fields auto-fill next time',
                                    "Tap Sign in",
                                ],
                            }),
                            _callout("warn", {
                                "uz": "Parol noto'g'ri kiritilsa, server yangi parol so'raydi. 5 marta xato kiritsangiz hisob vaqtincha bloklanishi mumkin.",
                                "ru": "Если пароль введён неверно, сервер запросит повторный ввод. После 5 ошибок аккаунт может быть временно заблокирован.",
                                "en": "If your password is wrong, the server asks again. Five failures may temporarily lock your account.",
                            }),
                        ],
                    ),
                    SeedSection(
                        anchor="login-troubleshoot",
                        title={"uz": "Muammolar va yechim", "ru": "Проблемы и решения", "en": "Troubleshooting"},
                        blocks=[
                            _callout("danger", {
                                "uz": "Agar **Server xato** ko'rsatilsa: Internetingizni va serverning to'g'ri tanlanganligini tekshiring.",
                                "ru": "Если показано **Ошибка сервера**: проверьте интернет и правильность выбора сервера.",
                                "en": "If you see **Server error**: check your internet connection and that the right server is selected.",
                            }),
                            _paragraph({
                                "uz": "Agar **Sessiya muddati tugagan** xabari chiqsa, qaytadan login qiling. Cache parolingiz xavfsiz saqlanadi.",
                                "ru": "Если появляется сообщение **Срок сессии истёк**, войдите снова. Кэшированный пароль хранится безопасно.",
                                "en": "If you see **Session expired**, log in again. Your cached password is stored securely.",
                            }),
                        ],
                    ),
                ],
            ),
            SeedDocument(
                slug="til-tema-sozlamalari",
                doc_type=DocType.MANUAL,
                is_pinned=False,
                title={
                    "uz": "Til va tema sozlamalari",
                    "ru": "Настройки языка и темы",
                    "en": "Language and theme settings",
                },
                summary={
                    "uz": "O'zbek/Rus/Ingliz tilini va Light/Dark temani sozlash",
                    "ru": "Переключение между O'zbek/Русский/English и Light/Dark темой",
                    "en": "Switch among Uzbek/Russian/English and Light/Dark themes",
                },
                sections=[
                    SeedSection(
                        anchor="open-settings",
                        title={"uz": "Sozlamalar sahifasini ochish", "ru": "Открыть настройки", "en": "Open settings"},
                        blocks=[
                            _paragraph({
                                "uz": "Bosh sahifaning yuqori qismida **Sozlamalar** ikonkasini bosing yoki pastki menyudan **Sozlamalar** bo'limini tanlang.",
                                "ru": "Нажмите иконку **Настройки** в верхней части главного экрана, либо выберите **Настройки** в нижнем меню.",
                                "en": "Tap the **Settings** icon at the top of the home screen, or pick **Settings** from the bottom navigation.",
                            }),
                            _image_placeholder(
                                "screenshot_settings_entry",
                                caption={"uz": "Sozlamalar sahifasi", "ru": "Страница настроек", "en": "Settings page"},
                            ),
                        ],
                    ),
                    SeedSection(
                        anchor="change-language",
                        title={"uz": "Tilni o'zgartirish", "ru": "Сменить язык", "en": "Change language"},
                        blocks=[
                            _list({
                                "uz": [
                                    "Sozlamalar → **Interfeys** tabini oching",
                                    "Til menyusidan **O'zbek / Русский / English** tanlang",
                                    "Ilova darhol yangi tilga o'tadi",
                                ],
                                "ru": [
                                    "Настройки → откройте таб **Интерфейс**",
                                    "В меню языка выберите **O'zbek / Русский / English**",
                                    "Приложение мгновенно переключится",
                                ],
                                "en": [
                                    "Settings → open the **Interface** tab",
                                    "Pick **O'zbek / Русский / English** from the language menu",
                                    "The app switches instantly",
                                ],
                            }),
                        ],
                    ),
                    SeedSection(
                        anchor="change-theme",
                        title={"uz": "Temani o'zgartirish", "ru": "Сменить тему", "en": "Change theme"},
                        blocks=[
                            _paragraph({
                                "uz": "**Interfeys** tabidagi Light / Dark to'lqinli tugmasi temani almashtiradi. Quyosh ostida ekran yaxshi ko'rinmasa, Light temani tanlang.",
                                "ru": "Переключатель Light / Dark на табе **Интерфейс** меняет тему. Если экран плохо виден на солнце — выберите Light.",
                                "en": "The Light / Dark toggle on the **Interface** tab swaps theme. If the screen is hard to read in direct sun, switch to Light.",
                            }),
                        ],
                    ),
                ],
            ),
            SeedDocument(
                slug="loyiha-tanlash",
                doc_type=DocType.MANUAL,
                is_pinned=False,
                title={
                    "uz": "Loyihani (project) tanlash",
                    "ru": "Выбор проекта",
                    "en": "Choosing the project",
                },
                summary={
                    "uz": "Bir nechta loyihalarda ishlovchilar uchun faol loyihani tanlash",
                    "ru": "Для тех, кто работает в нескольких проектах — выбор активного",
                    "en": "Active project selection for multi-project users",
                },
                sections=[
                    SeedSection(
                        anchor="project-overview",
                        title={"uz": "Loyiha tushunchasi", "ru": "Что такое проект", "en": "What is a project"},
                        blocks=[
                            _paragraph({
                                "uz": "Loyiha — bu mijozlar guruhi va ularning shartnomalarini ajratish uchun ishlatiladi. Bir savdo vakili bir vaqtning o'zida bitta loyihada ishlaydi.",
                                "ru": "Проект — это группировка клиентов и их договоров. Торговый представитель в один момент работает только в одном проекте.",
                                "en": "A project groups customers and contracts. A sales rep works in exactly one active project at a time.",
                            }),
                            _callout("info", {
                                "uz": "Faol loyiha har bir buyurtma, mijoz, va hisobotda hisobga olinadi.",
                                "ru": "Активный проект учитывается в каждом заказе, клиенте и отчёте.",
                                "en": "The active project is applied to every order, customer, and report.",
                            }),
                        ],
                    ),
                    SeedSection(
                        anchor="pick-project",
                        title={"uz": "Loyihani tanlash", "ru": "Выбор проекта", "en": "Pick a project"},
                        blocks=[
                            _list({
                                "uz": [
                                    "Sozlamalar → **Loyihalar** tabini oching",
                                    "Sizga biriktirilgan loyihalar ro'yxati ko'rinadi",
                                    "Faol loyiha rangi bilan ajralib turadi",
                                    "Boshqa loyihaga o'tish uchun shunchaki uni bosing",
                                ],
                                "ru": [
                                    "Настройки → откройте таб **Проекты**",
                                    "Появится список проектов, назначенных вам",
                                    "Активный проект выделен цветом",
                                    "Чтобы переключиться — просто нажмите на нужный проект",
                                ],
                                "en": [
                                    "Settings → open the **Projects** tab",
                                    "A list of assigned projects appears",
                                    "The active project is highlighted",
                                    "Tap another project to switch",
                                ],
                            }),
                            _image_placeholder(
                                "screenshot_projects_tab",
                                caption={"uz": "Loyihalar tabi", "ru": "Таб проектов", "en": "Projects tab"},
                            ),
                        ],
                    ),
                ],
            ),
        ],
    ),

    # =====================================================================
    # 2. Customers (Trading Points)
    # =====================================================================
    SeedCategory(
        slug="savdo-vakili-mijozlar",
        icon="👥",
        color=None,
        order=2,
        name={
            "uz": "Mijozlar (Trading Points)",
            "ru": "Клиенты (Trading Points)",
            "en": "Customers (Trading Points)",
        },
        description={
            "uz": "Mijozlar ro'yxati, qidirish, yangi mijoz, balans va xarita",
            "ru": "Список клиентов, поиск, добавление, баланс и карта",
            "en": "Customers list, search, creation, balance, and map",
        },
        documents=[
            SeedDocument(
                slug="mijozlar-royxati",
                doc_type=DocType.MANUAL,
                is_pinned=True,
                title={
                    "uz": "Mijozlar ro'yxati va qidirish",
                    "ru": "Список клиентов и поиск",
                    "en": "Customers list and search",
                },
                summary={
                    "uz": "List/Grid ko'rinishi, qidirish va filtrlash",
                    "ru": "Режимы List/Grid, поиск и фильтрация",
                    "en": "List/Grid view, search, and filtering",
                },
                sections=[
                    SeedSection(
                        anchor="list-overview",
                        title={"uz": "Asosiy ko'rinish", "ru": "Основной вид", "en": "Main view"},
                        blocks=[
                            _paragraph({
                                "uz": "Mijozlar sahifasi sizga biriktirilgan barcha mijozlarni ko'rsatadi. Yuqori o'ng tomondagi tugmadan **List** yoki **Grid** ko'rinishini tanlash mumkin.",
                                "ru": "Страница «Клиенты» показывает всех закреплённых за вами клиентов. Кнопка в правом верхнем углу переключает **List** или **Grid**.",
                                "en": "The Customers page shows everyone assigned to you. The button in the top-right toggles between **List** and **Grid** view.",
                            }),
                            _image_placeholder(
                                "screenshot_clients_list",
                                caption={"uz": "Mijozlar ro'yxati", "ru": "Список клиентов", "en": "Customers list"},
                            ),
                        ],
                    ),
                    SeedSection(
                        anchor="search-filter",
                        title={"uz": "Qidirish va filtrlash", "ru": "Поиск и фильтры", "en": "Search and filters"},
                        blocks=[
                            _list({
                                "uz": [
                                    "Yuqori panelda **🔍 qidirish** maydoni bor",
                                    "Mijoz nomi yoki kodini kiriting — natija real vaqtda yangilanadi",
                                    "Lotin va Kirill harflari avtomatik tanib olinadi",
                                    "Filter tugmasi orqali viloyat va status bo'yicha tanlang",
                                ],
                                "ru": [
                                    "В верхней панели есть поле **🔍 поиск**",
                                    "Введите название или код клиента — результат обновляется в реальном времени",
                                    "Латинские и кириллические буквы распознаются автоматически",
                                    "Кнопка фильтра позволяет выбрать по региону и статусу",
                                ],
                                "en": [
                                    "A **🔍 search** field is at the top",
                                    "Type a customer name or code — results update live",
                                    "Latin and Cyrillic letters are recognized automatically",
                                    "The filter button lets you pick by region and status",
                                ],
                            }),
                        ],
                    ),
                    SeedSection(
                        anchor="open-detail",
                        title={"uz": "Mijoz tafsilotlari", "ru": "Детали клиента", "en": "Customer details"},
                        blocks=[
                            _paragraph({
                                "uz": "Mijoz kartochkasiga tegishingiz bilan tafsilot oynasi ochiladi: balans, shartnomalar, telefon, koordinatalar va so'nggi buyurtmalar.",
                                "ru": "При нажатии на карточку клиента открывается окно деталей: баланс, договоры, телефон, координаты, последние заказы.",
                                "en": "Tapping a customer card opens the detail sheet: balance, contracts, phone, coordinates, and recent orders.",
                            }),
                        ],
                    ),
                ],
            ),
            SeedDocument(
                slug="yangi-mijoz",
                doc_type=DocType.MANUAL,
                is_pinned=False,
                title={
                    "uz": "Yangi mijoz qo'shish",
                    "ru": "Добавить нового клиента",
                    "en": "Add a new customer",
                },
                summary={
                    "uz": "Mijoz registratsiya formasi va majburiy maydonlar bo'yicha qo'llanma",
                    "ru": "Форма регистрации клиента и обязательные поля",
                    "en": "Customer registration form and required fields",
                },
                sections=[
                    SeedSection(
                        anchor="start-create",
                        title={"uz": "Qaerdan boshlash", "ru": "С чего начать", "en": "Where to start"},
                        blocks=[
                            _paragraph({
                                "uz": "Mijozlar sahifasining pastki o'ng burchagidagi **+** tugmasini bosing. Yangi mijoz formasi ochiladi.",
                                "ru": "Нажмите кнопку **+** в правом нижнем углу страницы «Клиенты». Откроется форма нового клиента.",
                                "en": "Tap **+** in the bottom-right of the Customers page. The new-customer form opens.",
                            }),
                            _image_placeholder(
                                "screenshot_create_client",
                                caption={"uz": "Yangi mijoz formasi", "ru": "Форма нового клиента", "en": "New customer form"},
                            ),
                        ],
                    ),
                    SeedSection(
                        anchor="required-fields",
                        title={"uz": "Majburiy maydonlar", "ru": "Обязательные поля", "en": "Required fields"},
                        blocks=[
                            _list({
                                "uz": [
                                    "**INN/TIN** — soliq raqami (agar sozlama yoqilgan bo'lsa majburiy)",
                                    "**Nomi** — mijoz do'koni yoki tashkilot nomi",
                                    "**Manzil** — to'liq pochta manzili",
                                    "**Telefon** — kontakt raqam (xalqaro format)",
                                    "**Koordinatalar** — xaritadan tanlash yoki GPS'dan olish",
                                ],
                                "ru": [
                                    "**ИНН/TIN** — налоговый номер (обязателен при включённой настройке)",
                                    "**Название** — магазин или организация",
                                    "**Адрес** — полный почтовый адрес",
                                    "**Телефон** — контактный номер (международный формат)",
                                    "**Координаты** — с карты или из GPS",
                                ],
                                "en": [
                                    "**TIN** — tax number (required if the setting is on)",
                                    "**Name** — store or organization name",
                                    "**Address** — full postal address",
                                    "**Phone** — contact number (international format)",
                                    "**Coordinates** — pick on map or grab from GPS",
                                ],
                            }),
                            _callout("info", {
                                "uz": "Permissions sozlamasida `allowCreationWithoutTIN` yoqilgan bo'lsa, INN majburiy emas.",
                                "ru": "Если в правах включён `allowCreationWithoutTIN`, поле ИНН необязательно.",
                                "en": "If permission `allowCreationWithoutTIN` is on, the TIN field is optional.",
                            }),
                        ],
                    ),
                ],
            ),
            SeedDocument(
                slug="mijoz-balansi",
                doc_type=DocType.REGULATION,
                is_pinned=True,
                title={
                    "uz": "Mijoz balansi va qarz indikatori",
                    "ru": "Баланс клиента и индикатор долга",
                    "en": "Customer balance and debt indicator",
                },
                summary={
                    "uz": "Yashil / sariq / qizil status ranglarining ma'nosi va bloklash holatlari",
                    "ru": "Что означают зелёный / жёлтый / красный статусы и когда блокировка",
                    "en": "Meaning of green / yellow / red statuses and when blocking happens",
                },
                sections=[
                    SeedSection(
                        anchor="status-colors",
                        title={"uz": "Status ranglari", "ru": "Цвета статуса", "en": "Status colors"},
                        blocks=[
                            _list({
                                "uz": [
                                    "🟢 **Yashil** — qarz yo'q yoki limit ichida, buyurtma berish mumkin",
                                    "🟡 **Sariq** — qarz limitga yaqinlashgan, ehtiyot bo'ling",
                                    "🔴 **Qizil** — qarz limitdan oshgan, buyurtma bloklanadi",
                                ],
                                "ru": [
                                    "🟢 **Зелёный** — долга нет либо в пределах лимита, заказ можно создавать",
                                    "🟡 **Жёлтый** — долг близок к лимиту, будьте осторожны",
                                    "🔴 **Красный** — долг превышает лимит, заказ блокируется",
                                ],
                                "en": [
                                    "🟢 **Green** — no debt or within limit, ordering allowed",
                                    "🟡 **Yellow** — debt nearing the limit, take care",
                                    "🔴 **Red** — debt exceeds limit, order is blocked",
                                ],
                            }),
                            _image_placeholder(
                                "screenshot_balance_indicator",
                                caption={"uz": "Balans indikatorlari", "ru": "Индикаторы баланса", "en": "Balance indicators"},
                            ),
                        ],
                    ),
                    SeedSection(
                        anchor="when-blocked",
                        title={"uz": "Bloklash qachon ishlaydi", "ru": "Когда срабатывает блокировка", "en": "When blocking kicks in"},
                        blocks=[
                            _callout("danger", {
                                "uz": "Buyurtma yaratish bosqichida server balansni qayta tekshiradi. Agar qarz limitdan oshsa, **DebtBlockedDialog** ochiladi va siz keyingi bosqichga o'ta olmaysiz.",
                                "ru": "При создании заказа сервер заново проверяет баланс. Если долг превышает лимит, открывается **DebtBlockedDialog** и продолжение блокируется.",
                                "en": "When you start creating an order, the server rechecks balance. If debt exceeds the limit, **DebtBlockedDialog** opens and you cannot proceed.",
                            }),
                            _paragraph({
                                "uz": "Qarzni to'lash kerak bo'lsa: mijoz to'lov qiladi → server balansni yangilaydi → siz **Yangilash** tugmasini bosib qaytadan urinasiz.",
                                "ru": "Если нужно погасить долг: клиент оплачивает → сервер обновляет баланс → нажмите **Обновить** и попробуйте снова.",
                                "en": "To clear debt: customer pays → server refreshes balance → tap **Refresh** and try again.",
                            }),
                        ],
                    ),
                ],
            ),
        ],
    ),

    # =====================================================================
    # 3. Visit steps
    # =====================================================================
    SeedCategory(
        slug="savdo-vakili-tashrif",
        icon="📍",
        color=None,
        order=3,
        name={
            "uz": "Tashrif (Visit) bosqichlari",
            "ru": "Этапы визита (Visit)",
            "en": "Visit steps",
        },
        description={
            "uz": "Photo Before, Shelf Audit, Competitor Audit, Buyurtma, Photo After",
            "ru": "Photo Before, Shelf Audit, Competitor Audit, Заказ, Photo After",
            "en": "Photo Before, Shelf Audit, Competitor Audit, Order, Photo After",
        },
        documents=[
            SeedDocument(
                slug="tashrif-boshlash",
                doc_type=DocType.TRAINING,
                is_pinned=False,
                title={
                    "uz": "Tashrifni boshlash",
                    "ru": "Начало визита",
                    "en": "Starting a visit",
                },
                summary={
                    "uz": "Mijozga kelganda qanday qadamlar ketma-ketligi",
                    "ru": "Последовательность действий при визите к клиенту",
                    "en": "Order of operations on arriving at a customer",
                },
                sections=[
                    SeedSection(
                        anchor="arrival",
                        title={"uz": "Kelish", "ru": "Прибытие", "en": "Arrival"},
                        blocks=[
                            _paragraph({
                                "uz": "Mijoz kartochkasidan **Tashrifni boshlash** tugmasini bosing. Tashrif vaqti hisoblana boshlaydi va step ketma-ketligi ochiladi.",
                                "ru": "В карточке клиента нажмите **Начать визит**. Запускается таймер визита и открывается последовательность шагов.",
                                "en": "On the customer card, tap **Start visit**. The visit timer starts and the step sequence opens.",
                            }),
                            _image_placeholder(
                                "screenshot_visit_start",
                                caption={"uz": "Tashrif boshi", "ru": "Старт визита", "en": "Visit start"},
                            ),
                        ],
                    ),
                    SeedSection(
                        anchor="strict-sequence",
                        title={"uz": "Qadamlar ketma-ketligi", "ru": "Последовательность шагов", "en": "Step ordering"},
                        blocks=[
                            _callout("info", {
                                "uz": "Permissionda `strict_sequence` yoqilgan bo'lsa, qadamlarni faqat tartib bilan bajarish mumkin. Aks holda har qaysi bosqichni alohida ochish mumkin.",
                                "ru": "Если в правах включён `strict_sequence`, шаги выполняются строго по порядку. Иначе можно открывать любой этап отдельно.",
                                "en": "If permission `strict_sequence` is on, you must complete steps in order. Otherwise any step can be opened on its own.",
                            }),
                        ],
                    ),
                ],
            ),
            SeedDocument(
                slug="photo-before",
                doc_type=DocType.TRAINING,
                is_pinned=False,
                title={
                    "uz": "Photo Before (fasad surati)",
                    "ru": "Photo Before (фото фасада)",
                    "en": "Photo Before (storefront photo)",
                },
                summary={
                    "uz": "Tashrif boshida fasad va vitrina surati",
                    "ru": "Фото фасада и витрины в начале визита",
                    "en": "Storefront and shelf photo at visit start",
                },
                sections=[
                    SeedSection(
                        anchor="goal",
                        title={"uz": "Maqsad", "ru": "Цель", "en": "Goal"},
                        blocks=[
                            _paragraph({
                                "uz": "Photo Before — bu mijozga kirgan paytdagi vitrina holatini qayd qilish. Bu rasm shelf audit bilan birga statistikaga tushadi.",
                                "ru": "Photo Before фиксирует состояние витрины на момент прихода. Снимок используется в статистике вместе с shelf audit.",
                                "en": "Photo Before captures the shelf state at arrival. The image feeds into statistics together with the shelf audit.",
                            }),
                            _image_placeholder(
                                "screenshot_photo_before",
                                caption={"uz": "Photo Before sahifasi", "ru": "Страница Photo Before", "en": "Photo Before page"},
                            ),
                        ],
                    ),
                    SeedSection(
                        anchor="how-to",
                        title={"uz": "Qanday qilish", "ru": "Как сделать", "en": "How to do it"},
                        blocks=[
                            _list({
                                "uz": [
                                    "Mahsulot peshtaxtasi to'la ko'rinadigan masofada turing",
                                    "**📷 Olish** tugmasini bosing",
                                    "Suratni ko'rib, ma'qul bo'lsa **Saqlash** ni bosing",
                                    "Yo'q bo'lsa **Qayta olish** orqali yangidan oling",
                                ],
                                "ru": [
                                    "Встаньте так, чтобы прилавок попал полностью в кадр",
                                    "Нажмите **📷 Снять**",
                                    "Просмотрите фото, если устраивает — **Сохранить**",
                                    "Иначе **Пересъёмка** и снимайте заново",
                                ],
                                "en": [
                                    "Position yourself so the whole shelf fits in frame",
                                    "Tap **📷 Capture**",
                                    "Review and tap **Save** if it looks right",
                                    "Otherwise **Retake** and try again",
                                ],
                            }),
                        ],
                    ),
                ],
            ),
            SeedDocument(
                slug="shelf-audit",
                doc_type=DocType.TRAINING,
                is_pinned=False,
                title={
                    "uz": "Shelf Audit (peshtaxta inventarizatsiyasi)",
                    "ru": "Shelf Audit (инвентаризация витрины)",
                    "en": "Shelf Audit (shelf inventory)",
                },
                summary={
                    "uz": "Peshtaxtadagi mahsulot mavjudligi va holati",
                    "ru": "Наличие и состояние товаров на витрине",
                    "en": "On-shelf product availability and state",
                },
                sections=[
                    SeedSection(
                        anchor="overview",
                        title={"uz": "Tushuncha", "ru": "Описание", "en": "Overview"},
                        blocks=[
                            _paragraph({
                                "uz": "Mijozning peshtaxtasidagi har bir SKU bo'yicha mavjudlik, miqdor va narxni belgilang. Bu ma'lumot keyingi buyurtmani aniqlash uchun zarur.",
                                "ru": "По каждому SKU на витрине клиента отметьте наличие, количество и цену. Эти данные нужны для формирования следующего заказа.",
                                "en": "For every SKU on the shelf, mark presence, quantity, and price. This drives the next order.",
                            }),
                        ],
                    ),
                    SeedSection(
                        anchor="tips",
                        title={"uz": "Maslahatlar", "ru": "Советы", "en": "Tips"},
                        blocks=[
                            _callout("success", {
                                "uz": "Mahsulotni nomi bilan emas, **shtrix-kod** bilan tanish tezroq.",
                                "ru": "Сканируйте товары по **штрих-коду** — быстрее, чем искать по названию.",
                                "en": "Scan products by **barcode** — faster than searching by name.",
                            }),
                        ],
                    ),
                ],
            ),
            SeedDocument(
                slug="buyurtma-yaratish",
                doc_type=DocType.MANUAL,
                is_pinned=True,
                title={
                    "uz": "Buyurtma yaratish",
                    "ru": "Создание заказа",
                    "en": "Creating an order",
                },
                summary={
                    "uz": "Tashrif ichida buyurtmani to'g'ri rasmiylashtirish",
                    "ru": "Правильное оформление заказа внутри визита",
                    "en": "Properly composing an order inside a visit",
                },
                sections=[
                    SeedSection(
                        anchor="pick-org",
                        title={"uz": "Tashkilot va ombor tanlash", "ru": "Выбор организации и склада", "en": "Pick organization and warehouse"},
                        blocks=[
                            _list({
                                "uz": [
                                    "Buyurtma sahifasining yuqorisida **Organizatsiya** tanlanadi",
                                    "**Ombor** — qaysi sklad orqali yetkazib beriladi",
                                    "**Narx turi** — distribyutor / chakana / aksiya",
                                    "**Yetkazib berish sanasi** — kun va vaqt",
                                ],
                                "ru": [
                                    "В верхней части страницы заказа выберите **Организацию**",
                                    "**Склад** — с какого склада отгружаем",
                                    "**Тип цены** — дистрибьютор / розница / акция",
                                    "**Дата доставки** — день и время",
                                ],
                                "en": [
                                    "Pick the **Organization** at the top of the order page",
                                    "**Warehouse** — where the goods ship from",
                                    "**Price type** — distributor / retail / promo",
                                    "**Delivery date** — day and time",
                                ],
                            }),
                            _image_placeholder(
                                "screenshot_create_order",
                                caption={"uz": "Buyurtma yaratish sahifasi", "ru": "Страница создания заказа", "en": "Create order page"},
                            ),
                        ],
                    ),
                    SeedSection(
                        anchor="add-products",
                        title={"uz": "Mahsulotlarni qo'shish", "ru": "Добавление товаров", "en": "Adding products"},
                        blocks=[
                            _paragraph({
                                "uz": "Mahsulotlar ro'yxatidan kerakli SKU ni tanlang yoki shtrix-kod skanerlashdan foydalaning. Miqdorni kiriting. Tizim avtomatik tarzda jami summa va og'irlikni hisoblaydi.",
                                "ru": "Выберите SKU из списка товаров или используйте сканер штрих-кода. Введите количество — сумма и вес посчитаются автоматически.",
                                "en": "Pick a SKU from the product list or use the barcode scanner. Enter quantity; total and weight calculate automatically.",
                            }),
                            _callout("warn", {
                                "uz": "Buyurtma yaratishdan oldin balans tekshiruvi avtomatik ravishda ishlaydi. Qarz limitdan oshgan mijozga buyurtma yaratib bo'lmaydi.",
                                "ru": "Перед созданием заказа автоматически проверяется баланс. Клиенту с превышенным долгом заказ создать нельзя.",
                                "en": "A balance check runs automatically before order creation. Customers over their debt limit cannot be ordered for.",
                            }),
                        ],
                    ),
                ],
            ),
        ],
    ),

    # =====================================================================
    # 4. Sync
    # =====================================================================
    SeedCategory(
        slug="savdo-vakili-sinxronizatsiya",
        icon="🔄",
        color=None,
        order=4,
        name={"uz": "Sinxronizatsiya", "ru": "Синхронизация", "en": "Sync"},
        description={
            "uz": "Manual va background sync, offline rejim",
            "ru": "Ручная и фоновая синхронизация, offline режим",
            "en": "Manual & background sync, offline mode",
        },
        documents=[
            SeedDocument(
                slug="manual-sync",
                doc_type=DocType.MANUAL,
                is_pinned=False,
                title={"uz": "Manual sinxronizatsiya", "ru": "Ручная синхронизация", "en": "Manual sync"},
                summary={
                    "uz": "Sync All tugmasi va per-table sync ko'rinishi",
                    "ru": "Кнопка Sync All и статус по таблицам",
                    "en": "Sync All button and per-table progress",
                },
                sections=[
                    SeedSection(
                        anchor="how-to-sync",
                        title={"uz": "Sinxronlash", "ru": "Синхронизация", "en": "Sync"},
                        blocks=[
                            _paragraph({
                                "uz": "Sozlamalar → **Ma'lumotlar sinxronizatsiyasi** tabini oching. **Sync All** tugmasi barcha jadvallarni serverdan yangilaydi.",
                                "ru": "Откройте Настройки → таб **Синхронизация данных**. **Sync All** обновляет все таблицы с сервера.",
                                "en": "Open Settings → **Data sync** tab. **Sync All** pulls every table from the server.",
                            }),
                            _image_placeholder(
                                "screenshot_sync_tab",
                                caption={"uz": "Sync tabi", "ru": "Таб синхронизации", "en": "Sync tab"},
                            ),
                        ],
                    ),
                    SeedSection(
                        anchor="when-to-sync",
                        title={"uz": "Qachon sync qilish kerak", "ru": "Когда синхронизировать", "en": "When to sync"},
                        blocks=[
                            _list({
                                "uz": [
                                    "Kun boshida (mijozlar, narxlar, omborlar yangilanadi)",
                                    "Kun oxirida (buyurtmalarni serverga yuborish)",
                                    "Yangi mijoz qo'shganda",
                                    "Internet sifati yaxshi bo'lganda",
                                ],
                                "ru": [
                                    "В начале дня (обновятся клиенты, цены, склады)",
                                    "В конце дня (заказы уйдут на сервер)",
                                    "После добавления нового клиента",
                                    "При хорошем интернете",
                                ],
                                "en": [
                                    "At the start of the day (clients, prices, warehouses refresh)",
                                    "At the end of the day (orders push to server)",
                                    "After adding a new customer",
                                    "When you have a good connection",
                                ],
                            }),
                        ],
                    ),
                ],
            ),
            SeedDocument(
                slug="offline-rejim",
                doc_type=DocType.MANUAL,
                is_pinned=False,
                title={"uz": "Offline rejimda ishlash", "ru": "Работа в offline режиме", "en": "Working offline"},
                summary={
                    "uz": "Internetsiz buyurtma yaratish va keyin sync qilish",
                    "ru": "Создание заказа без интернета и последующий sync",
                    "en": "Creating orders without internet and syncing later",
                },
                sections=[
                    SeedSection(
                        anchor="what-works",
                        title={"uz": "Nima ishlaydi", "ru": "Что работает", "en": "What works"},
                        blocks=[
                            _paragraph({
                                "uz": "Internet bo'lmaganda ham siz mavjud mijozlar bilan ishlay olasiz: yangi buyurtma yarating, suratlar oling, shelf audit qiling. Hammasi local kesh ichida saqlanadi.",
                                "ru": "Даже без интернета можно работать с уже синхронизированными клиентами: создавать заказы, делать фото, заполнять shelf audit. Всё хранится в локальном кэше.",
                                "en": "Without internet you can still work with synced customers: create orders, take photos, complete the shelf audit. Everything is stored in the local cache.",
                            }),
                            _callout("info", {
                                "uz": "Internet qaytganida avtomatik tarzda **background sync** ishlay boshlaydi va navbatdagi buyurtmalarni serverga yuboradi.",
                                "ru": "Когда интернет вернётся, автоматически запустится **фоновая синхронизация**, отправит очередь заказов на сервер.",
                                "en": "When the internet returns, **background sync** automatically pushes queued orders to the server.",
                            }),
                        ],
                    ),
                ],
            ),
        ],
    ),

    # =====================================================================
    # 5. Reports & references
    # =====================================================================
    SeedCategory(
        slug="savdo-vakili-hisobotlar",
        icon="📊",
        color=None,
        order=5,
        name={
            "uz": "Hisobotlar va ma'lumotnomalar",
            "ru": "Отчёты и справочники",
            "en": "Reports & references",
        },
        description={
            "uz": "Buyurtmalar tarixi, hisobotlar, narxlar, omborlar",
            "ru": "История заказов, отчёты, цены, склады",
            "en": "Order history, reports, prices, warehouses",
        },
        documents=[
            SeedDocument(
                slug="orders-history",
                doc_type=DocType.MANUAL,
                is_pinned=False,
                title={"uz": "Buyurtmalar tarixi", "ru": "История заказов", "en": "Order history"},
                summary={
                    "uz": "Kun, hafta, oy bo'yicha barcha buyurtmalarni ko'rish",
                    "ru": "Все заказы по дням, неделям, месяцам",
                    "en": "All orders by day, week, month",
                },
                sections=[
                    SeedSection(
                        anchor="orders-page",
                        title={"uz": "Buyurtmalar sahifasi", "ru": "Страница заказов", "en": "Orders page"},
                        blocks=[
                            _paragraph({
                                "uz": "Bosh menyudan **Buyurtmalar** ni oching. Filter orqali sana oralig'ini, status va mijozni tanlay olasiz.",
                                "ru": "В главном меню откройте **Заказы**. Через фильтр выберите период, статус и клиента.",
                                "en": "Open **Orders** from the main menu. Filter by date range, status, and customer.",
                            }),
                            _image_placeholder(
                                "screenshot_orders_page",
                                caption={"uz": "Buyurtmalar ro'yxati", "ru": "Список заказов", "en": "Orders list"},
                            ),
                        ],
                    ),
                ],
            ),
            SeedDocument(
                slug="narxlar-omborlar",
                doc_type=DocType.MANUAL,
                is_pinned=False,
                title={"uz": "Narxlar va omborlar", "ru": "Цены и склады", "en": "Prices & warehouses"},
                summary={
                    "uz": "Ma'lumotnomalardan foydalanish",
                    "ru": "Как использовать справочники",
                    "en": "Using reference data",
                },
                sections=[
                    SeedSection(
                        anchor="prices",
                        title={"uz": "Narxlar", "ru": "Цены", "en": "Prices"},
                        blocks=[
                            _paragraph({
                                "uz": "**Narxlar** sahifasi har bir mahsulot uchun chakana, distribyutor va aksiya narxlarini ko'rsatadi. Bu narxlar buyurtma yaratishda ishlatiladi.",
                                "ru": "Страница **Цены** показывает розничные, дистрибьюторские и акционные цены по каждому товару. Они применяются при создании заказа.",
                                "en": "The **Prices** page shows retail, distributor, and promo prices per product. These are applied when creating an order.",
                            }),
                        ],
                    ),
                    SeedSection(
                        anchor="warehouses",
                        title={"uz": "Omborlar", "ru": "Склады", "en": "Warehouses"},
                        blocks=[
                            _paragraph({
                                "uz": "Omborlar sahifasida har bir skladdagi mavjud mahsulot va qoldiqlarni ko'ra olasiz.",
                                "ru": "На странице складов виден остаток товаров по каждому складу.",
                                "en": "The warehouses page shows on-hand inventory per warehouse.",
                            }),
                        ],
                    ),
                ],
            ),
        ],
    ),
]
