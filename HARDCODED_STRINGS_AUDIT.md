# Hardcoded Strings Audit - To'liq Ro'yxat

Bu fayl loyihadagi barcha hardcoded stringlarni kategoriyalashtirilgan holatda o'z ichiga oladi.

## Kategoriyalar

### A. UI Labels va Text Widgets

#### trading_points_filters_panel.dart
- `'Savdo nuqtasi turi'` (42-qator) - **labelTradingPointType**
- `'Biznes region'` (74-qator) - **labelBusinessRegion**

#### order_filters_panel.dart  
- `'Status'` (36-qator) - **labelStatus**
- `'Sana oralig\'i'` (64-qator) - **labelDateRange**
- `'Mijozlar'` (71-qator) - **labelClients**
- `'Barcha sanalar'` (67-qator) - **allDates**

#### trading_points_page.dart
- `'Rad etish sababi'` (2127-qator) - **refusalReasonTitle**
- `'${widget.tradingPoint.name} uchun rad etish sababini tanlang:'` (2131-qator) - **selectRefusalReasonFor** (parameter)
- `'Biznes region: ${regionNames[...] ?? 'Noma\'lum'}'` (1848-qator) - **businessRegionLabel** (parameter)
- `'Aloqa: ${tradingPoint.contactPerson}'` (1856-qator) - **contactLabel** (parameter)
- `'INN: ${widget.tradingPoint.inn}'` (3774-qator) - **innLabel** (parameter)
- `'Egasi: ${widget.tradingPoint.ownerName}'` (3785-qator) - **ownerLabel** (parameter)
- `'Aloqa: ${widget.tradingPoint.contactPerson}'` (3795-qator) - **contactLabel** (parameter)
- `'Mas'ul: ${widget.tradingPoint.responsiblePerson}'` (3826-qator) - **responsiblePersonLabel** (parameter)
- `'Mas'ul tel: ${widget.tradingPoint.responsiblePersonPhone}'` (3837-qator) - **responsiblePersonPhoneLabel** (parameter)
- `'Turi: ${widget.tradingPoint.tradePointType}'` (3848-qator) - **typeLabel** (parameter)
- `'${widget.tradingPoint.region}, ${widget.tradingPoint.district}'` (3858-qator) - **regionDistrictLabel** (parameter)
- `'Belgi: ${widget.tradingPoint.signboard}'` (3869-qator) - **signboardLabel** (parameter)
- `'Mo'ljal: ${widget.tradingPoint.referencePoint}'` (3880-qator) - **landmarkLabel** (parameter)
- `'Joylashuv ma'lumotlari kutilmoqda...'` (4273-qator) - **waitingForLocation**

#### visit_completion_page.dart
- `'Tashrif yakunlandi'` (44-qator) - **visitCompletedTitle**
- `'Yopish'` (51-qator) - **close** (mavjud)
- `'Tashrif muvaffaqiyatli yakunlandi!'` (105-qator) - **visitCompletedSuccessfully**
- `'${widget.completedSteps.length} ta bosqich bajarildi'` (114-qator) - **stepsCompletedCount** (parameter)
- `'Bosh sahifaga qaytish'` (221-qator) - **returnToHome**
- `'Bajarilgan: ${_formatDateTime(...)}'` (188-qator) - **completedAtLabel** (parameter)
- `'Buyurtma ${createOrder.id ?? 'Yangi'}'` (307-qator) - **orderCaption** (parameter)
- `'Yangi'` (317-qator) - **new** (status)
- `'Retail'` (326-qator) - **retail** (price type)

