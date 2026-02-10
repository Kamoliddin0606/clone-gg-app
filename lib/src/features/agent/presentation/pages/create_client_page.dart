import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/business_region.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/sales_channel.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_class.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point_type.dart';
import 'package:gloria_marketing_flutter/src/core/services/location_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gloria_marketing_flutter/src/core/services/address_resolver_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/faktura_company_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/faktura_auth_service.dart';
import 'package:gloria_marketing_flutter/src/core/models/faktura_company_details.dart';
import 'package:gloria_marketing_flutter/src/core/models/scanned_document_data.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/document_scanner_widget.dart';
import 'package:gloria_marketing_flutter/src/core/services/gemini_document_scanner_service.dart';

/// Page for creating a new client (trading point)
/// Beautiful, user-friendly form with all required fields
class CreateClientPage extends StatefulWidget {
  const CreateClientPage({super.key});

  @override
  State<CreateClientPage> createState() => _CreateClientPageState();
}

class _CreateClientPageState extends State<CreateClientPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Form controllers
  final _nameController = TextEditingController();
  final _signboardController = TextEditingController();
  final _innController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _addressDeliveryController = TextEditingController();
  final _referencePointController = TextEditingController();
  final _responsiblePhoneController = TextEditingController();
  final _directorController = TextEditingController();
  final _mfoController = TextEditingController();
  final _bankAccountController = TextEditingController();

  // Location
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;

  // Region selection
  List<BusinessRegion> _regions = [];
  BusinessRegion? _selectedRegion;
  bool _isLoadingRegions = true;

  // Trade point type (now cascading based on channel)
  TradingPointType? _selectedTradePointType;
  List<TradingPointType> _allTradingPointTypes = [];
  List<TradingPointType> _filteredTradingPointTypes = [];
  bool _isLoadingTypes = true;

  // Sales classifiers
  List<SalesChannel> _salesChannels = [];
  List<ClientClass> _clientClasses = [];
  SalesChannel? _selectedChannel;
  ClientClass? _selectedClientClass;
  bool _isLoadingClassifiers = true;

  // Submission state
  bool _isSubmitting = false;

  // Track if addresses were auto-filled
  bool _addressAutoFilled = false;

  // Faktura.uz integration
  bool _isFetchingCompanyData = false;
  bool _companyDataFetched = false;
  bool _addressFilledFromFaktura = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _loadRegions();
    _loadTradePointTypes();
    _loadSalesClassifiers();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _signboardController.dispose();
    _innController.dispose();
    _contactPersonController.dispose();
    _contactPhoneController.dispose();
    _addressController.dispose();
    _addressDeliveryController.dispose();
    _referencePointController.dispose();
    _responsiblePhoneController.dispose();
    _directorController.dispose();
    _mfoController.dispose();
    _bankAccountController.dispose();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    try {
      final dbService = sl<ApiDatabaseService>();
      final regions = await dbService.getBusinessRegions();

      if (mounted) {
        setState(() {
          _regions = regions;
          _isLoadingRegions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRegions = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.regionsLoadError(e.toString()) ??
                  'Hududlarni yuklashda xatolik: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearFormForScan() {
    _nameController.clear();
    _signboardController.clear();
    _directorController.clear();
    _innController.clear();
    _addressController.clear();
    _addressDeliveryController.clear();
    _contactPhoneController.clear();
    _mfoController.clear();
    _bankAccountController.clear();

    setState(() {
      _selectedRegion = null;
      _companyDataFetched = false;
      _addressFilledFromFaktura = false;
    });
  }

  /// Load trading point types from data sync service
  /// Will be filtered by selected channel (cascading dropdown)
  Future<void> _loadTradePointTypes() async {
    try {
      final dataSyncService = sl<DataSyncService>();
      
      // Load all trading point types
      final types = await dataSyncService.getCachedTradingPointTypes();

      if (mounted) {
        setState(() {
          _allTradingPointTypes = types;
          // Initially show all types (no channel selected yet)
          _filteredTradingPointTypes = types;
          _isLoadingTypes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allTradingPointTypes = [];
          _filteredTradingPointTypes = [];
          _isLoadingTypes = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.tradingPointTypesLoadError ??
                  'Savdo nuqtasi turlarini yuklashda xatolik: $e',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Load sales classifiers (channels and classes) from data sync service
  Future<void> _loadSalesClassifiers() async {
    try {
      final dataSyncService = sl<DataSyncService>();
      
      // Sync classifiers from server
      await dataSyncService.syncSalesClassifiers();
      
      // Load from cache
      final channels = await dataSyncService.getCachedSalesChannels();
      final classes = await dataSyncService.getCachedClientClasses();
      
      if (mounted) {
        setState(() {
          _salesChannels = channels;
          _clientClasses = classes;
          _isLoadingClassifiers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _salesChannels = [];
          _clientClasses = [];
          _isLoadingClassifiers = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sales classifiers yuklashda xatolik: $e',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Check if location service is available
      final locationService = sl<LocationService>();
      final storedLocation = locationService.getStoredLocation();

      double? lat, lng;

      if (storedLocation != null) {
        lat = storedLocation['latitude'] as double?;
        lng = storedLocation['longitude'] as double?;
      } else {
        // Try to get fresh location
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
        lat = position.latitude;
        lng = position.longitude;
      }

      if (mounted && lat != null && lng != null) {
        setState(() {
          _latitude = lat;
          _longitude = lng;
        });

        // Resolve address from coordinates
        await _resolveAddressFromCoordinates(lat, lng);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.locationError(e.toString()) ??
                  'Joylashuvni olishda xatolik: $e',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  /// Resolve address from coordinates using AddressResolverService
  Future<void> _resolveAddressFromCoordinates(double lat, double lng) async {
    try {
      final prefs = sl<SharedPreferencesService>();
      final resolver = AddressResolverService(
        yandexApiKey: prefs.getYandexMapsToken(),
        googleApiKey: prefs.getGoogleMapsToken(),
      );

      final address = await resolver.resolveAddress(lat, lng);

      if (mounted && address.confidence > 0.3) {
        final formattedAddress = address.toFormattedString();
        setState(() {
          // If address was filled from Faktura, only update delivery address
          if (_addressFilledFromFaktura) {
            _addressDeliveryController.text = formattedAddress;
          } else {
            // Auto-fill both address fields with formatted address
            _addressController.text = formattedAddress;
            _addressDeliveryController.text = formattedAddress;
            _addressAutoFilled = true;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.addressDetected ??
                  'Manzil aniqlandi va avtomatik to\'ldirildi',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Silent fail - address resolution is optional
      debugPrint('Address resolution failed: $e');
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseSelectRegion ??
                'Iltimos, hududni tanlang',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedChannel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseSelectSalesChannel ??
                'Iltimos, mijoz kanalini tanlang',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedTradePointType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseSelectTradePointType ??
                'Iltimos, savdo nuqtasi turini tanlang',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedClientClass == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseSelectClientClass ??
                'Iltimos, mijoz klassini tanlang',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.locationDataNotFound ??
                'Joylashuv ma\'lumotlari topilmadi',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check internet connection
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.noInternetConnection ??
                'Internet aloqasi yo\'q. Iltimos, internetga ulaning',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = sl<SharedPreferencesService>();
      final soapService = sl<SoapApiService>();

      final userCode = prefs.getUserCode() ?? '';

      if (userCode.isEmpty) {
        throw Exception('Foydalanuvchi kodi topilmadi');
      }

      final result = await soapService.setClient(
        name: _nameController.text.trim(),
        signboard: _signboardController.text.trim(),
        inn: _innController.text.trim(),
        tradePointType: _selectedTradePointType!.name,
        contactPerson: _contactPersonController.text.trim(),
        contactPersonPhone: _contactPhoneController.text.trim(),
        address: _addressController.text.trim(),
        addressDelivery: _addressDeliveryController.text.trim().isEmpty
            ? _addressController.text.trim()
            : _addressDeliveryController.text.trim(),
        referencePoint: _referencePointController.text.trim(),
        responsiblePersonPhone: _responsiblePhoneController.text.trim().isEmpty
            ? _contactPhoneController.text.trim()
            : _responsiblePhoneController.text.trim(),
        longitude: _longitude!,
        latitude: _latitude!,
        codeUser: userCode,
        codeRegion: _selectedRegion!.code,
        director: _directorController.text.trim(),
        mfo: _mfoController.text.trim(),
        bankAccount: _bankAccountController.text.trim(),
        channelCode: _selectedChannel?.name, // Send channel NAME
        clientClass: _selectedClientClass?.classCode, // Send class NAME
      );

      if (result['success'] == true) {
        // Show success message
        if (mounted) {
          _showSuccessDialog(result['clientCode']);
        }
      } else {
        throw Exception(result['message'] ?? 'Noma\'lum xatolik');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.errorOccurredPrefix ?? 'Xatolik'}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog(String? clientCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green.shade600,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Mijoz yaratildi!',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _nameController.text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            if (clientCode != null && clientCode.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Kod: $clientCode',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Ma\'lumotlar sinxronlanmoqda...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    // Sync data and return
    _syncAndReturn(clientCode);
  }

  Future<void> _syncAndReturn(String? clientCode) async {
    try {
      final dataSyncService = sl<DataSyncService>();
      final prefs = sl<SharedPreferencesService>();
      final userCode = prefs.getUserCode() ?? '';
      final password = prefs.getPassword() ?? '';

      if (userCode.isNotEmpty && password.isNotEmpty) {
        // Sync clients
        await dataSyncService.syncClients(
          userCode: userCode,
          password: password,
          forceRefresh: true,
        );
      }
    } catch (e) {
      // Ignore sync errors
    }

    if (mounted) {
      Navigator.of(context).pop(); // Close dialog
      Navigator.of(
        context,
      ).pop(clientCode); // Return to previous page with client code
    }
  }

  /// Fetch company data from Faktura.uz by INN
  Future<void> _fetchCompanyDataFromFaktura() async {
    final inn = _innController.text.trim();
    
    if (inn.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fakturaEnterInn),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate INN format
    final fakturaService = sl<FakturaCompanyService>();
    if (!fakturaService.isValidInn(inn)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.fakturaInvalidInnFormat),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isFetchingCompanyData = true);

    try {
      final companyDetails = await fakturaService.getCompanyDetails(inn);
      
      if (mounted) {
        await _populateFormWithCompanyData(companyDetails);
        
        setState(() {
          _companyDataFetched = true;
          _isFetchingCompanyData = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.fakturaCompanyDataLoaded(
                companyDetails.companyName,
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingCompanyData = false);
        
        // Map error codes to localized messages
        String errorMessage;
        final l10n = AppLocalizations.of(context)!;
        
        if (e is FakturaCompanyException) {
          switch (e.message) {
            case 'INN_EMPTY':
              errorMessage = l10n.fakturaInnEmpty;
              break;
            case 'AUTH_ERROR':
              errorMessage = l10n.fakturaAuthErrorRetry;
              break;
            case 'COMPANY_NOT_FOUND':
              errorMessage = l10n.fakturaCompanyNotFound;
              break;
            case 'INVALID_REQUEST':
              errorMessage = l10n.fakturaInvalidRequest;
              break;
            case 'SERVER_ERROR':
              errorMessage = l10n.fakturaServerError(e.statusCode?.toString() ?? '');
              break;
            case 'NETWORK_ERROR':
              errorMessage = l10n.fakturaNetworkError;
              break;
            default:
              errorMessage = '${l10n.error}: ${e.message}';
          }
        } else if (e is FakturaAuthException) {
          switch (e.message) {
            case 'AUTH_ERROR':
              errorMessage = l10n.fakturaAuthError;
              break;
            case 'TOKEN_REFRESH_ERROR':
              errorMessage = l10n.fakturaTokenRefreshError;
              break;
            case 'NETWORK_ERROR':
              errorMessage = l10n.fakturaNetworkError;
              break;
            default:
              errorMessage = '${l10n.error}: ${e.message}';
          }
        } else {
          errorMessage = '${l10n.error}: $e';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  /// Populate form fields with company data from Faktura.uz
  Future<void> _populateFormWithCompanyData(FakturaCompanyDetails company) async {
    // Fill company name
    _nameController.text = company.companyName;
    _signboardController.text = company.companyName;

    // Fill director info
    if (company.directorName != null && company.directorName!.isNotEmpty) {
      _directorController.text = company.directorName!;
    }

    // Fill bank details from primary account
    final primaryAccount = company.getPrimaryAccount();
    if (primaryAccount != null) {
      _mfoController.text = primaryAccount.bankMfo;
      _bankAccountController.text = primaryAccount.accountCode;
    }

    // Fill phone if available
    if (company.phoneNumber != null && company.phoneNumber!.isNotEmpty) {
      _contactPhoneController.text = company.phoneNumber!;
    }

    // Fill address - combine Region, District, and CompanyAddress
    final fullAddress = company.getFullAddress();
    if (fullAddress.isNotEmpty) {
      _addressController.text = fullAddress;
      _addressFilledFromFaktura = true;
      
      // If delivery address is empty, also fill it
      if (_addressDeliveryController.text.trim().isEmpty) {
        // Try to resolve delivery address from current location
        if (_latitude != null && _longitude != null) {
          await _resolveAddressFromCoordinates(_latitude!, _longitude!);
        } else {
          // Fallback: use same address
          _addressDeliveryController.text = fullAddress;
        }
      }
    }

    // Try to match region from Faktura to existing BusinessRegion
    await _matchRegionFromFaktura(company.regionCode, company.region);
  }

  /// Try to match Faktura region to existing BusinessRegion
  Future<void> _matchRegionFromFaktura(String regionCode, String regionName) async {
    try {
      // Try to find matching region by name or code
      final matchingRegion = _regions.where((region) {
        final nameMatch = region.name.toLowerCase().contains(regionName.toLowerCase()) ||
                         regionName.toLowerCase().contains(region.name.toLowerCase());
        return nameMatch;
      }).firstOrNull;

      if (matchingRegion != null) {
        setState(() {
          _selectedRegion = matchingRegion;
        });
      } else {
        // Show info that region needs to be selected manually
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.fakturaRegionNotFound(regionName),
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error matching region: $e');
    }
  }

  /// Handle scanned document data from AI scanner
  /// Fills form fields and triggers Faktura verification if STIR is present
  Future<void> _handleScannedData(ScannedDocumentData data) async {
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    int filledCount = 0;

    // Overwrite fields with scanned data
    if (data.organizationName != null) {
      _nameController.text = data.organizationName!;
      _signboardController.text = data.organizationName!;
      filledCount += 2;
    }

    if (data.directorName != null) {
      _directorController.text = data.directorName!;
      filledCount++;
    }

    if (data.address != null) {
      _addressController.text = data.address!;
      _addressDeliveryController.text = data.address!;
      filledCount++;
    }

    if (data.phoneNumber != null) {
      _contactPhoneController.text = data.phoneNumber!;
      filledCount++;
    }

    if (data.mfo != null) {
      _mfoController.text = data.mfo!;
      filledCount++;
    }
    if (data.bankAccount != null) {
      _bankAccountController.text = data.bankAccount!;
      filledCount++;
    }

    // Fill INN/STIR - this is crucial for Faktura verification
    if (data.inn != null) {
      _innController.text = data.inn!;
      filledCount++;
    }

    setState(() {});

    // Show success message
    if (filledCount > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.scannerFormUpdated),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }

    // If STIR/INN was extracted, verify with Faktura.uz
    if (data.hasInn && _innController.text.trim().isNotEmpty) {
      await _verifyAndUpdateFromFaktura();
    }
  }

  /// Verify scanned INN with Faktura.uz and update mismatched/empty fields
  Future<void> _verifyAndUpdateFromFaktura() async {
    final inn = _innController.text.trim();
    if (inn.isEmpty) return;

    final fakturaService = sl<FakturaCompanyService>();
    if (!fakturaService.isValidInn(inn)) return;

    final l10n = AppLocalizations.of(context)!;

    // Show verifying message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(l10n.scannerVerifyingWithFaktura),
          ],
        ),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 10),
      ),
    );

    try {
      final companyDetails = await fakturaService.getCompanyDetails(inn);
      if (!mounted) return;

      // Hide the verifying snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      int updatedCount = 0;

      // Compare and update fields - update if empty or different
      // Organization name
      if (companyDetails.companyName.isNotEmpty) {
        if (_nameController.text.trim().isEmpty ||
            _nameController.text.trim() != companyDetails.companyName) {
          _nameController.text = companyDetails.companyName;
          updatedCount++;
        }
        if (_signboardController.text.trim().isEmpty) {
          _signboardController.text = companyDetails.companyName;
        }
      }

      // Director
      if (companyDetails.directorName != null && companyDetails.directorName!.isNotEmpty) {
        if (_directorController.text.trim().isEmpty ||
            _directorController.text.trim() != companyDetails.directorName) {
          _directorController.text = companyDetails.directorName!;
          updatedCount++;
        }
      }

      // Address
      final fullAddress = companyDetails.getFullAddress();
      if (fullAddress.isNotEmpty) {
        if (_addressController.text.trim().isEmpty ||
            _addressController.text.trim() != fullAddress) {
          _addressController.text = fullAddress;
          _addressFilledFromFaktura = true;
          updatedCount++;
        }
      }

      // Phone
      if (companyDetails.phoneNumber != null && companyDetails.phoneNumber!.isNotEmpty) {
        if (_contactPhoneController.text.trim().isEmpty) {
          _contactPhoneController.text = companyDetails.phoneNumber!;
          updatedCount++;
        }
      }

      // Bank details
      final primaryAccount = companyDetails.getPrimaryAccount();
      if (primaryAccount != null) {
        if (_mfoController.text.trim().isEmpty ||
            _mfoController.text.trim() != primaryAccount.bankMfo) {
          _mfoController.text = primaryAccount.bankMfo;
          updatedCount++;
        }
        if (_bankAccountController.text.trim().isEmpty ||
            _bankAccountController.text.trim() != primaryAccount.accountCode) {
          _bankAccountController.text = primaryAccount.accountCode;
          updatedCount++;
        }
      }

      // Try to match region
      await _matchRegionFromFaktura(companyDetails.regionCode, companyDetails.region);

      setState(() {
        _companyDataFetched = true;
      });

      // Show result message
      if (updatedCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.scannerDataMismatch(updatedCount)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.scannerDataVerified),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      // Silent fail - Faktura verification is optional enhancement
      debugPrint('Faktura verification failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.createClientTitle),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colorScheme.primaryContainer.withOpacity(0.1),
                colorScheme.surface,
              ],
            ),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Warning banner about territory
                _buildTerritoryWarningBanner(colorScheme, l10n),
                const SizedBox(height: 16),

                // Header card with location
                _buildLocationCard(theme, colorScheme),
                const SizedBox(height: 16),

                // AI Document Scanner
                DocumentScannerWidget(
                  scannerService: sl<GeminiDocumentScannerService>(),
                  onScanStarted: _clearFormForScan,
                  onDataExtracted: _handleScannedData,
                ),
                const SizedBox(height: 20),

                // Basic info section
                _buildSectionHeader(
                  theme,
                  l10n.createClientBasicInfo,
                  Icons.store,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _nameController,
                  label: l10n.createClientClientName,
                  hint: l10n.createClientClientNameHint,
                  icon: Icons.business,
                  isRequired: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _signboardController,
                  label: l10n.createClientSignboard,
                  hint: l10n.createClientSignboardHint,
                  icon: Icons.signpost,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _buildInnFieldWithFetchButton(colorScheme, l10n),
                const SizedBox(height: 12),
                _buildSalesChannelSelector(theme, colorScheme),
                const SizedBox(height: 12),
                _buildTradePointTypeSelector(theme, colorScheme),
                const SizedBox(height: 12),
                _buildClientClassSelector(theme, colorScheme),
                const SizedBox(height: 12),
                _buildRegionSelector(theme, colorScheme),

                const SizedBox(height: 24),

                // Contact info section
                _buildSectionHeader(
                  theme,
                  l10n.createClientContactInfo,
                  Icons.contact_phone,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _contactPersonController,
                  label: l10n.createClientContactPerson,
                  hint: l10n.createClientContactPersonHint,
                  icon: Icons.person,
                  isRequired: true,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _contactPhoneController,
                  label: l10n.createClientPhone,
                  hint: l10n.createClientPhoneHint,
                  icon: Icons.phone,
                  isRequired: true,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _responsiblePhoneController,
                  label: l10n.createClientResponsiblePhone,
                  hint: l10n.createClientResponsiblePhoneHint,
                  icon: Icons.phone_android,
                  keyboardType: TextInputType.phone,
                ),

                const SizedBox(height: 24),

                // Address section
                _buildSectionHeader(
                  theme,
                  l10n.createClientAddressInfo,
                  Icons.location_on,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _addressController,
                  label: l10n.createClientAddress,
                  hint: l10n.createClientAddressHint,
                  icon: Icons.home,
                  isRequired: true,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                if (_addressAutoFilled) _buildAutoFillHelperText(l10n),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _addressDeliveryController,
                  label: l10n.createClientDeliveryAddress,
                  hint: l10n.createClientDeliveryAddressHint,
                  icon: Icons.local_shipping,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                if (_addressAutoFilled) _buildAutoFillHelperText(l10n),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _referencePointController,
                  label: l10n.createClientLandmark,
                  hint: l10n.createClientLandmarkHint,
                  icon: Icons.place,
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 24),

                // Bank details section (optional)
                _buildSectionHeader(
                  theme,
                  l10n.createClientBankInfo,
                  Icons.account_balance,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _directorController,
                  label: l10n.createClientDirector,
                  hint: l10n.createClientDirectorHint,
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _mfoController,
                  label: l10n.createClientMfo,
                  hint: l10n.createClientMfoHint,
                  icon: Icons.account_balance_wallet,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 5,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _bankAccountController,
                  label: l10n.createClientBankAccount,
                  hint: l10n.createClientBankAccountHint,
                  icon: Icons.credit_card,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 20,
                ),

                const SizedBox(height: 32),

                // Submit button
                _buildSubmitButton(theme, colorScheme),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoFillHelperText(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 4),
      child: Row(
        children: [
          Icon(Icons.auto_fix_high, size: 12, color: Colors.red.shade600),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              l10n.createClientAutoFilledHint,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerritoryWarningBanner(
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.createClientTerritoryWarningTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.createClientTerritoryWarningMessage,
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isGettingLocation
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  )
                : Icon(
                    _latitude != null ? Icons.location_on : Icons.location_off,
                    color: _latitude != null ? Colors.green : Colors.orange,
                    size: 24,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (ctx) {
                    final l10n = AppLocalizations.of(ctx);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.location ?? 'Joylashuv',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _latitude != null && _longitude != null
                              ? '${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                              : _isGettingLocation
                              ? (l10n?.creatingLocation ?? 'Aniqlanmoqda...')
                              : (l10n?.locationNotFound ??
                                    'Joylashuv topilmadi'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer.withOpacity(
                              0.8,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isGettingLocation ? null : _getCurrentLocation,
            icon: Icon(Icons.refresh, color: colorScheme.onPrimaryContainer),
            tooltip: AppLocalizations.of(context)?.refreshLabel ?? 'Yangilash',
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildInnFieldWithFetchButton(
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _innController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 14,
            style: TextStyle(color: colorScheme.onSurface),
            decoration: InputDecoration(
              labelText: l10n.createClientInn,
              hintText: l10n.createClientInnHint,
              prefixIcon: Icon(Icons.numbers, color: colorScheme.primary),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colorScheme.error),
              ),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isFetchingCompanyData ? null : _fetchCompanyDataFromFaktura,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _isFetchingCompanyData
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _companyDataFetched ? Icons.refresh : Icons.download,
                            color: colorScheme.onPrimary,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _companyDataFetched 
                                ? AppLocalizations.of(context)!.fakturaRefreshCompanyData
                                : AppLocalizations.of(context)!.fakturaFetchCompanyData,
                            style: TextStyle(
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    int? maxLength,
    int maxLines = 1,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      maxLines: maxLines,
      textCapitalization: textCapitalization,
      style: TextStyle(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: isRequired ? '$label *' : label,
        hintText: hint,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        counterText: '',
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Bu maydon to\'ldirilishi shart';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildTradePointTypeSelector(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    if (_isLoadingTypes) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)?.tradingPointTypesLoading ??
                  'Savdo nuqtasi turlari yuklanmoqda...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    // Show message if channel not selected
    if (_selectedChannel == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context)?.pleaseSelectChannelFirst ??
                    'Avval mijoz kanalini tanlang',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<TradingPointType>(
        value: _selectedTradePointType,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)?.tradingPointTypeRequired ??
              'Savdo nuqtasi turi *',
          prefixIcon: Icon(Icons.category, color: colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: _filteredTradingPointTypes.map((type) {
          return DropdownMenuItem(
            value: type,
            child: Text(type.name),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedTradePointType = value),
        validator: (value) {
          if (value == null) {
            return AppLocalizations.of(context)?.pleaseSelectTradePointType ??
                'Savdo nuqtasi turini tanlang';
          }
          return null;
        },
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSalesChannelSelector(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoadingClassifiers) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)?.salesChannelsLoading ??
                  'Kanallar yuklanmoqda...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<SalesChannel>(
        value: _selectedChannel,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)?.salesChannelRequired ??
              'Mijoz kanali *',
          prefixIcon: Icon(Icons.store, color: colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: _salesChannels.map((channel) {
          return DropdownMenuItem(
            value: channel,
            child: Text(channel.name),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedChannel = value;
            // Reset trade point type when channel changes
            _selectedTradePointType = null;
            // Filter trading point types by selected channel
            if (value != null) {
              _filteredTradingPointTypes = _allTradingPointTypes
                  .where((type) => type.channelGroup == value.name)
                  .toList();
            } else {
              _filteredTradingPointTypes = _allTradingPointTypes;
            }
          });
        },
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildClientClassSelector(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoadingClassifiers) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppLocalizations.of(context)?.clientClassesLoading ??
                  'Klasslar yuklanmoqda...',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<ClientClass>(
        value: _selectedClientClass,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)?.clientClassRequired ??
              'Mijoz klassi *',
          prefixIcon: Icon(Icons.class_, color: colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: _clientClasses.map((clientClass) {
          return DropdownMenuItem(
            value: clientClass,
            child: Text(clientClass.classCode),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedClientClass = value),
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildRegionSelector(ThemeData theme, ColorScheme colorScheme) {
    if (_isLoadingRegions) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.map, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                AppLocalizations.of(context)?.regionsLoading ??
                    'Hududlar yuklanmoqda...',
              ),
            ),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: DropdownButtonFormField<BusinessRegion>(
        value: _selectedRegion,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context)?.regionRequired ??
              'Hudud *',
          prefixIcon: Icon(Icons.map, color: colorScheme.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: _regions.map((region) {
          return DropdownMenuItem(
            value: region,
            child: Text(region.name, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (value) => setState(() => _selectedRegion = value),
        validator: (value) {
          if (value == null) {
            return 'Hududni tanlang';
          }
          return null;
        },
        isExpanded: true,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, ColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 56,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _isSubmitting ? 0 : 4,
          shadowColor: colorScheme.primary.withOpacity(0.4),
        ),
        child: _isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.creating),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_business),
                  const SizedBox(width: 12),
                  Builder(
                    builder: (ctx) => Text(
                      AppLocalizations.of(ctx)!.createClient,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
