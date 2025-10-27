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
import 'package:flutter/foundation.dart';

// Yandex FULL Flutter binding
import 'package:yandex_maps_mapkit/yandex_map.dart';
import 'package:yandex_maps_mapkit/mapkit.dart' as mk;
import 'package:yandex_maps_mapkit/mapkit_factory.dart' as mkf;
import 'package:yandex_maps_mapkit/image.dart' as yimg; // ImageProvider & AnimatedImageProvider

// Maps system imports for MarkerManager integration
import '../../../../core/maps/managers/marker_manager.dart';
import '../../../../core/maps/models/map_marker.dart' hide MarkerClusterConfig;
import '../../../../core/maps/models/map_settings.dart';
import '../../../../core/maps/models/map_point.dart';

// Ixtiyoriy: agar initHook orqali init qilmoqchi bo‘lsangiz, import qilib qo‘yishingiz mumkin.
// import 'package:yandex_maps_mapkit/init.dart' as ymk_init;

class YandexFullMapView extends StatefulWidget {
  const YandexFullMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.markers = const [], // Yangi: MarkerManager orqali boshqariladigan markerlar
    this.markerId, // Eski: orqaga moslik uchun saqlanadi
    this.zoom = 15.0,
    this.initHook,
    this.onMapReady,
    this.clusterConfig, // Yangi: Marker clustering konfiguratsiyasi
  });

  /// Markaz nuqta (karta shu joyga olib boriladi)
  final double latitude;
  final double longitude;

  /// Markerlar ro'yxati (MarkerManager orqali boshqariladi)
  final List<MapMarker> markers;

  /// Marker identifikator (orqaga moslik uchun, agar markers bo'sh bo'lsa)
  final String? markerId;

  /// Boshlang'ich zoom (default 15)
  final double zoom;

  /// Ixtiyoriy: Agar globalda `initMapkit(apiKey: ...)` chaqirilmagan bo'lsa,
  /// shu yerga Future bering va widget uni kutib xaritani quradi.
  /// Masalan:
  ///   initHook: ymk_init.initMapkit(apiKey: 'YOUR_API_KEY')
  final Future<void>? initHook;

  /// Ixtiyoriy: xarita va marker tayyor bo'lgach chaqiriladi
  final VoidCallback? onMapReady;

  /// Ixtiyoriy: Marker clustering konfiguratsiyasi
  final MarkerClusterConfig? clusterConfig;

  @override
  State<YandexFullMapView> createState() => _YandexFullMapViewState();
}

