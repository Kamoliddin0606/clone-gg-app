import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/core/database/database_helper.dart';
import 'package:gloria_marketing_flutter/src/core/services/service_locator.dart';
import 'package:gloria_marketing_flutter/src/core/services/shared_preferences_service.dart';
import '../../data/models/faq_section_model.dart';
import '../../data/repositories/faq_repository.dart';
import '../../domain/enums/employee_type.dart';
import '../widgets/faq_section_card.dart';

/// FAQ page displaying company regulations based on user role.
/// Shows different content for Supervisors and Sales Representatives.
class FaqPage extends StatefulWidget {
  const FaqPage({super.key});

  @override
  State<FaqPage> createState() => _FaqPageState();
}

class _FaqPageState extends State<FaqPage> {
  EmployeeType _employeeType = EmployeeType.salesRep;
  List<FaqSection> _sections = [];
  bool _isLoading = true;
  String? _expandedSectionId;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    setState(() => _isLoading = true);

    try {
      // Get user code from preferences
      final prefs = sl<SharedPreferencesService>();
      final userCode = prefs.getUserCode();

      if (userCode != null) {
        // Get user role from database
        final dbHelper = sl<DatabaseHelper>();
        final userData = await dbHelper.getUserByCode(userCode);
        final role = userData?['role'] as String?;

        setState(() {
          _employeeType = EmployeeType.fromRole(role);
          _sections = FaqRepository.getSectionsForType(_employeeType);
          _isLoading = false;
        });
      } else {
        // Default to sales rep if no user code
        setState(() {
          _employeeType = EmployeeType.salesRep;
          _sections = FaqRepository.getSectionsForType(_employeeType);
          _isLoading = false;
        });
      }
    } catch (e) {
      // Default to sales rep on error
      setState(() {
        _employeeType = EmployeeType.salesRep;
        _sections = FaqRepository.getSectionsForType(_employeeType);
        _isLoading = false;
      });
    }
  }

  void _onSectionExpanded(String sectionId, bool isExpanded) {
    setState(() {
      // Accordion behavior - only one section open at a time
      _expandedSectionId = isExpanded ? sectionId : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with gradient
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          l10n.faqPageTitle,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _employeeType.isSupervisor
                              ? l10n.faqSupervisorSubtitle
                              : l10n.faqSalesRepSubtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              title: Text(
                l10n.faqPageTitle,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: true,
            ),
          ),

          // Role indicator chip
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  _RoleChip(
                    label: _employeeType.isSupervisor
                        ? l10n.faqRoleSupervisor
                        : l10n.faqRoleSalesRep,
                    icon: _employeeType.isSupervisor
                        ? Icons.supervisor_account
                        : Icons.person,
                    color: _employeeType.isSupervisor
                        ? const Color(0xFF9C27B0)
                        : const Color(0xFF2196F3),
                  ),
                  const Spacer(),
                  Text(
                    '${_sections.length} ${l10n.faqSectionsCount}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Loading or content
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final section = _sections[index];
                    return FaqSectionCard(
                      section: section,
                      initiallyExpanded: _expandedSectionId == section.id,
                      onExpansionChanged: (isExpanded) {
                        _onSectionExpanded(section.id, isExpanded);
                      },
                    );
                  },
                  childCount: _sections.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Chip widget displaying the current user role
class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
