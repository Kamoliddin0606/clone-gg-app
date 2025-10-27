// lib/yandex_full_map_view.dart
// ============================================================================
// Yandex Maps FULL (yandex_maps_mapkit) uchun modul vidjet.
// Eski controller-based (yandex_mapkit) kodini almashtirishga mos adapter.
// - Kamera: berilgan lat/lon ga zoom 15 bilan o‘tadi
// - Marker: bitta placemark qo‘yiladi (default pin)
// - Gesture’lar: default yoqilgan
//
// Foydalanish (eski case o‘rniga):
//   return YandexFullMapView(
//     latitude: position.latitude,
//     longitude: position.longitude,
//     markerId: markerId,
//     // Agar globalda initMapkit qilmagan bo‘lsangiz, bir marta shu yerda:
//     // initHook: ymk_init.initMapkit(apiKey: 'YOUR_REAL_YANDEX_API_KEY'),
//   );
//
// Talablar:
//   dependencies:
//     yandex_maps_mapkit: ^4.25.0-beta
// ============================================================================

import 'package:flutter/material.dart';

// Yandex FULL Flutter binding
import 'package:yandex_maps_mapkit/yandex_map.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' as mk;
import 'package:yandex_maps_mapkit/mapkit_factory.dart' as mkf;
import 'package:yandex_maps_mapkit/image.dart' as yimg; // ImageProvider & AnimatedImageProvider

// Ixtiyoriy: agar initHook orqali init qilmoqchi bo‘lsangiz, import qilib qo‘yishingiz mumkin.
// import 'package:yandex_maps_mapkit/init.dart' as ymk_init;

class YandexFullMapView extends StatefulWidget {
  const YandexFullMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.markerId,
    this.zoom = 15.0,
    this.initHook,
    this.onMapReady,
  });

  /// Markaz nuqta (karta shu joyga olib boriladi)
  final double latitude;
  final double longitude;

  /// Marker identifikator (hozircha faqat saqlab qo‘yamiz, arker)
  final String markerId;

  /// Boshlang‘ich zoom (default 15)
  final double zoom;

  /// Ixtiyoriy: Agar globalda `initMapkit(apiKey: ...)` chaqirilmagan bo‘lsa,
  /// shu yerga Future bering va widget uni kutib xaritani quradi.
  /// Masalan:
  ///   initHook: ymk_init.initMapkit(apiKey: 'YOUR_API_KEY')
  final Future<void>? initHook;

  /// Ixtiyoriy: xarita va marker tayyor bo‘lgach chaqiriladi
  final VoidCallback? onMapReady;

  @override
  State<YandexFullMapView> createState() => _YandexFullMapViewState();
}