#### product_selection_page.dart
- `'Maksimal miqdor: $stock dona'` (453, 537-qatorlar) - **maxQuantityMessage** (parameter)
- `'Narxi 0 yoki undan kichik bo\'lgan mahsulot qo\'shib bo\'lmaydi'` (465-qator) - **productPriceZeroError**
- `'Miqdorni yangilashda xatolik yuz berdi'` (520-qator) - **quantityUpdateError**
- `'Bekor'` (617-qator) - **cancel** (mavjud)
- `'Saqlash'` (637-qator) - **save** (mavjud)
- `'Tanlovni tasdiqlashda xatolik yuz berdi'` (706-qator) - **confirmationError**
- `'Tasdiqlash'` (773-qator) - **confirm**
- `'Orqaga'` (1456-qator) - **back** (mavjud)
- `'Mahsulot tanlash'` (1785-qator) - **productSelectionTitle**

#### create_order_page.dart
- `'Maksimal miqdor: $stock dona'` (805-qator) - **maxQuantityMessage** (parameter)
- `'Bekor'` (962-qator) - **cancel** (mavjud)
- `'${result.length} ta mahsulot tanlandi'` (2092-qator) - **productsSelectedCount** (parameter)
- `'Mahsulot tanlash'` (2132-qator) - **productSelectionTitle**
- `'Mahsulotlar mavjud emas'` (2137-qator) - **noProductsAvailable**
- `'Bekor qilish'` (2168-qator) - **cancel** (mavjud)
- `'Tozalash'` (2198-qator) - **clear**
- `'Jami mahsulotlar: $_totalItems ta'` (2278-qator) - **totalProductsCount** (parameter)
- `'Jami qiymat: ${uzsFormat.format(_totalValue)}'` (2279-qator) - **totalAmount** (parameter)

#### photo_facing_before_page.dart va photo_facing_after_page.dart
- `'Xatolik yuz berdi: $e'` (98-qator) - **errorOccurred** (parameter)
- `'Kamera ruxsati berilmadi'` (131-qator) - **cameraPermissionDenied**
- `'Kamera ishga tushirishda xatolik: $e'` (145, 178-qatorlar) - **cameraInitError** (parameter)
- `'Kamera xatoligi: $error'` (196-qator) - **cameraError** (parameter)
- `'Kamera boshqa ilova tomonidan ishlatilmoqda. Qayta ulanishga harakat qilinmoqda...'` (228-qator) - **cameraInUseMessage**
- `'Rasm muvaffaqiyatli saqlandi'` (297-qator) - **imageSavedSuccessfully**
- `'Rasm saqlashda xatolik: $e'` (303-qator) - **imageSaveError** (parameter)
- `'Kamera tayyor emas'` (351-qator) - **cameraNotReady**
- `'Kamera mavjud emas yoki ishlamayapti'` (362-qator) - **cameraNotAvailable**
- `'Bekor qilish'` (644, 808, 924, 1034-qatorlar) - **cancel** (mavjud)
- `'${_currentIndex + 1} / ${widget.photos.length}'` (763, 880-qatorlar) - **imageCounter** (parameter)
- `'Yakunlash'` (1287, 1289-qatorlar) - **finish**
- `'Rasm muvaffaqiyatli olingan'` (1348, 1350-qatorlar) - **imageCapturedSuccessfully**
- `'Rasm olishda xatolik: $e'` (1358, 1360-qatorlar) - **imageCaptureError** (parameter)

#### create_contract_form.dart
- `'XML Request'` (340, 1566-qatorlar) - **xmlRequestLabel**
- `'Yopish'` (359-qator) - **close** (mavjud)
- `'XML nusxalandi'` (366-qator) - **xmlCopied**
- `'Nusxa olish'` (373-qator) - **copy** (mavjud)
- `'Qayta yuklash'` (1291-qator) - **reload** (mavjud)
- `'Raqamni kiriting'` (615, 645-qatorlar) - **enterNumberHint**
- `'AA1234567'` (686-qator) - Example format (hint)

#### client_balance_widget.dart
- `'$_remainingSeconds soniyadan keyin yangilash mumkin'` (238-qator) - **refreshAfterSeconds** (parameter, mavjud)
- `'Balans holati'` (269-qator) - **balanceStatusTitle**
- `'Yopish'` (276-qator) - **close** (mavjud)
- `'Qayta urinish'` (468-qator) - **retry** (mavjud)

