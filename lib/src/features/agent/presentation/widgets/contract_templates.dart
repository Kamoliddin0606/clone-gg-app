import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_contract.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';

class ContractTemplates {
  static Widget buildUzbekContract({
    required ThemeData theme,
    required ClientContractWithName contract,
    required bool isCreditContract,
    required String creditPercent,
    TradingPoint? clientData,
    String? organizationName,
  }) {
    final clientName = clientData?.name ?? contract.clientName ?? contract.codeClient;
    final ownerName = clientData?.ownerName ?? "_________________";
    final docBasis = clientData?.tradePointType == "ИП" ? "YaTT ro'yxatdan o'tkazish guvohnomasi" : "Ustav";
    final orgName = organizationName ?? '"GLORIYA MARKETING" MChJ';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'TOVARLARNI YETKAZIB BERISH SHARTNOMASI № ${contract.codeContract}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Toshkent sh.', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87)),
            Text(
              contract.dateOfContract != null ? DateFormat('dd.MM.yyyy').format(contract.dateOfContract!) : '___.___.______',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _p(theme, '     $orgName keyingi o\'rinlarda «Yetkazib beruvchi» deb ataluvchi, Ustav asosida faoliyat yurituvchi direktor Ortikov A.Sh. nomidan bir tomondan, va $clientName keyingi o\'rinlarda «Xaridor» deb ataluvchi, $docBasis asosida faoliyat yurituvchi $ownerName nomidan ikkinchi tomondan, birgalikda keyingi o\'rinlarda «Tomonlar», alohida «Tomon» deb atalib, quyidagilar to\'g\'risida mazkur Shartnomani tuzdilar:'),
        const SizedBox(height: 16),
        
        // 1-BO'LIM
        _h(theme, '1. Shartnoma predmeti'),
        _p(theme, '     1.1. Xaridor qo\'yilgan Buyurtmalarga muvofiq to\'lashga va «parfyumeriya-kosmetika vositalari assortimentda» (keyingi o\'rinlarda – Tovar) tovarni qabul qilishga majbur bo\'ladi, uning nomi, miqdori, o\'lchov birliklari, narxi va qiymati, shu jumladan QQS (O\'zR qonunchiligiga muvofiq amal qiluvchi stavkalar hisobga olingan holda), mazkur Shartnomaga ilova qilingan yuk xatlari va hisob-fakturalarida belgilanadi, Yetkazib beruvchi esa mazkur Shartnoma shartlariga muvofiq Tovarni Xaridor mulkiga topshirishga majbur bo\'ladi.'),
        _p(theme, '     1.2. Har bir partiyaning miqdori, assortimenti va qiymati Tomonlar tomonidan Buyurtmalarda, tovar-transport yuk xatlarida va hisob-fakturalarida belgilanadi, ularning har biri Tomonlarning vakolatli vakillari imzolagan va muhr bilan tasdiqlangan (mavjud bo\'lsa) holda mazkur Shartnomaning ajralmas qismi hisoblanadi.'),
        _p(theme, '     1.3. Xaridor Tovarni O\'zbekiston Respublikasi amaldagi qonunchilik normalariga rioya qilgan holda yakuniy iste\'molchiga sotishga majbur bo\'ladi. Bunday tartibga rioya qilmaslik uchun Xaridor javobgar bo\'ladi.'),
        _p(theme, '     1.4. Mazkur Shartnomaning umumiy summasi tuzilgan yuk xatlari va hisob-fakturalarining umumiy summalaridan tashkil topadi.'),
        const SizedBox(height: 12),
        
        // 2-BO'LIM
        _h(theme, '2. To\'lov shartlari'),
        if (isCreditContract) ...[
          _p(theme, '     2.1. Xaridor Buyurtma imzolangan kundan keyingi kundan boshlab 3 (uch) bank kuni ichida yetkazib beriladigan tovar uchun $creditPercent% miqdorida (lekin tovar buyurtmasi summasining kamida 30% dan kam bo\'lmagan) oldindan to\'lovni amalga oshiradi. Sotuvchi tomonidan pul mablag\'larini olish sanasi vakolatli bank tomonidan pul mablag\'larini Sotuvchi hisob raqamiga o\'tkazilgan bank kuni hisoblanadi.'),
          _p(theme, '     Yakuniy hisob-kitob Buyurtma to\'lovga qo\'yilgan paytdan boshlab 14 (o\'n to\'rt) kalendar kun ichida amalga oshiriladi.'),
          _p(theme, '     Tovarlar uchun to\'lov bo\'yicha qarzdorlik har qanday holatda yetkazib berish amalga oshirilgan joriy oyning 30 (31) sanasigacha, ya\'ni oxirgi kunigacha to\'lanishi kerak.'),
        ] else ...[
          _p(theme, '     2.1. Xaridor Buyurtma imzolangan kundan keyingi kundan boshlab 3 (uch) bank kuni ichida yetkazib beriladigan tovar uchun 100% oldindan to\'lovni amalga oshiradi. Sotuvchi tomonidan pul mablag\'larini olish sanasi vakolatli bank tomonidan pul mablag\'larini Sotuvchi hisob raqamiga o\'tkazilgan bank kuni hisoblanadi.'),
        ],
        _p(theme, '     2.2. To\'lov Xaridor tomonidan to\'lov topshiriqnomasi asosida, O\'zR milliy valyutasida – so\'mda naqdsiz pul mablag\'larini mazkur Shartnomaning 9-bo\'limida ko\'rsatilgan Yetkazib beruvchi hisobiga to\'g\'ridan-to\'g\'ri bank o\'tkazmasi yo\'li bilan amalga oshiriladi.'),
        _p(theme, '     2.3. Buyurtmada ko\'rsatilgan Tovar qiymati ushbu Tovar partiyasi uchun yakuniy hisoblanadi va mazkur Shartnomaning 2.1-bandida belgilangan Tovar to\'lovi shartlariga Xaridor tomonidan rioya qilingan taqdirda o\'zgartirilmaydi.'),
        if (isCreditContract) ...[
          _p(theme, '     2.4. Agar Xaridor Buyurtmani imzolagandan so\'ng Shartnomaning 2.1-bandiga muvofiq to\'lovni amalga oshirmasa, Yetkazib beruvchi bir tomonlama tartibda yetkazib berish muddatlari, shartlari, yetkazib beriladigan Tovar miqdori va qiymatini o\'zgartirish huquqini o\'zida saqlab qoladi.'),
          _p(theme, '     Agar tovar uchun to\'lov qoldig\'i Shartnomaning 2.1-bandiga muvofiq to\'lanmasa, oldindan to\'langan keyingi tovar partiyasining barcha keyingi sotuvlari va jo\'natishlari mavjud qarzdorlik to\'liq to\'languniga qadar to\'xtatiladi.'),
        ],
        _p(theme, '     2.5. Agar Xaridor Yetkazib beruvchi hisob raqamiga pul mablag\'larini o\'tkazishda xatoga yo\'l qo\'ysa; to\'lov tafsilotlarida shartnoma raqami yoki sanasini noto\'g\'ri ko\'rsatsa, mazkur Shartnomaning 8.4 va 8.5-bandlari talablariga mos kelmaganda, Yetkazib beruvchi pul mablag\'larini Xaridorga qaytarish va Tovarni jo\'natishni to\'xtatib turish huquqiga ega.'),
        _p(theme, '     2.6. Pul mablag\'larini qaytarish bo\'yicha bank xarajatlari Xaridor hisobiga yuklanadi.'),
        const SizedBox(height: 12),
        
        // 3-BO'LIM
        _h(theme, '3. Yetkazib berish shartlari'),
        _p(theme, '     3.1. Tovarni yetkazib berish Tomonlar tomonidan tasdiqlangan Tovar partiyasiga Buyurtmalarga muvofiq amalga oshiriladi, ularda Tovar assortimenti, miqdori, narxi va qiymati, shu jumladan QQS (O\'zR qonunchiligiga muvofiq amal qiluvchi stavkalar hisobga olingan holda) aks ettiriladi.'),
        _p(theme, '     3.2. Sotuvchi Xaridor tomonidan mazkur Shartnomaning 2.1-bandiga muvofiq oldindan to\'lov amalga oshirilgandan so\'ng o\'n bank kuni ichida va faqat mazkur Shartnomaning 1.1-bandida ko\'rsatilgan hajmda tovarni jo\'natadi.'),
        _p(theme, '     3.3. Tovarni Xaridorning savdo nuqtasiga yetkazib berish Sotuvchi kuchlari va hisobidan amalga oshiriladi. Tovarni yuklash va tushirish ham Sotuvchi kuchlari va vositalari hamda uning hisobidan amalga oshiriladi, transport xarajatlari Sotuvchi hisobiga yuklanadi.'),
        _p(theme, '     3.4. Yetkazib berish sanasi Xaridor tomonidan Sotuvchidan Tovarni qabul qilish-topshirish va tegishli tovar partiyasiga yozilgan yuk hujjatlariga (YX, TTYX, hisob-faktura va h.k.) imzo chekish sanasi hisoblanadi.'),
        _p(theme, '     3.5. Yetkazib beruvchi Tovar bilan birga Xaridorga quyidagi hujjatlarni topshiradi:\n        - tovar muvofiqlik sertifikati;\n        - gigiyenik sertifikat;\n        - buyurtma;\n        - ulgurji savdo huquqiga guvohnoma nusxasi.'),
        _p(theme, '     3.6. Sotuvchi Sotuvchi Tovarining yanada ilgarilanishi va sotuvlarini oshirish maqsadida reklama va tovarni ilgarilatuvchi mahsulotlarni tekin asosda yetkazib berish huquqini o\'zida saqlab qoladi.'),
        const SizedBox(height: 12),
        
        // 4-BO'LIM
        _h(theme, '4. Tovar sifati va miqdori, qabul qilish tartibi'),
        _p(theme, '     4.1. Yetkazib beruvchi Xaridorga yetkazib beriladigan Tovar sifatining tegishli DAVSTlar standartlari va talablariga, sifat sertifikatlariga va O\'zbekiston Respublikasining boshqa me\'yoriy hujjatlariga muvofiqligini kafolatlaydi.'),
        _p(theme, '     4.2. Sotuvchi Xaridorga muddati o\'tgan tovarni sotmaslikka majbur bo\'ladi, Xaridor o\'z navbatida foydalanish muddati o\'tgan Tovarni sotganlik uchun javobgar bo\'ladi.'),
        _p(theme, '     4.3. Tovarning yaroqlilik muddati tegishli O\'zR davlat organlari tomonidan tasdiqlangan ishlab chiqaruvchi zavod standartlari va texnik shartlariga muvofiq belgilanadi va Tovar ishlab chiqarilgan sana/paytdan boshlab hisoblanadi.'),
        _p(theme, '     4.4. Sotuvchi Xaridor tomonidan u yoki bu turdagi tovarlarni saqlash va savdo qilishning belgilangan shartlari buzilganda Tovar sifatining yo\'qolishi uchun javobgar emas.'),
        _p(theme, '     4.5. Tovarni miqdori va sifati bo\'yicha qabul qilish Tovar jo\'natilganda amalga oshiriladi, shundan so\'ng da\'volar ko\'rib chiqilmaydi va qabul qilinmaydi.'),
        _p(theme, '     4.6. Qabul qilish Xaridor vakili tomonidan Tovarni olish uchun belgilangan namunadagi ishonchnoma taqdim etilgandan va Sotuvchi tomonidan yozilgan Spetsifikatsiyaga Xaridor imzo chekkanidan so\'ng yakunlangan hisoblanadi.'),
        _p(theme, '     4.7. Xaridor aybi bilan noto\'g\'ri saqlash natijasida hosil bo\'lgan sifatsiz mahsulot qaytarilmaydi.'),
        _p(theme, '     4.8. Tovar qadoqlanishi O\'zbekiston Respublikasi davlat tilida markirovkani o\'z ichiga olishi kerak.'),
        const SizedBox(height: 12),
        
        // 5-BO'LIM
        _h(theme, '5. Tomonlarning javobgarligi va nizolarni ko\'rib chiqish tartibi'),
        _p(theme, '     5.1. Tomonlar O\'zbekiston Respublikasi amaldagi qonunchiligiga muvofiq mazkur Shartnomadan kelib chiqadigan majburiyatlarni bajarish uchun javobgar bo\'ladilar.'),
        _p(theme, '     5.2. Mazkur Shartnoma tomonlarining javobgarligi O\'zbekiston Respublikasi Fuqarolik kodeksiga, 1998 yil 29 avgustdagi № 670-1 «Xo\'jalik yurituvchi sub\'ektlar faoliyatining shartnoma-huquqiy bazasi to\'g\'risida»gi Qonunning 5-bobiga va O\'zbekiston Respublikasi amaldagi qonunchiligiga muvofiq belgilanadi.'),
        _p(theme, '     5.3. Tovar uchun to\'lov bo\'yicha pul majburiyatini bajarmaslik yoki bajarishni kechiktirish holatida Xaridor Yetkazib beruvchiga to\'lanmagan tovar qiymatining 1% miqdorida penya to\'lashga majbur bo\'ladi.'),
        _p(theme, '     5.4. Jarima sanktsiyalarini qo\'llash Tomonlarning huquqi, majburiyati emas.'),
        _p(theme, '     5.5. Mazkur Shartnoma bilan bog\'liq Xaridor va Sotuvchi o\'rtasida yuzaga keladigan barcha nizolar va kelishmovchiliklar Xaridor va Sotuvchi o\'rtasidagi muzokaralar yo\'li bilan hal qilinadi. Da\'volarni ko\'rib chiqish muddati da\'voni ko\'rib chiqish uchun olingan kundan boshlab 15 (o\'n besh) kalendar kunni tashkil etadi. Kelishmovchiliklarni tinch yo\'l bilan hal qilish imkoni bo\'lmaganda, tomonlar da\'volarni Toshkent shahar Iqtisodiy sudiga ko\'rib chiqish uchun topshiradilar.'),
        const SizedBox(height: 12),
        
        // 6-BO'LIM
        _h(theme, '6. Fors-major'),
        _p(theme, '     6.1. Tomonlar mazkur shartnoma bo\'yicha o\'z majburiyatlarini to\'liq yoki qisman bajarmaslik yengib bo\'lmas kuch holatlari, ya\'ni zilzila, yong\'in, suv toshqini, harbiy harakatlar, fuqarolik tartibsizliklari natijasida yuz bergan bo\'lsa, javobgarlikdan ozod qilinadilar. Mazkur shartnoma bo\'yicha holatlarni bajarish muddati yengib bo\'lmas kuch holatlari amal qilgan davrga mutanosib ravishda ko\'chiriladi. Agar fors-major holatlari 30 ish kuni davom etsa, har bir tomon Shartnomani bir tomonlama bekor qilish haqida ariza berish huquqiga ega.'),
        const SizedBox(height: 12),
        
        // 7-BO'LIM
        _h(theme, '7. Shartnoma amal qilish muddati va uni bekor qilish tartibi'),
        _p(theme, '     7.1. Mazkur Shartnoma tomonlar tomonidan tuzilgan paytdan boshlab kuchga kiradi va mazkur Shartnomadan kelib chiqadigan majburiyatlar tomonlar tomonidan to\'liq bajarilguniga qadar, imzolanganidan boshlab 1 (bir) kalendar yil muddatga amal qiladi.'),
        _p(theme, '     7.2. Shartnoma amal qilish muddati, agar tomonlar shartnomani bekor qilish haqida xabar bermagan bo\'lsa, keyingi o\'xshash muddat uchun avtomatik ravishda uzaytirilgan hisoblanadi.'),
        _p(theme, '     7.3. Mazkur Shartnoma bekor qilishdan oldin 10 (o\'n) kalendar kun oldin tomonlardan birining yozma xabarnomasi bilan bekor qilingan hisoblanadi.'),
        _p(theme, '     7.4. Har bir tomon o\'z rekvizitlarini (joylashuv o\'rni, bank, ro\'yxatga olish) o\'zgartirganda darhol boshqa tomonni yozma ravishda xabardor qilishi shart.'),
        const SizedBox(height: 12),
        
        // 8-BO'LIM
        _h(theme, '8. Yakuniy qoidalar'),
        _p(theme, '     8.1. Mazkur Shartnoma o\'zbek tilida ikki nusxada tuzilgan. Ikkala nusxa bir xil va teng yuridik kuchga ega.'),
        _p(theme, '     8.2. Mazkur Shartnomaga har qanday o\'zgartirishlar va qo\'shimchalar yozma shaklda tuzilgan va Tomonlarning vakolatli vakillari tomonidan imzolangan taqdirda haqiqiy hisoblanadi.'),
        _p(theme, '     8.3. Mazkur Shartnomaning hech bir Tomoni boshqa Tomonning yozma roziligisiz mazkur Shartnomadan kelib chiqadigan yoki uning bajarilishi bilan bog\'liq huquq va majburiyatlarini uchinchi shaxslarga topshirish huquqiga ega emas.'),
        const SizedBox(height: 12),
        
        // 9-BO'LIM
        _h(theme, '9. Yuridik manzillar, bank rekvizitlari'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yetkazib beruvchi:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(orgName, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('Manzil: Toshkent sh.', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('Telefon: +998712370303', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('H/r: 20208000600823324001', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('ATB Infin Bank Toshkent sh.', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('MFO: 01041', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('STIR: 305134937', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('IFUT: 46900', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('QQS RKP: 326020025647', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Xaridor:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(clientName, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('Manzil: ${clientData?.address ?? "_______________"}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('Telefon: ${clientData?.phone ?? "_______________"}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('H/r: _______________', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('_______________', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('MFO: _______________', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('STIR: ${clientData?.inn ?? "_______________"}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('IFUT: _______________', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('QQS RKP: _______________', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // 10-BO'LIM
        _h(theme, '10. Tomonlarning imzolari va muhrlari'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Text('Rahbar', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  const SizedBox(height: 24),
                  Text('Ortikov A.Sh. /_______________/', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('(imzo, muhr)', style: theme.textTheme.labelSmall?.copyWith(color: Colors.black54)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text('Rahbar', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  const SizedBox(height: 24),
                  Text('$ownerName /_______________/', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('(imzo, muhr)', style: theme.textTheme.labelSmall?.copyWith(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  static Widget buildRussianContract({
    required ThemeData theme,
    required ClientContractWithName contract,
    required bool isCreditContract,
    required String creditPercent,
    TradingPoint? clientData,
    String? organizationName,
  }) {
    final clientName = clientData?.name ?? contract.clientName ?? contract.codeClient;
    final ownerName = clientData?.ownerName ?? "_________________";
    final docBasis = clientData?.tradePointType == "ИП" ? "Свидетельства о регистрации ИП" : "Устава";
    final orgName = organizationName ?? '"GLORIYA MARKETING" MChJ';
    // Convert org name to Russian format
    final orgNameRu = orgName.contains('MChJ') ? 'ООО "${orgName.replaceAll('"', '').replaceAll(' MChJ', '').replaceAll('MChJ', '')}"' : orgName;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'ДОГОВОР ПОСТАВКИ ТОВАРОВ № ${contract.codeContract}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('г. Ташкент', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87)),
            Text(
              contract.dateOfContract != null ? DateFormat('dd.MM.yyyy').format(contract.dateOfContract!) : '___.___.______',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _p(theme, '     $orgNameRu именуемое в дальнейшем «Поставщик» в лице директора Ортиков А.Ш., действующего на основании Устава, с одной стороны, и $clientName именуемое в дальнейшем «Покупатель» в лице $ownerName, действующего на основании $docBasis, с другой стороны, вместе именуемые в дальнейшем «Стороны», а по отдельности «Сторона», заключили настоящий Договор о нижеследующем:'),
        const SizedBox(height: 16),
        
        // РАЗДЕЛ 1
        _h(theme, '1. Предмет Договора'),
        _p(theme, '     1.1. Покупатель обязуется оплатить, согласно выставленным Заказам и принять товар «парфюмерно-косметические средства в ассортименте» (далее – Товар), наименование, количество, единицы измерения, цена и стоимость которого, в том числе НДС (применяемых с учетом действующих ставок, согласно законодательства РУз.), определяется в накладных и счет-фактурах к настоящему Договору, а Поставщик обязуется передать в собственность Покупателя Товар на условиях настоящего Договора.'),
        _p(theme, '     1.2. Количество, ассортимент и стоимость каждой партии определяется Сторонами в Заказах, товарно-транспортных накладных и счетах-фактурах, каждая из которых становится неотъемлемой частью настоящего Договора после подписания уполномоченными представителями Сторон и скреплением печатью (при наличии).'),
        _p(theme, '     1.3. Покупатель обязуется продавать Товар конечному потребителю с соблюдением норм действующего законодательства Республики Узбекистан. За несоблюдение такого порядка несет ответственность Покупатель.'),
        _p(theme, '     1.4. Общая сумма настоящего Договора складывается из общих сумм заключенных накладных и счет-фактур.'),
        const SizedBox(height: 12),
        
        // РАЗДЕЛ 2
        _h(theme, '2. Условия оплаты'),
        if (isCreditContract) ...[
          _p(theme, '     2.1. Покупатель производит предварительную оплату товара в размере $creditPercent% (но не менее 30% от суммы заказа товара), объявленного к поставке в течение 3 (трех) банковских дней со дня следующего за днем подписания Заказа. Датой получения денежных средств Продавцом является банковский день зачисления уполномоченным банком денежных средств на расчетный счет Продавца.'),
          _p(theme, '     Окончательный расчет производится в течение 14 (четырнадцати) календарных дней с момента выставления Заказа на оплату.'),
          _p(theme, '     Задолженность по оплате товаров подлежит погашению в любом случае до 30 (31-го) числа, т.е. последнего числа текущего месяца, в котором осуществлялась поставка.'),
        ] else ...[
          _p(theme, '     2.1. Покупатель производит 100% предварительную оплату товара, объявленного к поставке в течение 3 (трех) банковских дней со дня следующего за днем подписания Заказа. Датой получения денежных средств Продавцом является банковский день зачисления уполномоченным банком денежных средств на расчетный счет Продавца.'),
        ],
        _p(theme, '     2.2. Оплата производится Покупателем на основании платежного поручения, путем перечисления безналичных денежных средств в национальной валюте РУз – сум, прямым банковским переводом на счет Поставщика, указанный в разделе 9 настоящего Договора.'),
        _p(theme, '     2.3. Указанная в Заказе стоимость Товара является окончательной для данной партии Товара и не подлежит изменению при условии соблюдения Покупателем условий оплаты Товара, определенными в пункте 2.1. настоящего Договора.'),
        if (isCreditContract) ...[
          _p(theme, '     2.4. В случае если Покупатель после подписания Заказа не осуществит оплату в соответствии с пунктом 2.1. Договора, Поставщик оставляет за собой право в одностороннем порядке изменять сроки, условия поставки, количество и стоимость поставляемого им Товара.'),
          _p(theme, '     Если остаток по оплате товара не будет оплачен согласно п. 2.1. Договора, все последующие продажи товара и отгрузки последующей партии товара, оплаченной по предоплате, приостанавливаются до момента полного погашения имеющейся задолженности.'),
        ],
        _p(theme, '     2.5. В случае если при перечислении денежных средств на расчетный счет Поставщика, Покупатель допустил ошибку; неправильно указал номер или дата договора в деталях платежа, несоответствие требованиям пунктам 8.4 и 8.5 настоящего Договора, то Поставщик вправе вернуть денежные средства Покупателю и приостановить отгрузку Товара.'),
        _p(theme, '     2.6. Банковские расходы по возврату денежных средств относятся на счет Покупателя.'),
        const SizedBox(height: 12),
        
        // РАЗДЕЛ 3
        _h(theme, '3. Условия поставки'),
        _p(theme, '     3.1. Поставка Товара будет осуществляться согласно утвержденным Сторонами Заказам на партию Товара, в которых отражается: ассортимент Товара, его количество, цена и стоимость, в том числе НДС (применяемый с учетом действующих ставок, согласно законодательства РУз).'),
        _p(theme, '     3.2. Продавец осуществляет в течение десяти банковских дней отгрузку товара, только после осуществления Покупателем предварительной оплаты согласно пункту 2.1. настоящего Договора и только в объеме, указанном в пункте 1.1. настоящего Договора.'),
        _p(theme, '     3.3. Отгрузка Товара до торговой точки Покупателя производится силами и за счет Продавца. Погрузка и выгрузка товара, также производится силами и средствами Продавца и за его счет, транспортные расходы относятся на счет Продавца.'),
        _p(theme, '     3.4. Датой поставки считается дата приема-передачи Покупателем Товара от Продавца и подписания товаросопроводительных документов (ТН, ТТН, счет-фактура и т.д.), выписанных на соответствующую партию товара.'),
        _p(theme, '     3.5. Поставщик с Товаром передает Покупателю следующие документы:\n        - сертификат соответствия на товар;\n        - гигиенический сертификат;\n        - заказ;\n        - копию свидетельства на право оптовой торговли.'),
        _p(theme, '     3.6. Продавец оставляет за собой право поставлять рекламную и товар продвигающую продукцию на безвозмездной основе в целях дальнейшего продвижения и увеличения продаж Товара Продавца.'),
        const SizedBox(height: 12),
        
        // РАЗДЕЛ 4
        _h(theme, '4. Качество и количество товара, порядок приемки'),
        _p(theme, '     4.1. Поставщик гарантирует Покупателю соответствие качества поставляемого им Товара стандартам и требованиям соответствующих ГОСТов, сертификатам качества и прочими нормативным документам Республики Узбекистан.'),
        _p(theme, '     4.2. Продавец обязуется не реализовывать Товар Покупателю с просроченным сроком потребления, Покупатель, в свою очередь, несет ответственность за продажу Товара с просроченным сроком его использования.'),
        _p(theme, '     4.3. Срок годности Товара устанавливается по стандартам и техническим условиям завода производителя, утвержденным соответствующими госорганами РУз, и исчисляется с момента/даты производства Товара.'),
        _p(theme, '     4.4. Продавец не несет ответственность за потерю качества Товара при нарушении Покупателем установленных условий хранения и торговли теми или иными видами товара.'),
        _p(theme, '     4.5. Приемка Товара по количеству и качеству производится при отгрузке Товара, после чего, претензии не рассматриваются и не принимаются.'),
        _p(theme, '     4.6. Приемка считается завершенной после предоставления представителем Покупателя доверенности установленного образца на получение Товара и подписания Покупателем Спецификации, выписанной Продавцом.'),
        _p(theme, '     4.7. Некачественная продукция, образовавшаяся в результате неправильного хранения по вине Покупателя, возврату не подлежит.'),
        _p(theme, '     4.8. Упаковка товара должна содержать маркировку на государственном языке Республики Узбекистан.'),
        const SizedBox(height: 12),
        
        // РАЗДЕЛ 5
        _h(theme, '5. Ответственность сторон и порядок рассмотрения споров'),
        _p(theme, '     5.1. Стороны несут ответственность за выполнение обязательств, вытекающих из настоящего Договора в соответствии с действующим законодательством Республики Узбекистан.'),
        _p(theme, '     5.2. Ответственность сторон настоящего Договора определяется в соответствии с Гражданским кодексом Республики Узбекистан, Главой 5 Закона «О договорно-правовой базе деятельности хозяйствующих субъектов» от 29.08.1998 г. № 670-1, и действующим законодательством Республики Узбекистан.'),
        _p(theme, '     5.3. В случае неисполнения, а равно просрочки исполнения денежного обязательства по оплате Товара, Покупатель обязуется выплатить Поставщику пени в размере 1% от стоимости неоплаченного товара.'),
        _p(theme, '     5.4. Предъявление штрафных санкций является правом, а не обязанностью Сторон.'),
        _p(theme, '     5.5. Все споры и разногласия, возникающие между Покупателем и Продавцом в связи с настоящим Договором, разрешаются путем переговоров между Покупателем и Продавцом. Срок рассмотрения претензий составляет 15 (пятнадцать) календарных дней со дня получения претензии для рассмотрения. При невозможности урегулирования разногласий мирным путем, стороны передают претензии на рассмотрение Экономического суда города Ташкента.'),
        const SizedBox(height: 12),
        
        // РАЗДЕЛ 6
        _h(theme, '6. Форс-мажор'),
        _p(theme, '     6.1. Стороны освобождаются от ответственности за полное или частичное неисполнение своих обязательств по настоящему договору, если оно явилось следствием обстоятельств непреодолимой силы, таких как землетрясение, пожар, наводнение, военные действия, гражданские беспорядки. Срок исполнения обстоятельств по настоящему договору отодвигается соразмерно периоду, в течение которого действовали обстоятельства непреодолимой силы. Если обстоятельства форс-мажора продолжаются 30 рабочих дней, то каждая из сторон имеет право заявить об одностороннем расторжении Договора.'),
        const SizedBox(height: 12),
        
        // РАЗДЕЛ 7
        _h(theme, '7. Срок действия Договора и порядок его расторжения'),
        _p(theme, '     7.1. Настоящий Договор вступает в силу с момента заключения его сторонами и действует до полного исполнения своих обязательств сторонами, вытекающими из настоящего Договора, сроком на 1(один) календарный год с момента подписания.'),
        _p(theme, '     7.2. Срок действия договора считается автоматически продлённым на следующий аналогичный по длительности период, в случае если, стороны не уведомили о прекращении договора.'),
        _p(theme, '     7.3. Настоящий Договор считается расторгнутым при письменном уведомлении одной из сторон заблаговременно за 10 (десять) календарных дней до расторжения.'),
        _p(theme, '     7.4. Каждая сторона при изменении своих реквизитов (место нахождения, банковские, регистрационные) обязана незамедлительно письменно известить об этом другую сторону.'),
        const SizedBox(height: 12),
        
        // РАЗДЕЛ 8
        _h(theme, '8. Заключительные положения'),
        _p(theme, '     8.1. Настоящий Договор составлен в двух экземплярах на русском языке. Оба экземпляра идентичны и имеют одинаковую юридическую силу.'),
        _p(theme, '     8.2. Любые изменения и дополнения к настоящему Договору действительны при совершении их в письменном виде и подписании их уполномоченными представителями Сторон.'),
        _p(theme, '     8.3. Ни одна из Сторон настоящего Договора не вправе передать свои права и обязательства, вытекающие из настоящего Договора или связанных с его исполнением, третьим лицам без письменного согласия на это другой Стороны.'),
        const SizedBox(height: 12),
        
        // РАЗДЕЛ 9
        _h(theme, '9. Юридические адреса, банковские реквизиты'),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Поставщик:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(orgNameRu, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('Адрес: г. Ташкент', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('Телефон: +998712370303', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('Р/сч: 20208000600823324001', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('в АКБ Infin Bank город Ташкент', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('МФО: 01041', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('ИНН: 305134937', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('ОКЭД: 46900', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('РКП НДС: 326020025647', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Покупатель:', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 4),
                  Text(clientName, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('Адрес: ${clientData?.address ?? "_______________"}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('Телефон: ${clientData?.phone ?? "_______________"}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('Р/сч: _______________', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('в _______________', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('МФО: _______________', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('ИНН: ${clientData?.inn ?? "_______________"}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('ОКЭД: _______________', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('РКП НДС: _______________', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // РАЗДЕЛ 10
        _h(theme, '10. Подписи и печати сторон'),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  Text('Руководитель', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  const SizedBox(height: 24),
                  Text('Ортиков А.Ш. /_______________/', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('(подпись, печать)', style: theme.textTheme.labelSmall?.copyWith(color: Colors.black54)),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Text('Руководитель', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  const SizedBox(height: 24),
                  Text('$ownerName /_______________/', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87)),
                  Text('(подпись, печать)', style: theme.textTheme.labelSmall?.copyWith(color: Colors.black54)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper methods
  static Widget _h(ThemeData theme, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
  );

  static Widget _p(ThemeData theme, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black87, height: 1.4), textAlign: TextAlign.justify),
  );
}