class _YandexFullMapViewState extends State<YandexFullMapView>
    with WidgetsBindingObserver {
  mk.MapWindow? _mapWindow;
  late final mk.MapKit _mapKit; // factory singleton
  mk.PlacemarkMapObject? _placemark;

  bool _ready = false;

  // initHook bo‘lsa — xarita qurilishidan OLDIN kutamiz
  late final Future<void> _ensureInited =
      widget.initHook ?? Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Yandex MapKit singleton
    _mapKit = mkf.mapkit;

    // Lifecycle boshqaruvi
    _safeOnStart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _safeOnStop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _safeOnStart();
    } else if (state == AppLifecycleState.paused) {
      _safeOnStop();
    }
  }

  void _safeOnStart() {
    try {
      _mapKit.onStart();
    } catch (_) {}
  }

  void _safeOnStop() {
    try {
      _mapKit.onStop();
    } catch (_) {}
  }


  Future<void> _onMapCreated(mk.MapWindow mapWindow) async {
    _mapWindow = mapWindow;

    final target = mk.Point(latitude: widget.latitude, longitude: widget.longitude);

    // 1) Kamera
    try {
      mapWindow.map.move(
        mk.CameraPosition(target, zoom: widget.zoom, tilt: 0, azimuth: 0),
      );
    } catch (_) {}

    // 2) Placemark — avval har doim obyektni yarating
    try {
      _placemark = mapWindow.map.mapObjects.addPlacemark()..geometry = target;
      await _applyPlacemarkIcon(_placemark!);
      // 2a) Ikon beramiz (assetdan). Agar asset topilmasa — fallback.
      // await _applyPlacemarkIcon(_placemark!);
      _makePlacemarkVisible(_placemark!);

      //(ixtiyoriy lekin foydali) biroz “yuqoriroq” ko‘rinishi uchun zIndex:
      try {
        _placemark!.zIndex = 10;
        // ko‘rinadigan qilish:
        _placemark!.isVisible = true;
        _placemark!.opacity = 1.0;
      } catch (_) {
        // Ba'zi bindinglarda bu property'lar bo'lmasligi mumkin — xatoni yutamiz.
      }
    } catch (_) {}

    setState(() => _ready = true);
    widget.onMapReady?.call();
  }
  void _makePlacemarkVisible(mk.PlacemarkMapObject p) {
    // 1) Ba’zi versiyalarda method ko‘rinishida
    try { p.setVisible(true as mk.Animation, visible: false); } catch (_) {}

    // 2) Boshqa versiyalarda opacity/zIndex kifoya qiladi
    try { p.opacity = 1.0; } catch (_) {}
    try { p.zIndex = 10; } catch (_) {}
  }
  /// Placemark uchun ikon qo‘llash:
  /// - Avval assetdan yuklashga harakat qiladi
  /// - Muvaffaqiyatsiz bo‘lsa, ko‘rinadigan fallback (matn) beradi
  Future<void> _applyPlacemarkIcon(mk.PlacemarkMapObject placemark) async {
    try {
      // 1) Assetdan image provider yarating (PNG/GIF qo‘llaydi)
      final yimg.ImageProvider provider =
      yimg.AnimatedImageProvider.fromAsset('assets/images/marker.png') as yimg.ImageProvider;

      // 2) Icon style (masshtab, anchor va h.k.)
      final mk.IconStyle style = mk.IconStyle();
        // ..scale = 1.0; // xohlasangiz 1.2-1.5 qilib kattalashtiring

      // 3) Ikonni 2 xil yo‘l bilan berish mumkin. Avval oddiy useIcon():
      try {
        final mk.Icon icon = placemark.useIcon();   // placemark’ning oddiy ikoni
        icon.setImageWithStyle(provider, style);    // ikon + style
      } catch (_) {
        // Agar sizning binding’da composite icon afzal bo‘lsa:
        final mk.CompositeIcon comp = placemark.useCompositeIcon();
        comp.setIcon(provider, style, name: 'pin'); // nomlangan qatlam
      }

      // Qo‘shimcha ko‘rinish parametrlari (agar mavjud bo‘lsa):
      try {
        placemark.opacity = 1.0;
        placemark.isVisible = true;
        placemark.zIndex = 10;
      } catch (_) {}
    } catch (_) {
      // Asset topilmasa — matnli fallback (ba’zi versiyalarda PlacemarkText mavjud)
      try {
        // final text = placemark.getText();
        // text.setText('●'); // oddiy nuqta belgisi
      } catch (_) {
        // hech bo‘lmasa ko‘rinadigan bo‘lsin
        try { placemark.opacity = 1.0; } catch (_) {}
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    // initHook berilgan bo‘lsa, avval init yakunlansin
    return FutureBuilder<void>(
      future: _ensureInited,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Text(
              'Yandex init xatosi: ${snap.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        // MUHIM: YandexMap har doim qurilsin — shunda onMapCreated chaqiriladi
        return Stack(
          children: [
            YandexMap(onMapCreated: _onMapCreated),
            if (!_ready)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x11000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        );
      },
    );
  }
}

