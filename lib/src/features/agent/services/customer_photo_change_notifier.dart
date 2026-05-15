import 'dart:async';

/// Global pub/sub for "this customer's photos changed" events.
///
/// Emitted by [CustomerPhotoCubit] after every successful mutation
/// (add / patch / replace / delete). Subscribed by widgets that
/// display the customer's primary photo outside the gallery flow —
/// e.g. [CustomerPrimaryThumbnail] in trading-point grid tiles and
/// avatars, and the carousel preview on the client detail sheet.
///
/// The single payload is the customer id (the same string the cubit
/// was constructed with — `tradingPoint.id` / `code_1c`). Subscribers
/// filter to their own customer and reload via
/// [CustomerPrimaryPhotoCache.invalidate].
class CustomerPhotoChangeNotifier {
  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void notifyChanged(String customerId) {
    if (_controller.isClosed) return;
    _controller.add(customerId);
  }

  void dispose() {
    _controller.close();
  }
}
