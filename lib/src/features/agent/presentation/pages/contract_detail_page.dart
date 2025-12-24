import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_contract.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/repositories/agent_repository.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/widgets/contract_templates.dart';
import 'package:gloria_marketing_flutter/src/features/agent/presentation/services/contract_pdf_service.dart';
import 'package:gloria_marketing_flutter/src/core/services/api_database_service.dart';

String formatNumber(num number) {
  final formatter = NumberFormat('#,###', 'en_US');
  return formatter.format(number).replaceAll(',', ' ');
}

enum ContractLanguage { uzbek, russian }

class ContractDetailPage extends StatefulWidget {
  final ClientContractWithName contract;
  const ContractDetailPage({super.key, required this.contract});
  @override
  State<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends State<ContractDetailPage> with TickerProviderStateMixin {
  late TabController _tabController;
  TradingPoint? _clientData;
  bool _isLoadingClient = true;
  ContractLanguage _selectedLanguage = ContractLanguage.uzbek;
  String? _organizationName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadClientData();
  }

  Future<void> _loadClientData() async {
    try {
      await sl.isReady<SharedPreferencesService>();
      final prefs = sl<SharedPreferencesService>();
      final userCode = prefs.getUserCode();
      if (userCode == null || userCode.isEmpty) {
        setState(() => _isLoadingClient = false);
        return;
      }
      final repository = sl<AgentRepository>();
      final clients = await repository.getClients(userCode: userCode, password: prefs.getPassword() ?? '', forceRefresh: false);
      final client = clients.where((c) => c.id == widget.contract.codeClient).firstOrNull;
      
      // Load organization name from user_organization table
      String? orgName;
      try {
        final dbService = sl<ApiDatabaseService>();
        final organizations = await dbService.getUserOrganizations(userCode);
        if (organizations.isNotEmpty) {
          orgName = organizations.first.name;
        }
      } catch (e) {
        if (kDebugMode) print('Error loading organization: $e');
      }
      
      setState(() { _clientData = client; _organizationName = orgName; _isLoadingClient = false; });
    } catch (e) {
      if (kDebugMode) print('Error loading client data: $e');
      setState(() => _isLoadingClient = false);
    }
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Shartnoma tafsilotlari', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).pop()),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Ma\'lumotlar'), Tab(text: 'Hujjat')]),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [colorScheme.primary.withValues(alpha: 0.08), colorScheme.primaryContainer.withValues(alpha: 0.06)])),
        child: TabBarView(controller: _tabController, children: [_buildDetailsTab(context), _buildDocumentTab(context)]),
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final contract = widget.contract;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), color: colorScheme.surface,
          child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(contract.codeContract, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, color: colorScheme.primary))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: contract.active ? colorScheme.primaryContainer : colorScheme.errorContainer, borderRadius: BorderRadius.circular(20)),
                child: Text(contract.active ? 'Faol' : 'Faol emas', style: theme.textTheme.bodySmall?.copyWith(color: contract.active ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 8),
            Text('Mijoz: ${contract.clientName ?? contract.codeClient}', style: theme.textTheme.titleMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildDetailItem(context, 'Boshlanish sanasi', contract.dateOfContract != null ? DateFormat('dd.MM.yyyy').format(contract.dateOfContract!) : 'Noma\'lum', Icons.calendar_today)),
              const SizedBox(width: 16),
              Expanded(child: _buildDetailItem(context, 'Tugash sanasi', contract.termOfContract != null ? DateFormat('dd.MM.yyyy').format(contract.termOfContract!) : 'Noma\'lum', Icons.event_busy)),
            ]),
            const SizedBox(height: 16),
            _buildDetailItem(context, 'Shartnoma summasi', '${formatNumber(contract.sumOfContract)} UZS', Icons.account_balance_wallet, isLarge: true),
          ]))),
        const SizedBox(height: 16),
        Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), color: colorScheme.surface,
          child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Status va turi', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: _buildStatusChip(context, 'Status', contract.status, _getStatusColor(contract.status, colorScheme))),
              const SizedBox(width: 16),
              Expanded(child: _buildStatusChip(context, 'Turi', contract.typeContract?.isNotEmpty == true ? contract.typeContract! : 'Noma\'lum', colorScheme.secondaryContainer)),
            ]),
          ]))),
        const SizedBox(height: 16),
        Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), color: colorScheme.surface,
          child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Qo\'shimcha ma\'lumotlar', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
            const SizedBox(height: 16),
            _buildDetailRow(context, 'Sertifikat cheklangan', contract.certificateUnlimited == 1 ? 'Ha' : 'Yo\'q'),
            if (contract.numbReference?.isNotEmpty == true) _buildDetailRow(context, 'Reference raqami', contract.numbReference!),
            if (contract.numbCertificate?.isNotEmpty == true) _buildDetailRow(context, 'Sertifikat raqami', contract.numbCertificate!),
            if (contract.numbPassport?.isNotEmpty == true) _buildDetailRow(context, 'Passport raqami', contract.numbPassport!),
            if (contract.codeDistrict?.isNotEmpty == true) _buildDetailRow(context, 'Tuman kodi', contract.codeDistrict!),
            if (contract.nameDistrict?.isNotEmpty == true) _buildDetailRow(context, 'Tuman nomi', contract.nameDistrict!),
            if (contract.codeProject?.isNotEmpty == true) _buildDetailRow(context, 'Loyiha kodi', contract.codeProject!),
          ]))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tahrirlash funksiyasi tez orada qo\'shiladi'))), icon: const Icon(Icons.edit), label: const Text('Tahrirlash'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
      ]),
    );
  }

  Widget _buildDocumentTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final contract = widget.contract;
    final bool isCreditContract = _isCreditContract(contract.typeContract);
    final String creditPercent = _extractCreditPercent(contract.typeContract);
    if (_isLoadingClient) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), color: colorScheme.surface,
          child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(Icons.description, color: colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text('Shartnoma hujjati', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface))),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isCreditContract ? colorScheme.tertiaryContainer : colorScheme.primaryContainer, borderRadius: BorderRadius.circular(8)),
                child: Text(isCreditContract ? 'Kredit' : '100% to\'lov', style: theme.textTheme.labelSmall?.copyWith(color: isCreditContract ? colorScheme.onTertiaryContainer : colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600))),
            ]),
            const SizedBox(height: 16),
            // Language toggle
            Container(decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(child: GestureDetector(onTap: () => setState(() => _selectedLanguage = ContractLanguage.uzbek),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _selectedLanguage == ContractLanguage.uzbek ? colorScheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🇺🇿', style: TextStyle(fontSize: 18)), const SizedBox(width: 8), Text('O\'zbekcha', style: theme.textTheme.labelLarge?.copyWith(color: _selectedLanguage == ContractLanguage.uzbek ? colorScheme.onPrimary : colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600))])))),
                Expanded(child: GestureDetector(onTap: () => setState(() => _selectedLanguage = ContractLanguage.russian),
                  child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: _selectedLanguage == ContractLanguage.russian ? colorScheme.primary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Text('🇷🇺', style: TextStyle(fontSize: 18)), const SizedBox(width: 8), Text('Русский', style: theme.textTheme.labelLarge?.copyWith(color: _selectedLanguage == ContractLanguage.russian ? colorScheme.onPrimary : colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600))])))),
              ])),
            const SizedBox(height: 16),
            Container(width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(border: Border.all(color: colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12), color: Colors.white),
              child: _selectedLanguage == ContractLanguage.uzbek 
                ? ContractTemplates.buildUzbekContract(theme: theme, contract: contract, isCreditContract: isCreditContract, creditPercent: creditPercent, clientData: _clientData, organizationName: _organizationName)
                : ContractTemplates.buildRussianContract(theme: theme, contract: contract, isCreditContract: isCreditContract, creditPercent: creditPercent, clientData: _clientData, organizationName: _organizationName)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () async {
                  try {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF tayyorlanmoqda...')));
                    await ContractPdfService.generateAndSharePdf(
                      contract: contract,
                      language: _selectedLanguage == ContractLanguage.uzbek ? ContractPdfLanguage.uzbek : ContractPdfLanguage.russian,
                      clientData: _clientData,
                      organizationName: _organizationName,
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Xatolik: $e')));
                    }
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('PDF yuborish'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
              )),
              const SizedBox(width: 12),
              Expanded(child: OutlinedButton.icon(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Print funksiyasi tez orada qo\'shiladi'))), icon: const Icon(Icons.print), label: const Text('Print'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)))),
            ]),
          ]))),
      ]),
    );
  }

  bool _isCreditContract(String? t) => t != null && t.isNotEmpty && (t.toLowerCase().contains('кредит') || t.toLowerCase().contains('kredit') || t.toLowerCase().contains('рассрочк') || (!t.toLowerCase().contains('100%') && !t.toLowerCase().contains('предоплат')));
  String _extractCreditPercent(String? t) { if (t == null) return '30'; final m = RegExp(r'(\d+)\s*%').firstMatch(t); return m?.group(1) ?? '30'; }

  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon, {bool isLarge = false}) {
    final theme = Theme.of(context); final colorScheme = theme.colorScheme;
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(icon, size: 16, color: colorScheme.onSurfaceVariant), const SizedBox(width: 8), Expanded(child: Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1))]),
        const SizedBox(height: 4),
        Text(value, style: (isLarge ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
      ]));
  }

  Widget _buildStatusChip(BuildContext context, String label, String value, Color backgroundColor) {
    final theme = Theme.of(context); final colorScheme = theme.colorScheme;
    return Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
      ]));
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context); final colorScheme = theme.colorScheme;
    return Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 140, child: Text('$label:', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500))),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w600))),
    ]));
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) { case 'Действует': return colorScheme.primaryContainer; case 'Истек': return colorScheme.errorContainer; case 'Не согласован': return colorScheme.secondaryContainer; default: return colorScheme.surfaceContainerHighest; }
  }
}
