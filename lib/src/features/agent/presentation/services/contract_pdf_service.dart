import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_contract.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';

enum ContractPdfLanguage { uzbek, russian }

class ContractPdfService {
  // Cached fonts for reuse
  static pw.Font? _regularFont;
  static pw.Font? _boldFont;

  // Load fonts that support both Latin and Cyrillic characters
  static Future<void> _loadFonts() async {
    if (_regularFont == null) {
      final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
      _regularFont = pw.Font.ttf(regularData);
    }
    if (_boldFont == null) {
      final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
      _boldFont = pw.Font.ttf(boldData);
    }
  }

  static Future<void> generateAndSharePdf({
    required ClientContractWithName contract,
    required ContractPdfLanguage language,
    TradingPoint? clientData,
    String? organizationName,
  }) async {
    // Load fonts with Cyrillic support
    await _loadFonts();
    
    final pdf = pw.Document();
    
    final bool isCreditContract = _isCreditContract(contract.typeContract);
    final String creditPercent = _extractCreditPercent(contract.typeContract);
    
    final clientName = clientData?.name ?? contract.clientName ?? contract.codeClient;
    final ownerName = clientData?.ownerName ?? "_________________";
    final orgName = organizationName ?? '"GLORIYA MARKETING" MChJ';
    
    // Create theme with custom fonts
    final theme = pw.ThemeData.withFont(
      base: _regularFont!,
      bold: _boldFont!,
    );
    
    // Watermark text based on language
    final watermarkText = language == ContractPdfLanguage.uzbek ? 'NUSXA' : 'КОПИЯ';
    
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: theme,
          buildBackground: (context) => pw.FullPage(
            ignoreMargins: true,
            child: pw.Center(
              child: pw.Transform.rotate(
                angle: 0.785398, // 45 degrees in radians (from bottom-left to top-right)
                child: pw.Text(
                  watermarkText,
                  style: pw.TextStyle(
                    font: _boldFont,
                    fontSize: 100,
                    color: PdfColors.grey300,
                  ),
                ),
              ),
            ),
          ),
        ),
        build: (context) => language == ContractPdfLanguage.uzbek
            ? _buildUzbekContent(contract, clientData, clientName, ownerName, isCreditContract, creditPercent, orgName)
            : _buildRussianContent(contract, clientData, clientName, ownerName, isCreditContract, creditPercent, orgName),
      ),
    );

    final Uint8List pdfBytes = await pdf.save();
    
    // Use application documents directory - more reliable for sharing on Android/iOS
    final directory = await getApplicationDocumentsDirectory();
    final contractsDir = Directory('${directory.path}/contracts');
    
    // Create contracts directory if it doesn't exist
    if (!await contractsDir.exists()) {
      await contractsDir.create(recursive: true);
    }
    
    // Clean filename (remove special characters)
    final safeContractCode = contract.codeContract.replaceAll(RegExp(r'[^\w\-]'), '_');
    final String fileName = language == ContractPdfLanguage.uzbek 
        ? 'Shartnoma_$safeContractCode.pdf'
        : 'Dogovor_$safeContractCode.pdf';
    
    final file = File('${contractsDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);
    
    // Verify file exists before sharing
    if (!await file.exists()) {
      throw Exception('PDF fayl yaratilmadi');
    }

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      text: language == ContractPdfLanguage.uzbek 
          ? 'Shartnoma № ${contract.codeContract}'
          : 'Договор № ${contract.codeContract}',
    );
  }

  static bool _isCreditContract(String? t) => t != null && t.isNotEmpty && 
      (t.toLowerCase().contains('кредит') || t.toLowerCase().contains('kredit') || 
       t.toLowerCase().contains('рассрочк') || 
       (!t.toLowerCase().contains('100%') && !t.toLowerCase().contains('предоплат')));
  
  static String _extractCreditPercent(String? t) {
    if (t == null) return '30';
    final m = RegExp(r'(\d+)\s*%').firstMatch(t);
    return m?.group(1) ?? '30';
  }

  static List<pw.Widget> _buildUzbekContent(
    ClientContractWithName contract,
    TradingPoint? clientData,
    String clientName,
    String ownerName,
    bool isCreditContract,
    String creditPercent,
    String orgName,
  ) {
    final docBasis = clientData?.tradePointType == "ИП" ? "YaTT ro'yxatdan o'tkazish guvohnomasi" : "Ustav";
    final dateStr = contract.dateOfContract != null 
        ? DateFormat('dd.MM.yyyy').format(contract.dateOfContract!) 
        : '___.___.______';

    return [
      pw.Center(
        child: pw.Text(
          'TOVARLARNI YETKAZIB BERISH SHARTNOMASI No ${contract.codeContract}',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
      ),
      pw.SizedBox(height: 16),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Toshkent sh.', style: const pw.TextStyle(fontSize: 10)),
          pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
      pw.SizedBox(height: 16),
      _p('     $orgName keyingi o\'rinlarda "Yetkazib beruvchi" deb ataluvchi, Ustav asosida faoliyat yurituvchi direktor Ortikov A.Sh. nomidan bir tomondan, va $clientName keyingi o\'rinlarda "Xaridor" deb ataluvchi, $docBasis asosida faoliyat yurituvchi $ownerName nomidan ikkinchi tomondan, birgalikda keyingi o\'rinlarda "Tomonlar", alohida "Tomon" deb atalib, quyidagilar to\'g\'risida mazkur Shartnomani tuzdilar:'),
      pw.SizedBox(height: 12),
      
      // 1-BO'LIM
      _h('1. Shartnoma predmeti'),
      _p('     1.1. Xaridor qo\'yilgan Buyurtmalarga muvofiq to\'lashga va "parfyumeriya-kosmetika vositalari assortimentda" (keyingi o\'rinlarda - Tovar) tovarni qabul qilishga majbur bo\'ladi, uning nomi, miqdori, o\'lchov birliklari, narxi va qiymati, shu jumladan QQS (O\'zR qonunchiligiga muvofiq amal qiluvchi stavkalar hisobga olingan holda), mazkur Shartnomaga ilova qilingan yuk xatlari va hisob-fakturalarida belgilanadi, Yetkazib beruvchi esa mazkur Shartnoma shartlariga muvofiq Tovarni Xaridor mulkiga topshirishga majbur bo\'ladi.'),
      _p('     1.2. Har bir partiyaning miqdori, assortimenti va qiymati Tomonlar tomonidan Buyurtmalarda, tovar-transport yuk xatlarida va hisob-fakturalarida belgilanadi, ularning har biri Tomonlarning vakolatli vakillari imzolagan va muhr bilan tasdiqlangan (mavjud bo\'lsa) holda mazkur Shartnomaning ajralmas qismi hisoblanadi.'),
      _p('     1.3. Xaridor Tovarni O\'zbekiston Respublikasi amaldagi qonunchilik normalariga rioya qilgan holda yakuniy iste\'molchiga sotishga majbur bo\'ladi. Bunday tartibga rioya qilmaslik uchun Xaridor javobgar bo\'ladi.'),
      _p('     1.4. Mazkur Shartnomaning umumiy summasi tuzilgan yuk xatlari va hisob-fakturalarining umumiy summalaridan tashkil topadi.'),
      pw.SizedBox(height: 10),
      
      // 2-BO'LIM
      _h('2. To\'lov shartlari'),
      if (isCreditContract) ...[
        _p('     2.1. Xaridor Buyurtma imzolangan kundan keyingi kundan boshlab 3 (uch) bank kuni ichida yetkazib beriladigan tovar uchun $creditPercent% miqdorida (lekin tovar buyurtmasi summasining kamida 30% dan kam bo\'lmagan) oldindan to\'lovni amalga oshiradi. Sotuvchi tomonidan pul mablag\'larini olish sanasi vakolatli bank tomonidan pul mablag\'larini Sotuvchi hisob raqamiga o\'tkazilgan bank kuni hisoblanadi.'),
        _p('     Yakuniy hisob-kitob Buyurtma to\'lovga qo\'yilgan paytdan boshlab 14 (o\'n to\'rt) kalendar kun ichida amalga oshiriladi.'),
        _p('     Tovarlar uchun to\'lov bo\'yicha qarzdorlik har qanday holatda yetkazib berish amalga oshirilgan joriy oyning 30 (31) sanasigacha, ya\'ni oxirgi kunigacha to\'lanishi kerak.'),
      ] else ...[
        _p('     2.1. Xaridor Buyurtma imzolangan kundan keyingi kundan boshlab 3 (uch) bank kuni ichida yetkazib beriladigan tovar uchun 100% oldindan to\'lovni amalga oshiradi. Sotuvchi tomonidan pul mablag\'larini olish sanasi vakolatli bank tomonidan pul mablag\'larini Sotuvchi hisob raqamiga o\'tkazilgan bank kuni hisoblanadi.'),
      ],
      _p('     2.2. To\'lov Xaridor tomonidan to\'lov topshiriqnomasi asosida, O\'zR milliy valyutasida – so\'mda naqdsiz pul mablag\'larini mazkur Shartnomaning 9-bo\'limida ko\'rsatilgan Yetkazib beruvchi hisobiga to\'g\'ridan-to\'g\'ri bank o\'tkazmasi yo\'li bilan amalga oshiriladi.'),
      _p('     2.3. Buyurtmada ko\'rsatilgan Tovar qiymati ushbu Tovar partiyasi uchun yakuniy hisoblanadi va mazkur Shartnomaning 2.1-bandida belgilangan Tovar to\'lovi shartlariga Xaridor tomonidan rioya qilingan taqdirda o\'zgartirilmaydi.'),
      if (isCreditContract) ...[
        _p('     2.4. Agar Xaridor Buyurtmani imzolagandan so\'ng Shartnomaning 2.1-bandiga muvofiq to\'lovni amalga oshirmasa, Yetkazib beruvchi bir tomonlama tartibda yetkazib berish muddatlari, shartlari, yetkazib beriladigan Tovar miqdori va qiymatini o\'zgartirish huquqini o\'zida saqlab qoladi.'),
        _p('     Agar tovar uchun to\'lov qoldig\'i Shartnomaning 2.1-bandiga muvofiq to\'lanmasa, oldindan to\'langan keyingi tovar partiyasining barcha keyingi sotuvlari va jo\'natishlari mavjud qarzdorlik to\'liq to\'languniga qadar to\'xtatiladi.'),
      ],
      _p('     2.5. Agar Xaridor Yetkazib beruvchi hisob raqamiga pul mablag\'larini o\'tkazishda xatoga yo\'l qo\'ysa; to\'lov tafsilotlarida shartnoma raqami yoki sanasini noto\'g\'ri ko\'rsatsa, mazkur Shartnomaning 8.4 va 8.5-bandlari talablariga mos kelmaganda, Yetkazib beruvchi pul mablag\'larini Xaridorga qaytarish va Tovarni jo\'natishni to\'xtatib turish huquqiga ega.'),
      _p('     2.6. Pul mablag\'larini qaytarish bo\'yicha bank xarajatlari Xaridor hisobiga yuklanadi.'),
      pw.SizedBox(height: 10),
      
      // 3-BO'LIM
      _h('3. Yetkazib berish shartlari'),
      _p('     3.1. Tovarni yetkazib berish Tomonlar tomonidan tasdiqlangan Tovar partiyasiga Buyurtmalarga muvofiq amalga oshiriladi, ularda Tovar assortimenti, miqdori, narxi va qiymati, shu jumladan QQS (O\'zR qonunchiligiga muvofiq amal qiluvchi stavkalar hisobga olingan holda) aks ettiriladi.'),
      _p('     3.2. Sotuvchi Xaridor tomonidan mazkur Shartnomaning 2.1-bandiga muvofiq oldindan to\'lov amalga oshirilgandan so\'ng o\'n bank kuni ichida va faqat mazkur Shartnomaning 1.1-bandida ko\'rsatilgan hajmda tovarni jo\'natadi.'),
      _p('     3.3. Tovarni Xaridorning savdo nuqtasiga yetkazib berish Sotuvchi kuchlari va hisobidan amalga oshiriladi. Tovarni yuklash va tushirish ham Sotuvchi kuchlari va vositalari hamda uning hisobidan amalga oshiriladi, transport xarajatlari Sotuvchi hisobiga yuklanadi.'),
      _p('     3.4. Yetkazib berish sanasi Xaridor tomonidan Sotuvchidan Tovarni qabul qilish-topshirish va tegishli tovar partiyasiga yozilgan yuk hujjatlariga (YX, TTYX, hisob-faktura va h.k.) imzo chekish sanasi hisoblanadi.'),
      _p('     3.5. Yetkazib beruvchi Tovar bilan birga Xaridorga quyidagi hujjatlarni topshiradi:\n     - tovar muvofiqlik sertifikati;\n     - gigiyenik sertifikat;\n     - buyurtma;\n     - ulgurji savdo huquqiga guvohnoma nusxasi.'),
      _p('     3.6. Sotuvchi Sotuvchi Tovarining yanada ilgarilanishi va sotuvlarini oshirish maqsadida reklama va tovarni ilgarilatuvchi mahsulotlarni tekin asosda yetkazib berish huquqini o\'zida saqlab qoladi.'),
      pw.SizedBox(height: 10),
      
      // 4-BO'LIM
      _h('4. Tovar sifati va miqdori, qabul qilish tartibi'),
      _p('     4.1. Yetkazib beruvchi Xaridorga yetkazib beriladigan Tovar sifatining tegishli DAVSTlar standartlari va talablariga, sifat sertifikatlariga va O\'zbekiston Respublikasining boshqa me\'yoriy hujjatlariga muvofiqligini kafolatlaydi.'),
      _p('     4.2. Sotuvchi Xaridorga muddati o\'tgan tovarni sotmaslikka majbur bo\'ladi, Xaridor o\'z navbatida foydalanish muddati o\'tgan Tovarni sotganlik uchun javobgar bo\'ladi.'),
      _p('     4.3. Tovarning yaroqlilik muddati tegishli O\'zR davlat organlari tomonidan tasdiqlangan ishlab chiqaruvchi zavod standartlari va texnik shartlariga muvofiq belgilanadi va Tovar ishlab chiqarilgan sana/paytdan boshlab hisoblanadi.'),
      _p('     4.4. Sotuvchi Xaridor tomonidan u yoki bu turdagi tovarlarni saqlash va savdo qilishning belgilangan shartlari buzilganda Tovar sifatining yo\'qolishi uchun javobgar emas.'),
      _p('     4.5. Tovarni miqdori va sifati bo\'yicha qabul qilish Tovar jo\'natilganda amalga oshiriladi, shundan so\'ng da\'volar ko\'rib chiqilmaydi va qabul qilinmaydi.'),
      _p('     4.6. Qabul qilish Xaridor vakili tomonidan Tovarni olish uchun belgilangan namunadagi ishonchnoma taqdim etilgandan va Sotuvchi tomonidan yozilgan Spetsifikatsiyaga Xaridor imzo chekkanidan so\'ng yakunlangan hisoblanadi.'),
      _p('     4.7. Xaridor aybi bilan noto\'g\'ri saqlash natijasida hosil bo\'lgan sifatsiz mahsulot qaytarilmaydi.'),
      _p('     4.8. Tovar qadoqlanishi O\'zbekiston Respublikasi davlat tilida markirovkani o\'z ichiga olishi kerak.'),
      pw.SizedBox(height: 10),
      
      // 5-BO'LIM
      _h('5. Tomonlarning javobgarligi va nizolarni ko\'rib chiqish tartibi'),
      _p('     5.1. Tomonlar O\'zbekiston Respublikasi amaldagi qonunchiligiga muvofiq mazkur Shartnomadan kelib chiqadigan majburiyatlarni bajarish uchun javobgar bo\'ladilar.'),
      _p('     5.2. Mazkur Shartnoma tomonlarining javobgarligi O\'zbekiston Respublikasi Fuqarolik kodeksiga, 1998 yil 29 avgustdagi № 670-1 «Xo\'jalik yurituvchi sub\'ektlar faoliyatining shartnoma-huquqiy bazasi to\'g\'risida»gi Qonunning 5-bobiga va O\'zbekiston Respublikasi amaldagi qonunchiligiga muvofiq belgilanadi.'),
      _p('     5.3. Tovar uchun to\'lov bo\'yicha pul majburiyatini bajarmaslik yoki bajarishni kechiktirish holatida Xaridor Yetkazib beruvchiga to\'lanmagan tovar qiymatining 1% miqdorida penya to\'lashga majbur bo\'ladi.'),
      _p('     5.4. Jarima sanktsiyalarini qo\'llash Tomonlarning huquqi, majburiyati emas.'),
      _p('     5.5. Mazkur Shartnoma bilan bog\'liq Xaridor va Sotuvchi o\'rtasida yuzaga keladigan barcha nizolar va kelishmovchiliklar Xaridor va Sotuvchi o\'rtasidagi muzokaralar yo\'li bilan hal qilinadi. Da\'volarni ko\'rib chiqish muddati da\'voni ko\'rib chiqish uchun olingan kundan boshlab 15 (o\'n besh) kalendar kunni tashkil etadi. Kelishmovchiliklarni tinch yo\'l bilan hal qilish imkoni bo\'lmaganda, tomonlar da\'volarni Toshkent shahar Iqtisodiy sudiga ko\'rib chiqish uchun topshiradilar.'),
      pw.SizedBox(height: 10),
      
      // 6-BO'LIM
      _h('6. Fors-major'),
      _p('     6.1. Tomonlar mazkur shartnoma bo\'yicha o\'z majburiyatlarini to\'liq yoki qisman bajarmaslik yengib bo\'lmas kuch holatlari, ya\'ni zilzila, yong\'in, suv toshqini, harbiy harakatlar, fuqarolik tartibsizliklari natijasida yuz bergan bo\'lsa, javobgarlikdan ozod qilinadilar. Mazkur shartnoma bo\'yicha holatlarni bajarish muddati yengib bo\'lmas kuch holatlari amal qilgan davrga mutanosib ravishda ko\'chiriladi. Agar fors-major holatlari 30 ish kuni davom etsa, har bir tomon Shartnomani bir tomonlama bekor qilish haqida ariza berish huquqiga ega.'),
      pw.SizedBox(height: 10),
      
      // 7-BO'LIM
      _h('7. Shartnoma amal qilish muddati va uni bekor qilish tartibi'),
      _p('     7.1. Mazkur Shartnoma tomonlar tomonidan tuzilgan paytdan boshlab kuchga kiradi va mazkur Shartnomadan kelib chiqadigan majburiyatlar tomonlar tomonidan to\'liq bajarilguniga qadar, imzolanganidan boshlab 1 (bir) kalendar yil muddatga amal qiladi.'),
      _p('     7.2. Shartnoma amal qilish muddati, agar tomonlar shartnomani bekor qilish haqida xabar bermagan bo\'lsa, keyingi o\'xshash muddat uchun avtomatik ravishda uzaytirilgan hisoblanadi.'),
      _p('     7.3. Mazkur Shartnoma bekor qilishdan oldin 10 (o\'n) kalendar kun oldin tomonlardan birining yozma xabarnomasi bilan bekor qilingan hisoblanadi.'),
      _p('     7.4. Har bir tomon o\'z rekvizitlarini (joylashuv o\'rni, bank, ro\'yxatga olish) o\'zgartirganda darhol boshqa tomonni yozma ravishda xabardor qilishi shart.'),
      pw.SizedBox(height: 10),
      
      // 8-BO'LIM
      _h('8. Yakuniy qoidalar'),
      _p('     8.1. Mazkur Shartnoma o\'zbek tilida ikki nusxada tuzilgan. Ikkala nusxa bir xil va teng yuridik kuchga ega.'),
      _p('     8.2. Mazkur Shartnomaga har qanday o\'zgartirishlar va qo\'shimchalar yozma shaklda tuzilgan va Tomonlarning vakolatli vakillari tomonidan imzolangan taqdirda haqiqiy hisoblanadi.'),
      _p('     8.3. Mazkur Shartnomaning hech bir Tomoni boshqa Tomonning yozma roziligisiz mazkur Shartnomadan kelib chiqadigan yoki uning bajarilishi bilan bog\'liq huquq va majburiyatlarini uchinchi shaxslarga topshirish huquqiga ega emas.'),
      pw.SizedBox(height: 10),
      
      // 9-BO'LIM
      _h('9. Yuridik manzillar, bank rekvizitlari'),
      pw.SizedBox(height: 8),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Yetkazib beruvchi:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(orgName, style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Manzil: Toshkent sh.', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Telefon: +998712370303', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('H/r: 20208000600823324001', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('ATB Infin Bank Toshkent sh.', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('MFO: 01041', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('STIR: 305134937', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('IFUT: 46900', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('QQS RKP: 326020025647', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Xaridor:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(clientName, style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Manzil: ${clientData?.address ?? "_______________"}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Telefon: ${clientData?.phone ?? "_______________"}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('H/r: _______________', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('_______________', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('MFO: _______________', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('STIR: ${clientData?.inn ?? "_______________"}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('IFUT: _______________', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('QQS RKP: _______________', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 20),
      
      // 10-BO'LIM
      _h('10. Tomonlarning imzolari va muhrlari'),
      pw.SizedBox(height: 16),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text('Rahbar', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 30),
                pw.Text('Ortikov A.Sh. /_______________/', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('(imzo, muhr)', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text('Rahbar', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 30),
                pw.Text('$ownerName /_______________/', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('(imzo, muhr)', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  static List<pw.Widget> _buildRussianContent(
    ClientContractWithName contract,
    TradingPoint? clientData,
    String clientName,
    String ownerName,
    bool isCreditContract,
    String creditPercent,
    String orgName,
  ) {
    final docBasis = clientData?.tradePointType == "ИП" ? "Свидетельства о регистрации ИП" : "Устава";
    final dateStr = contract.dateOfContract != null 
        ? DateFormat('dd.MM.yyyy').format(contract.dateOfContract!) 
        : '___.___.______';
    // Convert org name to Russian format if needed
    final orgNameRu = orgName.contains('MChJ') ? 'OOO "${orgName.replaceAll('"', '').replaceAll(' MChJ', '').replaceAll('MChJ', '')}"' : orgName;

    return [
      pw.Center(
        child: pw.Text(
          'ДОГОВОР ПОСТАВКИ ТОВАРОВ No ${contract.codeContract}',
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          textAlign: pw.TextAlign.center,
        ),
      ),
      pw.SizedBox(height: 16),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('г. Ташкент', style: const pw.TextStyle(fontSize: 10)),
          pw.Text(dateStr, style: const pw.TextStyle(fontSize: 10)),
        ],
      ),
      pw.SizedBox(height: 16),
      _p('     $orgNameRu именуемое в дальнейшем "Поставщик" в лице директора Ортиков А.Ш., действующего на основании Устава, с одной стороны, и $clientName именуемое в дальнейшем "Покупатель" в лице $ownerName, действующего на основании $docBasis, с другой стороны, вместе именуемые в дальнейшем "Стороны", а по отдельности "Сторона", заключили настоящий Договор о нижеследующем:'),
      pw.SizedBox(height: 12),
      
      // РАЗДЕЛ 1
      _h('1. Предмет Договора'),
      _p('     1.1. Покупатель обязуется оплатить, согласно выставленным Заказам и принять товар "парфюмерно-косметические средства в ассортименте" (далее - Товар), наименование, количество, единицы измерения, цена и стоимость которого, в том числе НДС (применяемых с учетом действующих ставок, согласно законодательства РУз.), определяется в накладных и счет-фактурах к настоящему Договору, а Поставщик обязуется передать в собственность Покупателя Товар на условиях настоящего Договора.'),
      _p('     1.2. Количество, ассортимент и стоимость каждой партии определяется Сторонами в Заказах, товарно-транспортных накладных и счетах-фактурах, каждая из которых становится неотъемлемой частью настоящего Договора после подписания уполномоченными представителями Сторон и скреплением печатью (при наличии).'),
      _p('     1.3. Покупатель обязуется продавать Товар конечному потребителю с соблюдением норм действующего законодательства Республики Узбекистан. За несоблюдение такого порядка несет ответственность Покупатель.'),
      _p('     1.4. Общая сумма настоящего Договора складывается из общих сумм заключенных накладных и счет-фактур.'),
      pw.SizedBox(height: 10),
      
      // РАЗДЕЛ 2
      _h('2. Условия оплаты'),
      if (isCreditContract) ...[
        _p('     2.1. Покупатель производит предварительную оплату товара в размере $creditPercent% (но не менее 30% от суммы заказа товара), объявленного к поставке в течение 3 (трех) банковских дней со дня следующего за днем подписания Заказа. Датой получения денежных средств Продавцом является банковский день зачисления уполномоченным банком денежных средств на расчетный счет Продавца.'),
        _p('     Окончательный расчет производится в течение 14 (четырнадцати) календарных дней с момента выставления Заказа на оплату.'),
        _p('     Задолженность по оплате товаров подлежит погашению в любом случае до 30 (31-го) числа, т.е. последнего числа текущего месяца, в котором осуществлялась поставка.'),
      ] else ...[
        _p('     2.1. Покупатель производит 100% предварительную оплату товара, объявленного к поставке в течение 3 (трех) банковских дней со дня следующего за днем подписания Заказа. Датой получения денежных средств Продавцом является банковский день зачисления уполномоченным банком денежных средств на расчетный счет Продавца.'),
      ],
      _p('     2.2. Оплата производится Покупателем на основании платежного поручения, путем перечисления безналичных денежных средств в национальной валюте РУз - сум, прямым банковским переводом на счет Поставщика, указанный в разделе 9 настоящего Договора.'),
      _p('     2.3. Указанная в Заказе стоимость Товара является окончательной для данной партии Товара и не подлежит изменению при условии соблюдения Покупателем условий оплаты Товара, определенными в пункте 2.1. настоящего Договора.'),
      if (isCreditContract) ...[
        _p('     2.4. В случае если Покупатель после подписания Заказа не осуществит оплату в соответствии с пунктом 2.1. Договора, Поставщик оставляет за собой право в одностороннем порядке изменять сроки, условия поставки, количество и стоимость поставляемого им Товара.'),
        _p('     Если остаток по оплате товара не будет оплачен согласно п. 2.1. Договора, все последующие продажи товара и отгрузки последующей партии товара, оплаченной по предоплате, приостанавливаются до момента полного погашения имеющейся задолженности.'),
      ],
      _p('     2.5. В случае если при перечислении денежных средств на расчетный счет Поставщика, Покупатель допустил ошибку; неправильно указал номер или дата договора в деталях платежа, несоответствие требованиям пунктам 8.4 и 8.5 настоящего Договора, то Поставщик вправе вернуть денежные средства Покупателю и приостановить отгрузку Товара.'),
      _p('     2.6. Банковские расходы по возврату денежных средств относятся на счет Покупателя.'),
      pw.SizedBox(height: 10),
      
      // РАЗДЕЛ 3
      _h('3. Условия поставки'),
      _p('     3.1. Поставка Товара будет осуществляться согласно утвержденным Сторонами Заказам на партию Товара, в которых отражается: ассортимент Товара, его количество, цена и стоимость, в том числе НДС (применяемый с учетом действующих ставок, согласно законодательства РУз).'),
      _p('     3.2. Продавец осуществляет в течение десяти банковских дней отгрузку товара, только после осуществления Покупателем предварительной оплаты согласно пункту 2.1. настоящего Договора и только в объеме, указанном в пункте 1.1. настоящего Договора.'),
      _p('     3.3. Отгрузка Товара до торговой точки Покупателя производится силами и за счет Продавца. Погрузка и выгрузка товара, также производится силами и средствами Продавца и за его счет, транспортные расходы относятся на счет Продавца.'),
      _p('     3.4. Датой поставки считается дата приема-передачи Покупателем Товара от Продавца и подписания товаросопроводительных документов (ТН, ТТН, счет-фактура и т.д.), выписанных на соответствующую партию товара.'),
      _p('     3.5. Поставщик с Товаром передает Покупателю следующие документы:\n     - сертификат соответствия на товар;\n     - гигиенический сертификат;\n     - заказ;\n     - копию свидетельства на право оптовой торговли.'),
      _p('     3.6. Продавец оставляет за собой право поставлять рекламную и товар продвигающую продукцию на безвозмездной основе в целях дальнейшего продвижения и увеличения продаж Товара Продавца.'),
      pw.SizedBox(height: 10),
      
      // РАЗДЕЛ 4
      _h('4. Качество и количество товара, порядок приемки'),
      _p('     4.1. Поставщик гарантирует Покупателю соответствие качества поставляемого им Товара стандартам и требованиям соответствующих ГОСТов, сертификатам качества и прочими нормативным документам Республики Узбекистан.'),
      _p('     4.2. Продавец обязуется не реализовывать Товар Покупателю с просроченным сроком потребления, Покупатель, в свою очередь, несет ответственность за продажу Товара с просроченным сроком его использования.'),
      _p('     4.3. Срок годности Товара устанавливается по стандартам и техническим условиям завода производителя, утвержденным соответствующими госорганами РУз, и исчисляется с момента/даты производства Товара.'),
      _p('     4.4. Продавец не несет ответственность за потерю качества Товара при нарушении Покупателем установленных условий хранения и торговли теми или иными видами товара.'),
      _p('     4.5. Приемка Товара по количеству и качеству производится при отгрузке Товара, после чего, претензии не рассматриваются и не принимаются.'),
      _p('     4.6. Приемка считается завершенной после предоставления представителем Покупателя доверенности установленного образца на получение Товара и подписания Покупателем Спецификации, выписанной Продавцом.'),
      _p('     4.7. Некачественная продукция, образовавшаяся в результате неправильного хранения по вине Покупателя, возврату не подлежит.'),
      _p('     4.8. Упаковка товара должна содержать маркировку на государственном языке Республики Узбекистан.'),
      pw.SizedBox(height: 10),
      
      // РАЗДЕЛ 5
      _h('5. Ответственность сторон и порядок рассмотрения споров'),
      _p('     5.1. Стороны несут ответственность за выполнение обязательств, вытекающих из настоящего Договора в соответствии с действующим законодательством Республики Узбекистан.'),
      _p('     5.2. Ответственность сторон настоящего Договора определяется в соответствии с Гражданским кодексом Республики Узбекистан, Главой 5 Закона «О договорно-правовой базе деятельности хозяйствующих субъектов» от 29.08.1998 г. № 670-1, и действующим законодательством Республики Узбекистан.'),
      _p('     5.3. В случае неисполнения, а равно просрочки исполнения денежного обязательства по оплате Товара, Покупатель обязуется выплатить Поставщику пени в размере 1% от стоимости неоплаченного товара.'),
      _p('     5.4. Предъявление штрафных санкций является правом, а не обязанностью Сторон.'),
      _p('     5.5. Все споры и разногласия, возникающие между Покупателем и Продавцом в связи с настоящим Договором, разрешаются путем переговоров между Покупателем и Продавцом. Срок рассмотрения претензий составляет 15 (пятнадцать) календарных дней со дня получения претензии для рассмотрения. При невозможности урегулирования разногласий мирным путем, стороны передают претензии на рассмотрение Экономического суда города Ташкента.'),
      pw.SizedBox(height: 10),
      
      // РАЗДЕЛ 6
      _h('6. Форс-мажор'),
      _p('     6.1. Стороны освобождаются от ответственности за полное или частичное неисполнение своих обязательств по настоящему договору, если оно явилось следствием обстоятельств непреодолимой силы, таких как землетрясение, пожар, наводнение, военные действия, гражданские беспорядки. Срок исполнения обстоятельств по настоящему договору отодвигается соразмерно периоду, в течение которого действовали обстоятельства непреодолимой силы. Если обстоятельства форс-мажора продолжаются 30 рабочих дней, то каждая из сторон имеет право заявить об одностороннем расторжении Договора.'),
      pw.SizedBox(height: 10),
      
      // РАЗДЕЛ 7
      _h('7. Срок действия Договора и порядок его расторжения'),
      _p('     7.1. Настоящий Договор вступает в силу с момента заключения его сторонами и действует до полного исполнения своих обязательств сторонами, вытекающими из настоящего Договора, сроком на 1(один) календарный год с момента подписания.'),
      _p('     7.2. Срок действия договора считается автоматически продлённым на следующий аналогичный по длительности период, в случае если, стороны не уведомили о прекращении договора.'),
      _p('     7.3. Настоящий Договор считается расторгнутым при письменном уведомлении одной из сторон заблаговременно за 10 (десять) календарных дней до расторжения.'),
      _p('     7.4. Каждая сторона при изменении своих реквизитов (место нахождения, банковские, регистрационные) обязана незамедлительно письменно известить об этом другую сторону.'),
      pw.SizedBox(height: 10),
      
      // РАЗДЕЛ 8
      _h('8. Заключительные положения'),
      _p('     8.1. Настоящий Договор составлен в двух экземплярах на русском языке. Оба экземпляра идентичны и имеют одинаковую юридическую силу.'),
      _p('     8.2. Любые изменения и дополнения к настоящему Договору действительны при совершении их в письменном виде и подписании их уполномоченными представителями Сторон.'),
      _p('     8.3. Ни одна из Сторон настоящего Договора не вправе передать свои права и обязательства, вытекающие из настоящего Договора или связанных с его исполнением, третьим лицам без письменного согласия на это другой Стороны.'),
      pw.SizedBox(height: 10),
      
      // РАЗДЕЛ 9
      _h('9. Юридические адреса, банковские реквизиты'),
      pw.SizedBox(height: 8),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Поставщик:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(orgNameRu, style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Адрес: г. Ташкент', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Телефон: +998712370303', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Р/сч: 20208000600823324001', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('в АКБ Infin Bank город Ташкент', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('МФО: 01041', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('ИНН: 305134937', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('ОКЭД: 46900', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('РКП НДС: 326020025647', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Покупатель:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(clientName, style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Адрес: ${clientData?.address ?? "_______________"}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Телефон: ${clientData?.phone ?? "_______________"}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Р/сч: _______________', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('в _______________', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('МФО: _______________', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('ИНН: ${clientData?.inn ?? "_______________"}', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('ОКЭД: _______________', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('РКП НДС: _______________', style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 20),
      
      // РАЗДЕЛ 10
      _h('10. Подписи и печати сторон'),
      pw.SizedBox(height: 16),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text('Руководитель', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 30),
                pw.Text('Ортиков А.Ш. /_______________/', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('(подпись, печать)', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
          pw.Expanded(
            child: pw.Column(
              children: [
                pw.Text('Руководитель', style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 30),
                pw.Text('$ownerName /_______________/', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('(подпись, печать)', style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  static pw.Widget _h(String title) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
  );

  static pw.Widget _p(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 4),
    child: pw.Text(text, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.justify),
  );
}
