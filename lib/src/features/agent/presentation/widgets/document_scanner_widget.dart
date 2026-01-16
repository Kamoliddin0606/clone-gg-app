import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/models/scanned_document_data.dart';
import 'package:gloria_marketing_flutter/src/core/services/gemini_document_scanner_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/gemini_base_service.dart';

/// Widget for scanning organization certificates using AI
/// 
/// Provides camera capture and gallery selection with visual feedback.
/// Uses GeminiDocumentScannerService for AI-powered document scanning.
/// 
/// The scanner service should be obtained from the service locator:
/// ```dart
/// DocumentScannerWidget(
///   scannerService: sl<GeminiDocumentScannerService>(),
///   onDataExtracted: (data) => handleData(data),
/// )
/// ```
class DocumentScannerWidget extends StatefulWidget {
  /// Callback when document data is successfully extracted
  final Function(ScannedDocumentData data) onDataExtracted;
  
  /// Gemini document scanner service instance
  final GeminiDocumentScannerService scannerService;
  
  /// Callback when scan operation starts
  final VoidCallback? onScanStarted;
  
  /// Callback when scan operation completes
  final VoidCallback? onScanCompleted;

  const DocumentScannerWidget({
    super.key,
    required this.onDataExtracted,
    required this.scannerService,
    this.onScanStarted,
    this.onScanCompleted,
  });

  @override
  State<DocumentScannerWidget> createState() => _DocumentScannerWidgetState();
}

class _DocumentScannerWidgetState extends State<DocumentScannerWidget>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  bool _isScanning = false;
  String? _errorMessage;
  ScannedDocumentData? _lastScanResult;

  /// Get scanner service from widget
  GeminiDocumentScannerService get _scannerService => widget.scannerService;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _captureFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85, // Optimize image size while maintaining quality
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showError('CAMERA_ERROR');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image != null) {
        await _processImage(image);
      }
    } catch (e) {
      _showError('GALLERY_ERROR');
    }
  }

  Future<void> _processImage(XFile image) async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
    });
    widget.onScanStarted?.call();
    _animationController.repeat(reverse: true);

    try {
      // Read image bytes efficiently
      final bytes = await image.readAsBytes();

      // Scan document with AI
      final result = await _scannerService.scanDocument(bytes);

      if (mounted) {
        setState(() {
          _lastScanResult = result;
          _isScanning = false;
        });
        _animationController.stop();
        _animationController.reset();

        if (result.hasData) {
          widget.onDataExtracted(result);
          widget.onScanCompleted?.call();
        } else {
          _showError('NO_DATA_EXTRACTED');
        }
      }
    } on GeminiException catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        _animationController.stop();
        _animationController.reset();
        _showError(_mapGeminiErrorCode(e.code));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        _animationController.stop();
        _animationController.reset();
        _showError('UNKNOWN_ERROR');
      }
    }
  }

  void _showError(String code) {
    setState(() => _errorMessage = code);
  }

  /// Map GeminiErrorCode to legacy error code string for localization
  String _mapGeminiErrorCode(GeminiErrorCode code) {
    switch (code) {
      case GeminiErrorCode.networkError:
        return 'NETWORK_ERROR';
      case GeminiErrorCode.authError:
        return 'AUTH_ERROR';
      case GeminiErrorCode.apiKeyNotFound:
      case GeminiErrorCode.apiKeyError:
        return 'AUTH_ERROR';
      case GeminiErrorCode.rateLimitError:
        return 'RATE_LIMIT';
      case GeminiErrorCode.parseError:
        return 'PARSE_ERROR';
      case GeminiErrorCode.noContent:
        return 'NO_DATA_EXTRACTED';
      case GeminiErrorCode.invalidRequest:
        return 'IMAGE_EMPTY';
      default:
        return 'UNKNOWN_ERROR';
    }
  }

  String _getLocalizedError(BuildContext context, String code) {
    final l10n = AppLocalizations.of(context)!;
    switch (code) {
      case 'CAMERA_ERROR':
        return l10n.scannerCameraError;
      case 'GALLERY_ERROR':
        return l10n.scannerGalleryError;
      case 'IMAGE_EMPTY':
        return l10n.scannerImageEmpty;
      case 'NETWORK_ERROR':
        return l10n.scannerNetworkError;
      case 'AUTH_ERROR':
        return l10n.scannerAuthError;
      case 'RATE_LIMIT':
        return l10n.scannerRateLimitError;
      case 'NO_DATA_EXTRACTED':
        return l10n.scannerNoDataExtracted;
      case 'PARSE_ERROR':
        return l10n.scannerParseError;
      default:
        return l10n.scannerUnknownError;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer.withOpacity(0.3),
            colorScheme.secondaryContainer.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.document_scanner_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.scannerTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      l10n.scannerSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Scanning status or buttons
          if (_isScanning)
            _buildScanningIndicator(colorScheme, l10n)
          else
            _buildActionButtons(colorScheme, l10n),

          // Error message
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, 
                       color: colorScheme.error, 
                       size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getLocalizedError(context, _errorMessage!),
                      style: TextStyle(
                        color: colorScheme.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, 
                               color: colorScheme.error, 
                               size: 18),
                    onPressed: () => setState(() => _errorMessage = null),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],

          // Success indicator
          if (_lastScanResult != null && _lastScanResult!.hasData && !_isScanning) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, 
                             color: Colors.green, 
                             size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.scannerDataExtracted(_lastScanResult!.extractedFieldCount),
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScanningIndicator(ColorScheme colorScheme, AppLocalizations l10n) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: colorScheme.primary,
                      ),
                    ),
                    Icon(
                      Icons.auto_awesome,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.scannerProcessing,
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.scannerPleaseWait,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme, AppLocalizations l10n) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.camera_alt_outlined,
            label: l10n.scannerTakePhoto,
            onTap: _captureFromCamera,
            isPrimary: true,
            colorScheme: colorScheme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.photo_library_outlined,
            label: l10n.scannerChoosePhoto,
            onTap: _pickFromGallery,
            isPrimary: false,
            colorScheme: colorScheme,
          ),
        ),
      ],
    );
  }
}

/// Reusable action button for scanner widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final ColorScheme colorScheme;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary 
          ? colorScheme.primary 
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isPrimary 
                    ? colorScheme.onPrimary 
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isPrimary 
                        ? colorScheme.onPrimary 
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
