import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/soap_api_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/contract_type.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/district_contracting.dart';
import 'package:gloria_marketing_flutter/src/core/services/data_sync_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/searchable_client_dialog.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';

/// Modern contract creation form widget with animations and beautiful UI
/// 
/// This widget provides a comprehensive form for creating new contracts
/// with support for:
/// - Auto-filling client when filtered
/// - Contract type selection from cached data
/// - Date pickers with validation
/// - Real-time form validation
/// - Multi-language support
/// - Modern Material 3 design with animations
class CreateContractForm extends StatefulWidget {
  /// Pre-selected client code (auto-fill when navigating from filtered view)
  final String? preSelectedClientCode;
  
  /// Pre-selected client name for display
  final String? preSelectedClientName;
  
  /// List of available trading points/clients for selection
  final List<TradingPoint> availableClients;
  
  /// Callback when contract is successfully created
  final VoidCallback? onContractCreated;
  
  /// Callback to close the form
  final VoidCallback? onClose;

  const CreateContractForm({
    super.key,
    this.preSelectedClientCode,
    this.preSelectedClientName,
    required this.availableClients,
    this.onContractCreated,
    this.onClose,
  });

  @override
  State<CreateContractForm> createState() => _CreateContractFormState();
}

class _CreateContractFormState extends State<CreateContractForm>
    with SingleTickerProviderStateMixin {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Animation controller for form entrance
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  // Form controllers
  final _sumController = TextEditingController();
  final _numbReferenceController = TextEditingController();
  final _numbCertificateController = TextEditingController();
  final _numbPassportController = TextEditingController();
  
  // Form state
  TradingPoint? _selectedClient;
  String? _selectedContractType;
  DateTime _contractDate = DateTime.now();
  DateTime? _termReference;
  DateTime? _termCertificate;
  DateTime? _termPassport;
  bool _certificateUnlimited = false;
  bool _isSumFieldExpanded = false;
  
  // Data state
  List<ContractType> _contractTypes = [];
  List<DistrictContracting> _districtContracting = [];
  DistrictContracting? _selectedDistrict;
  bool _isLoadingTypes = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadContractTypes();
    _loadDistrictContracting();
    _initPreSelectedClient();
  }

  /// Initialize entrance animations
  void _initAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _animationController.forward();
  }

  /// Initialize pre-selected client if provided
  void _initPreSelectedClient() {
    if (widget.preSelectedClientCode != null) {
      // Find the client in available clients list
      final client = widget.availableClients.firstWhere(
        (c) => c.id == widget.preSelectedClientCode,
        orElse: () => TradingPoint(
          id: widget.preSelectedClientCode!,
          name: widget.preSelectedClientName ?? widget.preSelectedClientCode!,
          address: '',
          phone: '',
          ownerName: '',
          contactPerson: '',
          inn: '',
          status: '',
          lastVisitDate: '',
          hasOrders: false,
          hasContracts: false,
          isVisited: false,
          hasContract: false,
          latitude: 0,
          longitude: 0,
          region: '',
          district: '',
          signboard: '',
          referencePoint: '',
          responsiblePerson: '',
          responsiblePersonPhone: '',
          tradePointType: '',
          creditLimit: 0,
          accumulatedCredit: 0,
          codeRegion: '',
        ),
      );
      setState(() {
        _selectedClient = client;
      });
    }
  }

  /// Load contract types from cache or server
  Future<void> _loadContractTypes({bool forceRefresh = false}) async {
    try {
      setState(() {
        _isLoadingTypes = true;
        _errorMessage = null;
      });

      final dbService = sl<ApiDatabaseService>();
      
      // First try to get from cache (unless force refresh)
      var types = forceRefresh ? <ContractType>[] : await dbService.getContractTypes();
      
      // If cache is empty or force refresh, fetch from server
      if (types.isEmpty) {
        if (kDebugMode) {
          print('CreateContractForm: ${forceRefresh ? "Force refreshing" : "No cached"} contract types, fetching from server');
        }
        
        try {
          final soapService = sl<SoapApiService>();
          types = await soapService.getTypeOfContract();
          
          // Save to cache
          if (types.isNotEmpty) {
            await dbService.saveContractTypes(types);
            if (kDebugMode) {
              print('CreateContractForm: Saved ${types.length} contract types to cache');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('CreateContractForm: Error fetching contract types from server: $e');
          }
          // Continue with empty types - user can still fill other fields
        }
      }

      // Filter out invalid contract types and remove duplicates
      final validTypes = <String, ContractType>{};
      for (final type in types) {
        // Skip if name is empty or whitespace only
        if (type.name.trim().isEmpty) {
          if (kDebugMode) {
            print('CreateContractForm: Skipping contract type with empty name: ${type.code}');
          }
          continue;
        }
        
        // Keep only the first occurrence of each name (remove duplicates)
        if (!validTypes.containsKey(type.name)) {
          validTypes[type.name] = type;
        } else if (kDebugMode) {
          print('CreateContractForm: Skipping duplicate contract type name: ${type.name}');
        }
      }

      setState(() {
        _contractTypes = validTypes.values.toList();
        _isLoadingTypes = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('CreateContractForm: Error loading contract types: $e');
      }
      setState(() {
        _isLoadingTypes = false;
        _errorMessage = AppLocalizations.of(context)?.contractTypesLoadError ?? 'Error loading contract types';
      });
    }
  }

  /// Load district contracting data from cache or server
  Future<void> _loadDistrictContracting({bool forceRefresh = false}) async {
    try {
      final prefs = sl<SharedPreferencesService>();
      final dataSyncService = sl<DataSyncService>();
      
      final userCode = prefs.getUserCode() ?? '';
      final codeProject = prefs.getCodeProject() ?? '';
      
      // Try to get from cache first (unless force refresh)
      var districts = forceRefresh ? <DistrictContracting>[] : await dataSyncService.getCachedDistrictContracting();
      
      // If cache is empty or force refresh, fetch from server
      if (districts.isEmpty && userCode.isNotEmpty && codeProject.isNotEmpty) {
        if (kDebugMode) {
          print('CreateContractForm: ${forceRefresh ? "Force refreshing" : "No cached"} districts, fetching from server');
        }
        try {
          districts = await dataSyncService.syncDistrictContracting(
            userCode: userCode,
            codeProject: codeProject,
            forceRefresh: true,
          );
        } catch (e) {
          if (kDebugMode) {
            print('CreateContractForm: Error fetching districts from server: $e');
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _districtContracting = districts;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('CreateContractForm: Error loading district contracting: $e');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sumController.dispose();
    _numbReferenceController.dispose();
    _numbCertificateController.dispose();
    _numbPassportController.dispose();
    super.dispose();
  }

  /// Build XML request for debugging
  String _buildXmlRequest() {
    final prefs = sl<SharedPreferencesService>();
    final userCode = prefs.getUserCode() ?? '';
    final codeProject = prefs.getCodeProject() ?? '';
    final dateFormat = DateFormat('yyyy-MM-dd');
    
    final dateOfContract = dateFormat.format(_contractDate);
    final sumOfContract = double.tryParse(_sumController.text.replaceAll(' ', '')) ?? 0.0;
    final termReference = _termReference != null ? dateFormat.format(_termReference!) : '';
    final termCertificate = _termCertificate != null ? dateFormat.format(_termCertificate!) : '';
    final numbReference = _numbReferenceController.text.isEmpty ? '' : _numbReferenceController.text;
    final numbCertificate = _numbCertificateController.text.isEmpty ? '' : _numbCertificateController.text;
    final typeOfContract = _selectedContractType ?? '';
    final numbPassport = _numbPassportController.text.isEmpty ? '' : _numbPassportController.text;
    final termPassport = _termPassport != null ? dateFormat.format(_termPassport!) : '';
    final certificateUnlimited = _certificateUnlimited ? 1 : 0;
    final codeClient = _selectedClient?.id ?? '';
    final psCodeDistrict = _selectedDistrict?.codeDistrict ?? '';
    final psNameDistrict = _selectedDistrict?.nameDistrict ?? '';
    
    return '''
<soap:Envelope xmlns:soap="http://www.w3.org/2003/05/soap-envelope" xmlns:sam="http://www.sample-package.org">
   <soap:Header/>
   <soap:Body>
      <sam:SetContract>
         <sam:DateOfContract>$dateOfContract</sam:DateOfContract>
         <sam:CodeUser>$userCode</sam:CodeUser>
         <sam:CodeClient>$codeClient</sam:CodeClient>
         <sam:SumOfContract>$sumOfContract</sam:SumOfContract>
         <sam:TermReference>$termReference</sam:TermReference>
         <sam:TermCertificate>$termCertificate</sam:TermCertificate>
         <sam:NumbReference>$numbReference</sam:NumbReference>
         <sam:NumbCertificate>$numbCertificate</sam:NumbCertificate>
         <sam:TypeOfContract>$typeOfContract</sam:TypeOfContract>
         <sam:NumbPassport>$numbPassport</sam:NumbPassport>
         <sam:TermPassport>$termPassport</sam:TermPassport>
         <sam:CertificateUnlimited>$certificateUnlimited</sam:CertificateUnlimited>
         <sam:PS_CodeProject>$codeProject</sam:PS_CodeProject>
         <sam:PS_CodeDistrict>$psCodeDistrict</sam:PS_CodeDistrict>
         <sam:PS_NameDistrict>$psNameDistrict</sam:PS_NameDistrict>
      </sam:SetContract>
   </soap:Body>
</soap:Envelope>''';
  }

  /// Show XML request dialog
  void _showXmlRequestDialog() {
    final xmlRequest = _buildXmlRequest();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.code, color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8),
            Text(AppLocalizations.of(context)?.xmlRequestLabel ?? 'XML Request'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(maxHeight: 500),
          child: SingleChildScrollView(
            child: SelectableText(
              xmlRequest,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)?.close ?? 'Yopish'),
          ),
          FilledButton.icon(
            onPressed: () {
              final l10n = AppLocalizations.of(context)!;
              Clipboard.setData(ClipboardData(text: xmlRequest));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.xmlCopied),
                  behavior: SnackBarBehavior.floating,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: Icon(Icons.copy),
            label: Text(AppLocalizations.of(context)?.copy ?? 'Nusxa olish'),
          ),
        ],
      ),
    );
  }

  /// Submit the contract creation form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClient == null) {
      _showError(AppLocalizations.of(context)?.pleaseSelectClient ?? 'Please select a client');
      return;
    }

    if (_selectedContractType == null) {
      _showError(AppLocalizations.of(context)?.pleaseSelectContractType ?? 'Please select a contract type');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final prefs = sl<SharedPreferencesService>();
      final soapService = sl<SoapApiService>();
      
      final userCode = prefs.getUserCode() ?? '';
      final codeProject = prefs.getCodeProject() ?? '';
      
      // Format dates for API
      final dateFormat = DateFormat('yyyy-MM-dd');
      // Default minimal date for 1C (SQL Server minimum date)
      const defaultMinimalDate = '1753-01-01';
      
      final result = await soapService.setContract(
        dateOfContract: dateFormat.format(_contractDate),
        codeUser: userCode,
        codeClient: _selectedClient!.id,
        sumOfContract: double.tryParse(_sumController.text.replaceAll(' ', '')) ?? 0.0,
        termReference: _termReference != null ? dateFormat.format(_termReference!) : defaultMinimalDate,
        termCertificate: _termCertificate != null ? dateFormat.format(_termCertificate!) : defaultMinimalDate,
        numbReference: _numbReferenceController.text.isEmpty ? null : _numbReferenceController.text,
        numbCertificate: _numbCertificateController.text.isEmpty ? null : _numbCertificateController.text,
        typeOfContract: _selectedContractType!,
        numbPassport: _numbPassportController.text.isEmpty ? null : _numbPassportController.text,
        termPassport: _termPassport != null ? dateFormat.format(_termPassport!) : defaultMinimalDate,
        certificateUnlimited: _certificateUnlimited,
        psCodeProject: codeProject,
        psCodeDistrict: _selectedDistrict?.codeDistrict,
        psNameDistrict: _selectedDistrict?.nameDistrict,
      );

      if (result['success'] == true) {
        if (mounted) {
          _showSuccess(result['message'] ?? AppLocalizations.of(context)?.contractCreatedSuccessfully ?? 'Contract created successfully');
          widget.onContractCreated?.call();
        }
      } else {
        _showError(result['message'] ?? AppLocalizations.of(context)?.contractCreationError ?? 'Error creating contract');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CreateContractForm: Error creating contract: $e');
      }
      _showError('${AppLocalizations.of(context)?.contractCreationError ?? "Error creating contract"}: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// Show error message
  void _showError(String message) {
    setState(() {
      _errorMessage = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Show success message
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Pick a date using date picker
  Future<DateTime?> _pickDate({
    required DateTime? initialDate,
    required String helpText,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
      helpText: helpText,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              _buildHeader(theme, colorScheme, l10n),
              
              // Form content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Error message if any
                        if (_errorMessage != null)
                          _buildErrorBanner(colorScheme),
                        
                        const SizedBox(height: 16),
                        
                        // Client selection
                        _buildClientSelector(theme, colorScheme, l10n),
                        
                        const SizedBox(height: 20),
                        
                        // Contract type selection
                        _buildContractTypeSelector(theme, colorScheme, l10n),
                        
                        const SizedBox(height: 20),
                        
                        // Contract date
                        _buildDateField(
                          label: l10n?.dateOfContract ?? 'Shartnoma sanasi',
                          value: _contractDate,
                          onChanged: (date) => setState(() => _contractDate = date),
                          icon: Icons.calendar_today,
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Contract sum - collapsible
                        _buildCollapsibleSumField(theme, colorScheme, l10n),
                        
                        const SizedBox(height: 24),
                        
                        // Divider with label
                        _buildSectionDivider(l10n?.documentInfoSection ?? 'Document information', colorScheme),
                        
                        const SizedBox(height: 16),
                        
                        // Reference document fields
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _numbReferenceController,
                                label: l10n?.referenceNumberField ?? 'Reference number',
                                hint: AppLocalizations.of(context)?.enterNumberHint ?? 'Raqamni kiriting',
                                icon: Icons.description_outlined,
                                theme: theme,
                                colorScheme: colorScheme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                label: l10n?.termLabel ?? 'Term',
                                value: _termReference,
                                onChanged: (date) => setState(() => _termReference = date),
                                icon: Icons.event,
                                isOptional: true,
                                theme: theme,
                                colorScheme: colorScheme,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Certificate fields
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _numbCertificateController,
                                label: l10n?.certificateNumberField ?? 'Certificate number',
                                hint: AppLocalizations.of(context)?.enterNumberHint ?? 'Raqamni kiriting',
                                icon: Icons.verified_outlined,
                                theme: theme,
                                colorScheme: colorScheme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                label: l10n?.termLabel ?? 'Term',
                                value: _termCertificate,
                                onChanged: (date) => setState(() => _termCertificate = date),
                                icon: Icons.event,
                                isOptional: true,
                                enabled: !_certificateUnlimited,
                                theme: theme,
                                colorScheme: colorScheme,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Certificate unlimited checkbox
                        _buildCheckbox(
                          value: _certificateUnlimited,
                          label: l10n?.certificateUnlimitedField ?? 'Certificate unlimited',
                          onChanged: (value) => setState(() => _certificateUnlimited = value ?? false),
                          colorScheme: colorScheme,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Passport fields
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _numbPassportController,
                                label: l10n?.passportNumberField ?? 'Passport number',
                                hint: 'AA1234567',
                                icon: Icons.badge_outlined,
                                theme: theme,
                                colorScheme: colorScheme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                label: l10n?.termLabel ?? 'Term',
                                value: _termPassport,
                                onChanged: (date) => setState(() => _termPassport = date),
                                icon: Icons.event,
                                isOptional: true,
                                theme: theme,
                                colorScheme: colorScheme,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Divider with label
                        _buildSectionDivider(l10n?.regionInfoSection ?? 'Region information', colorScheme),
                        
                        const SizedBox(height: 16),
                        
                        // District contracting dropdown (NameDistrict va CodeDistrict)
                        _buildDistrictContractingSelector(theme, colorScheme),
                        
                        const SizedBox(height: 32),
                        
                        // Submit button
                        _buildSubmitButton(colorScheme),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build form header with title and close button
  Widget _buildHeader(ThemeData theme, ColorScheme colorScheme, AppLocalizations? l10n) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.add_circle_outline,
              color: colorScheme.onPrimaryContainer,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.newContractTitle ?? 'New contract',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.fillAllFields ?? 'Fill in all fields',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(
              Icons.close,
              color: colorScheme.onSurfaceVariant,
            ),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  /// Build error banner
  Widget _buildErrorBanner(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _errorMessage = null),
            icon: Icon(Icons.close, color: colorScheme.onErrorContainer, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Open searchable client selection dialog
  Future<void> _openClientSelector() async {
    // Don't open if pre-selected
    if (widget.preSelectedClientCode != null) return;

    final selected = await SearchableClientDialog.show(
      context: context,
      clients: widget.availableClients,
      selectedClient: _selectedClient,
      title: AppLocalizations.of(context)?.selectClientTitle,
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedClient = selected;
      });
    }
  }

  /// Build client selector with search capability
  Widget _buildClientSelector(ThemeData theme, ColorScheme colorScheme, AppLocalizations? l10n) {
    final isDisabled = widget.preSelectedClientCode != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.clientName ?? 'Mijoz',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: isDisabled ? null : _openClientSelector,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedClient == null && !isDisabled
                    ? colorScheme.error.withValues(alpha: 0.5)
                    : colorScheme.outline.withValues(alpha: 0.5),
              ),
              color: isDisabled ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5) : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.business,
                  color: isDisabled ? colorScheme.onSurfaceVariant : colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _selectedClient != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedClient!.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Kod: ${_selectedClient!.id}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (_selectedClient!.inn.isNotEmpty) ...[
                                  Flexible(
                                    child: Text(
                                      ' • INN: ${_selectedClient!.inn}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        )
                      : Text(
                          'Mijozni tanlang (qidirish mavjud)',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
                if (!isDisabled) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.search,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.preSelectedClientCode != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Avtomatik to\'ldirilgan',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        if (_selectedClient == null && !isDisabled)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Qidirish: nom, kod, INN, telefon, tur, region...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build district contracting selector dropdown
  Widget _buildDistrictContractingSelector(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shahar/Tuman',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // District dropdown
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
                ),
                child: _districtContracting.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.location_city, size: 20, color: colorScheme.onSurfaceVariant),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Shahar/Tuman yuklanmoqda...',
                                style: TextStyle(color: colorScheme.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<DistrictContracting>(
                        value: _selectedDistrict,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.location_city, color: colorScheme.primary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          hintText: 'Shahar/Tumanni tanlang',
                        ),
                        items: _districtContracting.map((district) {
                          return DropdownMenuItem<DistrictContracting>(
                            value: district,
                            child: Text(
                              district.nameDistrict,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDistrict = value;
                          });
                        },
                        isExpanded: true,
                        icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurfaceVariant),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            // District code (auto-filled, read-only display)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: colorScheme.surfaceContainerHighest,
                  border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.tag, size: 18, color: colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedDistrict?.codeDistrict ?? 'Kod',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _selectedDistrict != null 
                              ? colorScheme.onSurface 
                              : colorScheme.onSurfaceVariant,
                          fontWeight: _selectedDistrict != null 
                              ? FontWeight.w600 
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (_selectedDistrict != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Kod avtomatik to\'ldirildi',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.primary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  /// Build collapsible sum field
  Widget _buildCollapsibleSumField(ThemeData theme, ColorScheme colorScheme, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isSumFieldExpanded = !_isSumFieldExpanded),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
              color: _isSumFieldExpanded ? colorScheme.surfaceContainerHighest : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.payments_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isSumFieldExpanded
                        ? (l10n?.contractSum ?? 'Shartnoma summasi')
                        : (_sumController.text.isEmpty
                            ? (l10n?.contractSum ?? 'Shartnoma summasi')
                            : '${l10n?.contractSum ?? 'Shartnoma summasi'}: ${_sumController.text}'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: _isSumFieldExpanded ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                      fontWeight: _isSumFieldExpanded ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  _isSumFieldExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isSumFieldExpanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextFormField(
                    controller: _sumController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsSeparatorFormatter(),
                    ],
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: '0',
                      prefixIcon: Icon(Icons.attach_money, color: colorScheme.primary, size: 20),
                      suffixIcon: _sumController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, size: 20),
                              onPressed: () => setState(() => _sumController.clear()),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.error),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.error, width: 2),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Build contract type selector dropdown
  Widget _buildContractTypeSelector(ThemeData theme, ColorScheme colorScheme, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n?.typeOfContract ?? 'Shartnoma turi',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: _isLoadingTypes ? null : () async {
                await _loadContractTypes(forceRefresh: true);
                await _loadDistrictContracting(forceRefresh: true);
              },
              icon: Icon(
                Icons.refresh,
                color: _isLoadingTypes ? colorScheme.onSurfaceVariant : colorScheme.primary,
              ),
              tooltip: AppLocalizations.of(context)?.refreshContractTypesAndRegions ?? 'Refresh contract types and regions',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
          ),
          child: _isLoadingTypes
              ? Container(
                  padding: const EdgeInsets.all(16),
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
                        AppLocalizations.of(context)?.loading ?? 'Loading...',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _contractTypes.any((type) => type.name == _selectedContractType) 
                      ? _selectedContractType 
                      : null,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined, color: colorScheme.primary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: AppLocalizations.of(context)?.selectContractType ?? 'Select contract type',
                  ),
                  items: _contractTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type.name,
                      child: Text(
                        type.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedContractType = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.of(context)?.selectContractType ?? 'Select contract type';
                    }
                    return null;
                  },
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurfaceVariant),
                ),
        ),
        if (_contractTypes.isEmpty && !_isLoadingTypes)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.warning_amber, size: 14, color: colorScheme.error),
                const SizedBox(width: 4),
                Text(
                  AppLocalizations.of(context)?.contractTypesNotFound ?? 'Contract types not found',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _loadContractTypes,
                  child: Text(AppLocalizations.of(context)?.reloadLabel ?? 'Reload'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build text field with icon
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: colorScheme.primary, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  /// Build date field with picker
  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required Function(DateTime) onChanged,
    required IconData icon,
    required ThemeData theme,
    required ColorScheme colorScheme,
    bool isOptional = false,
    bool enabled = true,
  }) {
    final dateFormat = DateFormat('dd.MM.yyyy');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: enabled ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.5),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: enabled
              ? () async {
                  final date = await _pickDate(
                    initialDate: value,
                    helpText: label,
                  );
                  if (date != null) {
                    onChanged(date);
                  }
                }
              : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: enabled
                    ? colorScheme.outline.withValues(alpha: 0.5)
                    : colorScheme.outline.withValues(alpha: 0.2),
              ),
              color: enabled ? null : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: enabled ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    value != null ? dateFormat.format(value) : (isOptional ? 'Tanlanmagan' : 'Tanlang'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: value != null
                          ? (enabled ? colorScheme.onSurface : colorScheme.onSurface.withValues(alpha: 0.5))
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: enabled ? colorScheme.onSurfaceVariant : colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build checkbox
  Widget _buildCheckbox({
    required bool value,
    required String label,
    required Function(bool?) onChanged,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: value ? colorScheme.primary : colorScheme.outline,
                  width: 2,
                ),
                color: value ? colorScheme.primary : Colors.transparent,
              ),
              child: value
                  ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build section divider with label
  Widget _buildSectionDivider(String label, ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: colorScheme.outlineVariant),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: colorScheme.outlineVariant),
        ),
      ],
    );
  }

  /// Build submit button
  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitForm,
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: _isSubmitting ? 0 : 2,
            ),
            child: _isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Yaratilmoqda...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        AppLocalizations.of(context)?.createContract ?? 'Create contract',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _showXmlRequestDialog,
              icon: const Icon(Icons.code, size: 20),
              label: Text(AppLocalizations.of(context)?.xmlRequestLabel ?? 'XML Request'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Formatter for thousands separator in number input
class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final number = int.tryParse(newValue.text.replaceAll(' ', ''));
    if (number == null) {
      return oldValue;
    }

    final formatter = NumberFormat('#,###', 'en_US');
    final newText = formatter.format(number).replaceAll(',', ' ');

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