class _YandexFullMapViewState extends State<YandexFullMapView>
    with WidgetsBindingObserver {
  mk.MapWindow? _mapWindow;
  late final mk.MapKit _mapKit; // factory singleton
  mk.PlacemarkMapObject? _placemark;

  // MarkerManager integration
  late final MarkerManager _markerManager;
  List<MapMarker> _processedMarkers = [];

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

    // Initialize MarkerManager
    _markerManager = MarkerManager(
      config: widget.clusterConfig ?? const MarkerClusterConfig(),
      provider: MapProvider.yandex,
    );

    // Process initial markers
    _processMarkers();

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

  /// Process markers through MarkerManager for clustering and optimization
  Future<void> _processMarkers() async {
    try {
      if (widget.markers.isNotEmpty) {
        // Use MarkerManager to process markers
        _processedMarkers = await _markerManager.processMarkersForDisplay(
          widget.markers,
          widget.zoom,
          MapPoint(
            id: 'center',
            latitude: widget.latitude,
            longitude: widget.longitude,
          ),
          400, // viewport width
          600, // viewport height
        );

        if (kDebugMode) {
          print('✅ Successfully processed ${widget.markers.length} markers, result: ${_processedMarkers.length} markers');
          for (final marker in _processedMarkers) {
            print('   - Marker ${marker.id}: ${marker.type} at (${marker.point.latitude}, ${marker.point.longitude})');
          }
        }
      } else if (widget.markerId != null) {
        // Fallback: create single marker from markerId (backward compatibility)
        _processedMarkers = [
          MapMarker(
            id: widget.markerId!,
            point: MapPoint(
              id: widget.markerId!,
              latitude: widget.latitude,
              longitude: widget.longitude,
            ),
            type: MarkerType.default_,
          ),
        ];

        if (kDebugMode) {
          print('⚠️ Using backward compatibility mode with markerId: ${widget.markerId}');
        }
      } else {
        _processedMarkers = [];
        if (kDebugMode) {
          print('ℹ️ No markers provided');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error processing markers: $e');
        print('Stack trace: $stackTrace');
      }
      _processedMarkers = [];

      // Try fallback for critical errors
      if (widget.markerId != null) {
        try {
          _processedMarkers = [
            MapMarker(
              id: widget.markerId!,
              point: MapPoint(
                id: widget.markerId!,
                latitude: widget.latitude,
                longitude: widget.longitude,
              ),
              type: MarkerType.default_,
            ),
          ];
          if (kDebugMode) {
            print('✅ Fallback marker created successfully');
          }
        } catch (fallbackError) {
          if (kDebugMode) {
            print('❌ Fallback marker creation also failed: $fallbackError');
          }
        }
      }
    }
  }

  /// Create Yandex Placemark from MapMarker using MarkerManager data
  Future<mk.PlacemarkMapObject> _createPlacemarkFromMapMarker(MapMarker marker) async {
    try {
      final point = mk.Point(
        latitude: marker.point.latitude,
        longitude: marker.point.longitude,
      );

      final placemark = _mapWindow!.map.mapObjects.addPlacemark()..geometry = point;

      // Apply marker styling based on type
      await _applyPlacemarkStyleFromMapMarker(placemark, marker);

      // Ensure visibility
      _makePlacemarkVisible(placemark);

      return placemark;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating placemark from marker ${marker.id}: $e');
      }
      rethrow;
    }
  }

  /// Apply styling to placemark based on MapMarker properties
  Future<void> _applyPlacemarkStyleFromMapMarker(mk.PlacemarkMapObject placemark, MapMarker marker) async {
    try {
      // Set z-index based on marker priority
      placemark.zIndex = marker.zIndex.toInt() as double;

      // Apply icon based on marker type
      await _applyPlacemarkIconByType(placemark, marker.type);

      // Set opacity
      placemark.opacity = marker.isVisible ? 1.0 : 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('Error applying style to placemark: $e');
      }
    }
  }

  /// Apply icon based on marker type
  Future<void> _applyPlacemarkIconByType(mk.PlacemarkMapObject placemark, MarkerType type) async {
    try {
      String assetPath;
      switch (type) {
        case MarkerType.visited:
          assetPath = 'assets/images/marker_visited.png';
          break;
        case MarkerType.today:
          assetPath = 'assets/images/marker_today.png';
          break;
        case MarkerType.contract:
          assetPath = 'assets/images/marker_contract.png';
          break;
        case MarkerType.cluster:
          assetPath = 'assets/images/marker_cluster.png';
          break;
        case MarkerType.user:
          assetPath = 'assets/images/marker_user.png';
          break;
        default:
          assetPath = 'assets/images/marker.png';
      }

      // Try to load asset, fallback to default if not found
      await _applyPlacemarkIconWithAsset(placemark, assetPath);
    } catch (e) {
      // Fallback to default icon
      await _applyPlacemarkIcon(placemark);
    }
  }

  /// Apply icon with specific asset path
  Future<void> _applyPlacemarkIconWithAsset(mk.PlacemarkMapObject placemark, String assetPath) async {
    try {
      final provider = yimg.AnimatedImageProvider.fromAsset(assetPath) as yimg.ImageProvider;
      final style = mk.IconStyle();

      try {
        final icon = placemark.useIcon();
        icon.setImageWithStyle(provider, style);
      } catch (_) {
        final comp = placemark.useCompositeIcon();
        comp.setIcon(provider, style, name: 'marker');
      }
    } catch (_) {
      // Asset not found, use default
      await _applyPlacemarkIcon(placemark);
    }
  }


  Future<void> _onMapCreated(mk.MapWindow mapWindow) async {
    _mapWindow = mapWindow;

    final target = mk.Point(latitude: widget.latitude, longitude: widget.longitude);

    // 1) Kamera
    try {
      mapWindow.map.move(
        mk.CameraPosition(target, zoom: widget.zoom, tilt: 0, azimuth: 0),
      );
      if (kDebugMode) {
        print('✅ Camera moved to (${widget.latitude}, ${widget.longitude}) with zoom ${widget.zoom}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error moving camera: $e');
      }
    }

    // 2) Placemark'lar — MarkerManager orqali qayta ishlangan markerlardan yaratish
    try {
      if (kDebugMode) {
        print('🔄 Creating placemarks for ${_processedMarkers.length} markers...');
      }

      // Eski yolg'iz placemark o'rniga, MarkerManager orqali qayta ishlangan markerlardan yaratamiz
      for (final marker in _processedMarkers) {
        try {
          final placemark = await _createPlacemarkFromMapMarker(marker);
          if (kDebugMode) {
            print('✅ Created placemark for marker ${marker.id}');
          }
        } catch (markerError) {
          if (kDebugMode) {
            print('❌ Error creating placemark for marker ${marker.id}: $markerError');
          }
        }
      }

      // Agar eski usulda markerId berilgan bo'lsa va yangi markers bo'sh bo'lsa
      if (_processedMarkers.isEmpty && widget.markerId != null) {
        if (kDebugMode) {
          print('⚠️ Using legacy markerId mode: ${widget.markerId}');
        }

        _placemark = mapWindow.map.mapObjects.addPlacemark()..geometry = target;
        await _applyPlacemarkIcon(_placemark!);
        _makePlacemarkVisible(_placemark!);

        try {
          _placemark!.zIndex = 10;
          _placemark!.opacity = 1.0;
          if (kDebugMode) {
            print('✅ Legacy placemark created and made visible');
          }
        } catch (zIndexError) {
          if (kDebugMode) {
            print('⚠️ Error setting zIndex/opacity on legacy placemark: $zIndexError');
          }
        }
      }

      if (kDebugMode) {
        print('✅ Placemark creation completed. Total placemarks created: ${_processedMarkers.length}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error creating placemarks: $e');
        print('Stack trace: $stackTrace');
      }
    }

    setState(() => _ready = true);
    widget.onMapReady?.call();

    if (kDebugMode) {
      print('🎉 Map initialization completed successfully');
    }
  }
  void _makePlacemarkVisible(mk.PlacemarkMapObject p) {
    // 1) setVisible metodi mavjud bo'lmasligi mumkin, shuning uchun faqat opacity va zIndex
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

      // Qo'shimcha ko'rinish parametrlari (agar mavjud bo'lsa):
      try {
        placemark.opacity = 1.0;
        // isVisible mavjud emas, faqat opacity va zIndex
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

