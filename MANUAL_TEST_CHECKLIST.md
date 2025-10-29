# Unified Map Implementation - Manual Test Checklist

## 1. Camera Animations (Google/Yandex/OSM)
- [ ] **my_location button**: Tap animates to user location with smooth 900-1200ms easeInOutCubic
- [ ] **client_location button**: Tap animates to client location with smooth 900-1200ms easeInOutCubic
- [ ] **Google Maps**: Uses animateCamera with CameraUpdate.newCameraPosition
- [ ] **Yandex Maps**: Uses moveCamera with MapAnimation smooth type and 900-1200ms duration
- [ ] **OSM**: Uses MapController.move with tween animation fallback
- [ ] **Zoom consistency**: All providers respect zoom levels 1-20 with proper clamping
- [ ] **Animation smoothness**: No stuttering or jerky movements during animation

## 2. Auto-collapse UX (3 seconds)
- [ ] **Timer starts**: After 3 seconds of inactivity, controls fade to 60% opacity
- [ ] **Collapse animation**: Smooth scale animation to 92% size over 300ms
- [ ] **Expand on tap**: Tapping collapsed controls smoothly expands back to full size
- [ ] **Reset on interaction**: Any button tap or map interaction resets the 3-second timer
- [ ] **Provider consistency**: Auto-collapse works identically across Google/Yandex/OSM

## 3. Route Drawing and fitBounds
- [ ] **Route button tap**: Creates route from user to client location
- [ ] **Polyline display**: Route appears as blue polyline on all map providers
- [ ] **fitBounds execution**: Camera automatically fits to show entire route
- [ ] **Route info overlay**: Shows distance and time in top overlay
- [ ] **Google Maps**: Uses Polyline with correct coordinates
- [ ] **Yandex Maps**: Uses polylines with proper coordinate conversion
- [ ] **OSM**: Uses PolylineLayer with coordinate transformation
- [ ] **Bounds calculation**: Correctly calculates min/max lat/lng from route points

## 4. Edit Location Mode (Real Coordinates)
- [ ] **Edit button tap**: Enters edit mode with search field and center marker
- [ ] **Drag interaction**: Dragging marker updates coordinates in real-time
- [ ] **Coordinate accuracy**: Uses proper screen-to-coordinate conversion (not mock values)
- [ ] **Address update**: Reverse geocoding updates address as coordinates change
- [ ] **Save functionality**: Saves new coordinates and updates client marker
- [ ] **Cancel functionality**: Cancels changes and returns to original state
- [ ] **Google Maps**: Uses Projection API for coordinate conversion
- [ ] **Yandex Maps**: Uses windowToWorld/worldToWindow methods
- [ ] **OSM**: Uses proper coordinate transformation calculations

## 5. MyLocation Layer Unification
- [ ] **enableLocation: true**: Shows user location marker on all providers
- [ ] **Google Maps**: myLocationEnabled shows blue dot with accuracy circle
- [ ] **Yandex Maps**: userLocationLayer shows user position marker
- [ ] **OSM**: Custom user location marker in MarkerLayer
- [ ] **Location updates**: Marker updates when location changes via onLocationUpdate
- [ ] **Permission handling**: Graceful handling when location permission denied

## 6. Fullscreen Mode
- [ ] **Fullscreen button**: Opens fullscreen map page with navigation
- [ ] **State preservation**: Current center, zoom, markers, routes preserved
- [ ] **Provider switching**: Dropdown allows switching between Google/Yandex/OSM
- [ ] **Controls overlay**: Auto-hiding controls with zoom and location buttons
- [ ] **Back navigation**: Returns to detail page with updated state
- [ ] **State restoration**: Detail page camera animates to fullscreen position

## 7. Error Handling and Offline Support
- [ ] **Network offline**: Shows "Internetga ulanish yo'q" snackbar
- [ ] **Provider failure**: Falls back to OSM when Google/Yandex fail to load
- [ ] **Location failure**: Shows appropriate error messages for location issues
- [ ] **Route failure**: Displays "Marshrutni hisoblashda xatolik" snackbar
- [ ] **Initialization errors**: Shows retry button in error widget
- [ ] **Connectivity monitoring**: Real-time online/offline status updates

## 8. Cross-Provider Consistency
- [ ] **Animation timing**: All providers use 900-1200ms duration
- [ ] **Easing curves**: Consistent easeInOutCubic animation feel
- [ ] **Zoom levels**: Same zoom range and behavior across providers
- [ ] **Marker appearance**: Similar visual styling for markers
- [ ] **Route styling**: Blue polylines with consistent width
- [ ] **Control positioning**: Identical UI layout and positioning

## 9. Performance and Edge Cases
- [ ] **Large routes**: Handles routes with 100+ points smoothly
- [ ] **Many markers**: Clustering works with 50+ markers
- [ ] **Rapid interactions**: No crashes with rapid button tapping
- [ ] **Memory leaks**: No memory issues after repeated navigation
- [ ] **Orientation changes**: Handles screen rotation properly
- [ ] **Background/foreground**: Maintains state when app backgrounded

## 10. Integration Testing
- [ ] **MapDetailPage**: All buttons functional and responsive
- [ ] **FullscreenMapPage**: State preservation and navigation
- [ ] **UnifiedMapController**: All animation methods work
- [ ] **LocationManager**: Proper location updates and error handling
- [ ] **RouteManager**: Route creation and display
- [ ] **MarkerManager**: Clustering and marker management

## Test Environment Setup
- **Device**: Physical Android/iOS device or emulator
- **Location**: Enable GPS and grant location permissions
- **Network**: Test both online and offline scenarios
- **Providers**: Test all three map providers (Google/Yandex/OSM)
- **Data**: Use real trading point data with valid coordinates

## Expected Results
- ✅ All animations are smooth and consistent across providers
- ✅ Auto-collapse works reliably after 3 seconds
- ✅ Route drawing and fitBounds function correctly
- ✅ Edit location uses real coordinate transformation
- ✅ User location displays on all providers
- ✅ Fullscreen preserves and restores state
- ✅ Error handling provides good user experience
- ✅ No crashes or runtime exceptions
- ✅ Performance remains smooth with large datasets