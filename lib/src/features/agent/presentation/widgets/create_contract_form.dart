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
  final _districtNameController = TextEditingController();
  final _districtCodeController = TextEditingController();
  
  // Form state
  TradingPoint? _selectedClient;
  String? _selectedContractType;
  DateTime _contractDate = DateTime.now();
  DateTime? _termReference;
  DateTime? _termCertificate;
  DateTime? _termPassport;
  bool _certificateUnlimited = false;
  
  // Data state
  List<ContractType> _contractTypes = [];
  bool _isLoadingTypes = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadContractTypes();
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
  Future<void> _loadContractTypes() async {
    try {
      setState(() {
        _isLoadingTypes = true;
        _errorMessage = null;
      });

      final dbService = sl<ApiDatabaseService>();
      
      // First try to get from cache
      var types = await dbService.getContractTypes();
      
      // If cache is empty, fetch from server
      if (types.isEmpty) {
        if (kDebugMode) {
          print('CreateContractForm: No cached contract types, fetching from server');
        }
        
        try {
          final soapService = sl<SoapApiService>();
          types = await soapService.getTypeOfContract();
          
          // Save to cache
          if (types.isNotEmpty) {
            await dbService.saveContractTypes(types);
          }
        } catch (e) {
          if (kDebugMode) {
            print('CreateContractForm: Error fetching contract types from server: $e');
          }
          // Continue with empty types - user can still fill other fields
        }
      }

      setState(() {
        _contractTypes = types;
        _isLoadingTypes = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('CreateContractForm: Error loading contract types: $e');
      }
      setState(() {
        _isLoadingTypes = false;
        _errorMessage = 'Shartnoma turlarini yuklashda xatolik';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sumController.dispose();
    _numbReferenceController.dispose();
    _numbCertificateController.dispose();
    _numbPassportController.dispose();
    _districtNameController.dispose();
    _districtCodeController.dispose();
    super.dispose();
  }

  /// Submit the contract creation form
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedClient == null) {
      _showError('Iltimos, mijozni tanlang');
      return;
    }

    if (_selectedContractType == null) {
      _showError('Iltimos, shartnoma turini tanlang');
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
      
      final result = await soapService.setContract(
        dateOfContract: dateFormat.format(_contractDate),
        codeUser: userCode,
        codeClient: _selectedClient!.id,
        sumOfContract: double.tryParse(_sumController.text.replaceAll(' ', '')) ?? 0.0,
        termReference: _termReference != null ? dateFormat.format(_termReference!) : null,
        termCertificate: _termCertificate != null ? dateFormat.format(_termCertificate!) : null,
        numbReference: _numbReferenceController.text.isEmpty ? null : _numbReferenceController.text,
        numbCertificate: _numbCertificateController.text.isEmpty ? null : _numbCertificateController.text,
        typeOfContract: _selectedContractType!,
        numbPassport: _numbPassportController.text.isEmpty ? null : _numbPassportController.text,
        termPassport: _termPassport != null ? dateFormat.format(_termPassport!) : null,
        certificateUnlimited: _certificateUnlimited,
        psCodeProject: codeProject,
        psCodeDistrict: _districtCodeController.text.isEmpty ? null : _districtCodeController.text,
        psNameDistrict: _districtNameController.text.isEmpty ? null : _districtNameController.text,
      );

      if (result['success'] == true) {
        if (mounted) {
          _showSuccess(result['message'] ?? 'Shartnoma muvaffaqiyatli yaratildi');
          widget.onContractCreated?.call();
        }
      } else {
        _showError(result['message'] ?? 'Shartnoma yaratishda xatolik');
      }
    } catch (e) {
      if (kDebugMode) {
        print('CreateContractForm: Error creating contract: $e');
      }
      _showError('Shartnoma yaratishda xatolik: $e');
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
                        
                        // Contract sum
                        _buildTextField(
                          controller: _sumController,
                          label: l10n?.contractSum ?? 'Shartnoma summasi',
                          hint: '0',
                          icon: Icons.payments_outlined,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _ThousandsSeparatorFormatter(),
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Summani kiriting';
                            }
                            return null;
                          },
                          theme: theme,
                          colorScheme: colorScheme,
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Divider with label
                        _buildSectionDivider('Hujjatlar ma\'lumotlari', colorScheme),
                        
                        const SizedBox(height: 16),
                        
                        // Reference document fields
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _numbReferenceController,
                                label: 'Ma\'lumotnoma raqami',
                                hint: 'Raqamni kiriting',
                                icon: Icons.description_outlined,
                                theme: theme,
                                colorScheme: colorScheme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                label: 'Muddati',
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
                                label: 'Sertifikat raqami',
                                hint: 'Raqamni kiriting',
                                icon: Icons.verified_outlined,
                                theme: theme,
                                colorScheme: colorScheme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                label: 'Muddati',
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
                          label: 'Sertifikat muddatsiz',
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
                                label: 'Pasport raqami',
                                hint: 'AA1234567',
                                icon: Icons.badge_outlined,
                                theme: theme,
                                colorScheme: colorScheme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildDateField(
                                label: 'Muddati',
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
                        _buildSectionDivider('Hudud ma\'lumotlari', colorScheme),
                        
                        const SizedBox(height: 16),
                        
                        // District fields
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField(
                                controller: _districtNameController,
                                label: 'Tuman nomi',
                                hint: 'Tuman nomini kiriting',
                                icon: Icons.location_on_outlined,
                                theme: theme,
                                colorScheme: colorScheme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _districtCodeController,
                                label: 'Tuman kodi',
                                hint: 'Kod',
                                icon: Icons.tag,
                                theme: theme,
                                colorScheme: colorScheme,
                              ),
                            ),
                          ],
                        ),
                        
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
                  'Yangi shartnoma',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Barcha maydonlarni to\'ldiring',
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

  /// Build client selector dropdown
  Widget _buildClientSelector(ThemeData theme, ColorScheme colorScheme, AppLocalizations? l10n) {
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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withValues(alpha: 0.5)),
          ),
          child: DropdownButtonFormField<TradingPoint>(
            value: _selectedClient,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.business, color: colorScheme.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Mijozni tanlang',
            ),
            items: widget.availableClients.map((client) {
              return DropdownMenuItem<TradingPoint>(
                value: client,
                child: Text(
                  client.name,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: widget.preSelectedClientCode != null
                ? null // Disable if pre-selected
                : (value) => setState(() => _selectedClient = value),
            validator: (value) {
              if (value == null) {
                return 'Mijozni tanlang';
              }
              return null;
            },
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurfaceVariant),
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
      ],
    );
  }

  /// Build contract type selector dropdown
  Widget _buildContractTypeSelector(ThemeData theme, ColorScheme colorScheme, AppLocalizations? l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.typeOfContract ?? 'Shartnoma turi',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
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
                        'Yuklanmoqda...',
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                )
              : DropdownButtonFormField<String>(
                  value: _selectedContractType,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined, color: colorScheme.primary),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    hintText: 'Shartnoma turini tanlang',
                  ),
                  items: _contractTypes.map((type) {
                    return DropdownMenuItem<String>(
                      value: type.code,
                      child: Text(
                        type.name.isNotEmpty ? type.name : type.code,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedContractType = value),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Shartnoma turini tanlang';
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
                  'Shartnoma turlari topilmadi',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _loadContractTypes,
                  child: const Text('Qayta yuklash'),
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
    return AnimatedContainer(
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
                  const Text(
                    'Shartnoma yaratish',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
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