#### promotion_detail_page.dart
- `'Mahsulot ma\'lumotlari topilmadi: $productCode'` (80-qator) - **productNotFoundMessage** (parameter)
- `'Kod: ${product.code}'` (705, 749, 792-qatorlar) - **codeLabel** (parameter, mavjud)

#### data_persistence_widgets.dart
- `'Skip Step'` (706-qator) - **skipStep** (mavjud)
- `'Complete Step'` (719-qator) - **completeStep** (mavjud)
- `'${widget.stepProgress.step.stepName} completed'` (764-qator) - **stepCompleted** (parameter)
- `'Confirm completion'` (768-qator) - **confirmCompletion** (mavjud)
- `'Cancel'` (783-qator) - **cancel** (mavjud)
- `'Confirm'` (791-qator) - **confirm**
- `'${widget.stepProgress.step.stepName} skip'` (802-qator) - **stepSkip** (parameter)
- `'Enter skip reason'` (806-qator) - **enterSkipReason** (mavjud)
- `'Confirm Skip'` (829-qator) - **confirmSkip** (mavjud)

#### table_sync_card.dart
- `'Sync with dependencies'` (79-qator) - **syncWithDependencies**
- `'Recommended'` (80-qator) - **recommended**
- `'Sync table only'` (88-qator) - **syncTableOnly**
- `'May fail if dependencies not synced'` (89-qator) - **syncWarning**
- `'Table only'` (340-qator) - **tableOnly**
- `'With dependencies'` (345-qator) - **withDependencies**

#### group_sync_card.dart
- `'Sync Entire Group'` (301-qator) - **syncEntireGroup**

#### order_card.dart
- `'№ ${order.numOrder}'` (52-qator) - **orderNumberPrefix** (mavjud, parameter bilan)

### B. Dialog va SnackBar Xabarlar

#### trading_points_page.dart
- `'Yangi mijoz muvaffaqiyatli yaratildi!'` (1617-qator) - **clientCreatedSuccessfully**
- `'Qo'ng'iroq qilish'` (4468-qator) - **callClientTitle**
- `'Mijozga qo'ng'iroq qilmoqchimisiz?\n$rawPhone'` (4469-qator) - **callClientConfirmation** (parameter)
- `'Dialer ochilmadi'` (4482-qator) - **dialerNotAvailable**
- `'Update coordinates - functionality to be implemented'` (3448, 3549, 3682-qatorlar) - **updateCoordinatesNotImplemented**
- `'OpenStreetMap yuklanmadi. Google Maps ishlatiladi.'` (3695-qator) - **osmNotLoadedFallback**
- `'Joylashuvni tasdiqlash'` (map detail pages) - **confirmLocationTitle**

#### visit_completion_page.dart
- `'Buyurtma tafsilotlari topilmadi'` (253-qator) - **orderDetailsNotFound**
- `'Buyurtma tafsilotlariga o\'tishda xatolik'` (264-qator) - **orderDetailsNavigationError** (mavjud errorOccurredPrefix)

#### map detail pages (osm, yandex, google)
- `'Joylashuv ruxsatnomasi berilmadi'` - **locationPermissionDenied** (mavjud)
- `'Ruxsatnoma tekshirishda xatolik: $e'` - **permissionCheckError** (parameter)
- `'Joylashuvni aniqlashda xatolik: $e'` - **locationDetectionError** (parameter)
- `'Foydalanuvchi joylashuvi aniqlanmadi'` - **userLocationNotFound**
- `'Marshrut: ${distance} km, taxminiy ${estimatedTime}'` - **routeInfo** (parameter)
- `'Marshrut yaratishda xatolik: $e'` - **routeCreationError** (parameter)
- `'Kamera harakatida xatolik: $e'` - **cameraMoveError** (parameter)
- `'Ruxsatlarni tekshirishda xatolik: $e'` - **permissionsCheckError** (parameter)
- `'Joylashuv yangilanmoqda...'` - **locationUpdating**
- `'Mijoz joylashuvi muvaffaqiyatli yangilandi'` - **clientLocationUpdated**
- `'Joylashuvni yangilashda xatolik: $e'` - **locationUpdateError** (parameter)
- `'Marshrut hisoblanmoqda...'` - **calculatingRoute**

