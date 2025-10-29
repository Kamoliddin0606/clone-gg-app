import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart' as model;
import 'package:gloria_marketing_flutter/src/core/maps/widgets/map_widget.dart';
import 'package:gloria_marketing_flutter/src/core/maps/controllers/unified_map_controller.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_settings.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_marker.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_point.dart';
import 'package:gloria_marketing_flutter/src/core/maps/models/map_route.dart';
import 'package:gloria_marketing_flutter/src/core/maps/managers/location_manager.dart' as location_manager;

/// Fullscreen map page for detailed map viewing and navigation
class FullscreenMapPage extends StatefulWidget {
  final model.TradingPoint tradingPoint;
  final MapProvider initialProvider;
  final MapPoint initialCenter;
  final double initialZoom;
  final List<MapMarker> initialMarkers;
  final List<MapRoute> initialRoutes;
  final bool showUserLocation;

  const FullscreenMapPage({
    super.key,
    required this.tradingPoint,
    required this.initialProvider,
    required this.initialCenter,
    required this.initialZoom,
    required this.initialMarkers,
    required this.initialRoutes,
    this.showUserLocation = false,
  });

  @override
  State<FullscreenMapPage> createState() => _FullscreenMapPageState();
}

class _FullscreenMapPageState extends State<FullscreenMapPage> {
  late MapProvider _currentProvider;
  late MapPoint _currentCenter;
  late double _currentZoom;
  late final UnifiedMapController _mapController;
  late final MapSettings _mapSettings;

  // UI state
  bool _showControls = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _currentProvider = widget.initialProvider;
    _currentCenter = widget.initialCenter;
    _currentZoom = widget.initialZoom;
    _mapController = UnifiedMapController();

    _mapSettings = MapSettings(
      provider: _currentProvider,
      defaultCenter: _currentCenter,
      defaultZoom: _currentZoom,
      showUserLocation: widget.showUserLocation,
    );

    _startControlsTimer();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    super.dispose();
  }

  /// Start timer to auto-hide controls
  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  /// Show controls and reset timer
  void _showControlsAndResetTimer() {
    setState(() {
      _showControls = true;
    });
    _startControlsTimer();
  }

  /// Close fullscreen and return current state
  void _closeFullscreen() {
    final result = {
      'center': _currentCenter,
      'zoom': _currentZoom,
      'provider': _currentProvider,
    };
    Navigator.of(context).pop(result);
  }

  /// Update current map state
  void _updateMapState(MapPoint center, double zoom) {
    _currentCenter = center;
    _currentZoom = zoom;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        children: [
          // Fullscreen map
          UnifiedMapWidget(
            provider: _currentProvider,
            settings: _mapSettings,
            initialMarkers: widget.initialMarkers,
            initialRoutes: widget.initialRoutes,
            initialCenter: _currentCenter,
            initialZoom: _currentZoom,
            enableLocation: widget.showUserLocation,
            enableRouting: true,
            enableClustering: true,
            controller: _mapController,
            onMapReady: () {
              if (kDebugMode) {
                print('Fullscreen map ready');
              }
            },
            onLocationUpdate: (location) {
              // Update current center when location changes
              _updateMapState(location.toMapPoint(), _currentZoom);
            },
          ),

          // Controls overlay
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Stack(
              children: [
                // Close button (top-left)
                Positioned(
                  top: 16,
                  left: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: cs.surface.withOpacity(0.9),
                    foregroundColor: cs.onSurface,
                    onPressed: _closeFullscreen,
                    child: const Icon(Icons.close),
                  ),
                ),

                // Provider switcher (top-right)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: cs.outline.withOpacity(0.2)),
                    ),
                    child: DropdownButton<MapProvider>(
                      value: _currentProvider,
                      underline: const SizedBox(),
                      icon: Icon(Icons.map, color: cs.primary, size: 20),
                      items: MapProvider.values.map((provider) {
                        return DropdownMenuItem(
                          value: provider,
                          child: Text(
                            _getProviderDisplayName(provider),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (provider) {
                        if (provider != null) {
                          setState(() {
                            _currentProvider = provider;
                            _mapSettings = _mapSettings.copyWith(provider: provider);
                          });
                          _showControlsAndResetTimer();
                        }
                      },
                    ),
                  ),
                ),

                // Bottom controls
                Positioned(
                  bottom: 24,
                  left: 24,
                  right: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Zoom in
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: cs.surface.withOpacity(0.9),
                        foregroundColor: cs.onSurface,
                        onPressed: () {
                          final newZoom = (_currentZoom + 1).clamp(1.0, 20.0);
                          _mapController.animateTo(
                            target: _currentCenter,
                            zoom: newZoom,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          _updateMapState(_currentCenter, newZoom);
                          _showControlsAndResetTimer();
                        },
                        child: const Icon(Icons.add),
                      ),

                      // Zoom out
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: cs.surface.withOpacity(0.9),
                        foregroundColor: cs.onSurface,
                        onPressed: () {
                          final newZoom = (_currentZoom - 1).clamp(1.0, 20.0);
                          _mapController.animateTo(
                            target: _currentCenter,
                            zoom: newZoom,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                          _updateMapState(_currentCenter, newZoom);
                          _showControlsAndResetTimer();
                        },
                        child: const Icon(Icons.remove),
                      ),

                      // Center on client
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: cs.primary.withOpacity(0.9),
                        foregroundColor: cs.onPrimary,
                        onPressed: () {
                          final clientPoint = MapPoint.fromTradingPoint(widget.tradingPoint);
                          _mapController.animateTo(
                            target: clientPoint,
                            zoom: 18.0,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOutCubic,
                          );
                          _updateMapState(clientPoint, 18.0);
                          _showControlsAndResetTimer();
                        },
                        child: const Icon(Icons.location_on),
                      ),

                      // Center on user (if location enabled)
                      if (widget.showUserLocation)
                        FloatingActionButton(
                          mini: true,
                          backgroundColor: cs.secondary.withOpacity(0.9),
                          foregroundColor: cs.onSecondary,
                          onPressed: () {
                            // This would need location manager integration
                            // For now, just show controls
                            _showControlsAndResetTimer();
                          },
                          child: const Icon(Icons.my_location),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tap to show controls
          Positioned.fill(
            child: GestureDetector(
              onTap: _showControlsAndResetTimer,
              behavior: HitTestBehavior.translucent,
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getProviderDisplayName(MapProvider provider) {
    switch (provider) {
      case MapProvider.google:
        return 'Google Maps';
      case MapProvider.yandex:
        return 'Yandex Maps';
      case MapProvider.openStreetMap:
        return 'OpenStreetMap';
    }
  }
}