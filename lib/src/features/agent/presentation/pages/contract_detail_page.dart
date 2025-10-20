import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_contract.dart';
// import 'package:gloria_marketing_flutter/src/features/agent/data/models/client_contract_with_name.dart';
import '../../../../Utility/formatter.dart';

/// Format number with spaces as thousand separators
String formatNumber(num number) {
  final formatter = NumberFormat('#,###', 'en_US');
  return formatter.format(number).replaceAll(',', ' ');
}

class ContractDetailPage extends StatefulWidget {
  final ClientContractWithName contract;

  const ContractDetailPage({
    super.key,
    required this.contract,
  });

  @override
  State<ContractDetailPage> createState() => _ContractDetailPageState();
}

class _ContractDetailPageState extends State<ContractDetailPage> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Shartnoma tafsilotlari', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Orqaga',
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Ma\'lumotlar'),
            Tab(text: 'Hujjat'),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withValues(alpha: 0.08),
              colorScheme.primaryContainer.withValues(alpha: 0.06),
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildDetailsTab(context),
            _buildDocumentTab(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final contract = widget.contract;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Contract header card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          contract.codeContract,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.primary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: contract.active ? colorScheme.primaryContainer : colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          contract.active ? 'Faol' : 'Faol emas',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: contract.active ? colorScheme.onPrimaryContainer : colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mijoz: ${contract.clientName ?? contract.codeClient}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          context,
                          'Boshlanish sanasi',
                          contract.dateOfContract != null
                              ? DateFormat('dd.MM.yyyy').format(contract.dateOfContract!)
                              : 'Noma\'lum',
                          Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailItem(
                          context,
                          'Tugash sanasi',
                          contract.termOfContract != null
                              ? DateFormat('dd.MM.yyyy').format(contract.termOfContract!)
                              : 'Noma\'lum',
                          Icons.event_busy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailItem(
                    context,
                    'Shartnoma summasi',
                    '${formatNumber(contract.sumOfContract)} UZS',
                    Icons.account_balance_wallet,
                    isLarge: true,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Status and type card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status va turi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusChip(
                          context,
                          'Status',
                          contract.status,
                          _getStatusColor(contract.status, colorScheme),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatusChip(
                          context,
                          'Turi',
                          contract.typeContract?.isNotEmpty == true ? contract.typeContract! : 'Noma\'lum',
                          colorScheme.secondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Additional details card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Qoshimcha ma\'lumotlar',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(context, 'Sertifikat cheklangan', contract.certificateUnlimited == 1 ? 'Ha' : 'Yo\'q'),
                  if (contract.numbReference?.isNotEmpty == true)
                    _buildDetailRow(context, 'Reference raqami', contract.numbReference!),
                  if (contract.numbCertificate?.isNotEmpty == true)
                    _buildDetailRow(context, 'Sertifikat raqami', contract.numbCertificate!),
                  if (contract.numbPassport?.isNotEmpty == true)
                    _buildDetailRow(context, 'Passport raqami', contract.numbPassport!),
                  if (contract.codeDistrict?.isNotEmpty == true)
                    _buildDetailRow(context, 'Tuman kodi', contract.codeDistrict!),
                  if (contract.nameDistrict?.isNotEmpty == true)
                    _buildDetailRow(context, 'Tuman nomi', contract.nameDistrict!),
                  if (contract.codeProject?.isNotEmpty == true)
                    _buildDetailRow(context, 'Loyiha kodi', contract.codeProject!),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Edit button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                // TODO: Implement edit functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tahrirlash funksiyasi tez orada qo\'shiladi')),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Tahrirlash'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final contract = widget.contract;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.description, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Shartnoma hujjati',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(color: colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(12),
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'SHARTNOMA',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Raqami: ${contract.codeContract}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildDocumentSection('Tomorqalar', [
                          'Shartnoma raqami: ${contract.codeContract}',
                          'Mijoz: ${contract.clientName ?? contract.codeClient}',
                          'Boshlanish sanasi: ${contract.dateOfContract != null ? DateFormat('dd.MM.yyyy').format(contract.dateOfContract!) : 'Noma\'lum'}',
                          'Tugash sanasi: ${contract.termOfContract != null ? DateFormat('dd.MM.yyyy').format(contract.termOfContract!) : 'Noma\'lum'}',
                          'Shartnoma summasi: ${formatNumber(contract.sumOfContract)} UZS',
                          'Status: ${contract.status}',
                          'Faolligi: ${contract.active ? 'Faol' : 'Faol emas'}',
                        ]),

                        const SizedBox(height: 16),

                        if (contract.typeContract?.isNotEmpty == true)
                          _buildDocumentSection('Shartnoma turi', [
                            contract.typeContract!,
                          ]),

                        const SizedBox(height: 16),

                        _buildDocumentSection('Qoshimcha shartlar', [
                          'Sertifikat cheklangan: ${contract.certificateUnlimited == 1 ? 'Ha' : 'Yo\'q'}',
                          if (contract.numbReference?.isNotEmpty == true) 'Reference raqami: ${contract.numbReference}',
                          if (contract.numbCertificate?.isNotEmpty == true) 'Sertifikat raqami: ${contract.numbCertificate}',
                          if (contract.numbPassport?.isNotEmpty == true) 'Passport raqami: ${contract.numbPassport}',
                          if (contract.codeDistrict?.isNotEmpty == true) 'Tuman kodi: ${contract.codeDistrict}',
                          if (contract.nameDistrict?.isNotEmpty == true) 'Tuman nomi: ${contract.nameDistrict}',
                          if (contract.codeProject?.isNotEmpty == true) 'Loyiha kodi: ${contract.codeProject}',
                        ].where((item) => item?.isNotEmpty == true).toList()),

                        const SizedBox(height: 32),

                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('____________________'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mijoz imzosi',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: Column(
                                children: [
                                  const Text('____________________'),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Kompaniya imzosi',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Center(
                          child: Text(
                            DateFormat('dd.MM.yyyy').format(DateTime.now()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement PDF export
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('PDF eksport tez orada qo\'shiladi')),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('PDF'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // TODO: Implement print functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Print funksiyasi tez orada qo\'shiladi')),
                            );
                          },
                          icon: const Icon(Icons.print),
                          label: const Text('Print'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon, {bool isLarge = false}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: (isLarge ? theme.textTheme.titleMedium : theme.textTheme.bodyLarge)?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String label, String value, Color backgroundColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentSection(String title, List<String> items) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            item,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        )),
      ],
    );
  }

  Color _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'Действует':
        return colorScheme.primaryContainer;
      case 'Истек':
        return colorScheme.errorContainer;
      case 'Не согласован':
        return colorScheme.secondaryContainer;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }
}