#### create_client_page.dart
- `'Hududlarni yuklashda xatolik: $e'` (130-qator) - **regionsLoadError** (parameter)
- `'Joylashuvni olishda xatolik: $e'` (199-qator) - **locationGetError** (parameter)
- `'Iltimos, hududni tanlang'` (251-qator) - **pleaseSelectRegion** (mavjud createClientSelectRegionError)
- `'Iltimos, savdo nuqtasi turini tanlang'` (261-qator) - **pleaseSelectTradePointType** (mavjud createClientSelectTypeError)
- `'Xatolik: $e'` (343-qator) - **errorPrefix** (mavjud)

#### settings_page.dart
- `'API kaliti muvaffaqiyatli saqlandi'` (1312-qator) - **apiKeySavedSuccessfully**
- `'Xatolik: ${result.errorMessage}'` (1321-qator) - **errorPrefix** (mavjud)

#### settings/data_sync_tab.dart
- `'Balans keshi tozalandi'` (192-qator) - **balanceCacheCleared** (mavjud)
- `'Xatolik: $e'` (202-qator) - **errorPrefix** (mavjud)
- `'Minimum interval is 60 minutes'` (257-qator) - **minimumInterval60Minutes**

#### orders_page.dart
- `'${widget.initialClientName} mijozining buyurtmalari'` (243-qator) - **clientOrdersFor** (mavjud, parameter bilan)

#### client_images_page.dart va client_images_management_page.dart
- `'Kamera ruxsati berilmadi'` - **cameraPermissionDenied** (takrorlanadi)
- `'Kamera ishga tushirishda xatolik: $e'` - **cameraInitError** (takrorlanadi)
- `'Kamera xatoligi: $error'` - **cameraError** (takrorlanadi)
- `'Kamera boshqa ilova tomonidan ishlatilmoqda...'` - **cameraInUseMessage** (takrorlanadi)
- `'Sahifa yuklanishda xatolik: $e'` - **pageLoadError** (parameter)
- `'Rasm asosiy qilib belgilandi'` - **imageSetAsPrimary**
- `'Rasm muvaffaqiyatli saqlandi'` - **imageSavedSuccessfully** (takrorlanadi)
- `'Rasm saqlashda xatolik: $e'` - **imageSaveError** (takrorlanadi)
- `'${uploadedUrls.length} ta rasm muvaffaqiyatli yuklandi'` - **imagesUploadedCount** (parameter)
- `'Server rasmlarini yuklashda xatolik: $e'` - **serverImagesLoadError** (parameter)
- `'Galereyadan rasm tanlashda xatolik: $e'` - **gallerySelectionError** (parameter)
- `'Kameradan rasm olishda xatolik: $e'` - **cameraCaptureError** (parameter)
- `'Rasmlar muvaffaqiyatli yuklandi'` - **imagesUploadedSuccessfully**
- `'Rasmlarni yuklashda xatolik: $e'` - **imagesUploadError** (parameter)

#### db_view_page.dart
- `'Order Draft saved: $fileName'` (214-qator) - **orderDraftSaved** (parameter)
- `'Error: $e'` (220-qator) - **errorPrefix** (mavjud)
- `'Jadvallar'` (427-qator) - **tablesLabel**
- `'${table.name} ustunlari'` (681-qator) - **tableColumns** (parameter)

### C. Form Labels va Titles

#### trading_points_page.dart
- `'Qidirish...'` (1661-qator) - **searchHint** (mavjud)
- `'Noma\'lum'` (1848-qator) - **unknown** (fallback value)

#### order_details_page.dart
- `'Buyurtma tafsilotlari'` (184, 200, 257-qatorlar) - **orderDetailsTitle**
- `'Orqaga'` (235-qator) - **back** (mavjud)

#### client_images_management_page.dart
- `'Kamera'` (204-qator) - **camera** (title)
- `'Galereya'` (212-qator) - **gallery** (title)
- `'${widget.clientName} - Rasmlar'` (246-qator) - **clientImagesTitle** (parameter)
- `'${_currentIndex + 1} / ${widget.images.length}'` (452-qator) - **imageCounter** (parameter, takrorlanadi)

#### client_images_page.dart
- `'Rasm'` (782-qator) - **imageTitle**
- `'${widget.tradingPoint.tradingPoint.name} - Rasmlar'` (806-qator) - **tradingPointImagesTitle** (parameter)
- `'Serverga yuborish (${_photos.length} ta rasm)'` (1256-qator) - **uploadToServer** (parameter)

#### agent_home_modern.dart, agent_home_page.dart
- `'Chiqish'` (784-qator) - **logout** (mavjud)
- `'KPI Dashboard'` (232-qator) - **kpiDashboardTitle**

#### reports_page.dart
- `'Hisobot yuborilgan'` (217-qator) - **reportSentTitle**

#### contract_detail_page.dart
- `'Tahrirlash funksiyasi tez orada qo\'shiladi'` - **editFeatureComingSoon**
- `'Tahrirlash'` - **edit** (mavjud)
- `'PDF yuborish'` - **sendPdf**
- `'Print funksiyasi tez orada qo\'shiladi'` - **printFeatureComingSoon**
- `'Print'` - **print**

#### order_detail_sections.dart
- `'Yopish'` (69, 90-qatorlar) - **close** (mavjud, takrorlanadi)

#### create_client_page.dart
- `'Yangi mijoz'` - **newClient** (mavjud)

#### map_pages
- `'Joylashuvni tasdiqlash'` - **confirmLocationTitle** (takrorlanadi)

### D. Xatolik Xabarlari

Ko'p hollarda xatolik xabarlari allaqachon lokalizatsiya qilingan, lekin ba'zi joylarda hardcoded. Barcha xatoliklar uchun `errorPrefix` va specific error message'lar mavjud.

### E. PDF Content (contract_pdf_service.dart)

Bu bo'limda juda ko'p hardcoded Uzbek matnlar bor. PDF generatsiya uchun alohida ARB kalitlar kerak:

- `'TOVARLARNI YETKAZIB BERISH SHARTNOMASI No ${contract.codeContract}'` - **pdfContractTitle** (parameter)
- `'Toshkent sh.'` - **pdfCityTashkent**
- `'Yetkazib beruvchi'` - **pdfSupplier**
- `'Xaridor'` - **pdfBuyer**
- `'YaTT ro'yxatdan o'tkazish guvohnomasi'` - **pdfRegistrationCertificate**
- `'Ustav'` - **pdfCharter**
- `'Tomonlar'` - **pdfParties**
- `'Tomon'` - **pdfParty**
- Va PDF ichidagi barcha bo'limlar (1-9 bo'limlar) - har biri uchun alohida kalitlar kerak.

PDF kontenti juda uzun, shuning uchun alohida fayl yaratish kerak: `PDF_LOCALIZATION_KEYS.md`

## Statistik Ma'lumotlar

- **Jami topilgan hardcoded stringlar**: ~150+
- **Yangilik kerak bo'lgan ARB kalitlar**: ~120+
- **Takrorlanuvchi stringlar**: ~30+
- **Parameter bilan stringlar**: ~40+

## Takliflar

1. Barcha button label'lar uchun umumiy kalitlar yaratish (`cancel`, `save`, `close`, `confirm`, `back` kabi)
2. Xatolik xabarlari uchun unified error message system
3. PDF content uchun alohida yondashuv
4. Parameter bilan bo'lgan stringlar uchun placeholder'lar ishlatish
