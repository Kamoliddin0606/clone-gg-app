import 'package:flutter/material.dart';
import 'package:gloria_marketing_flutter/l10n/app_localizations.dart';
import 'package:gloria_marketing_flutter/src/Utility/formatter.dart';
import 'package:gloria_marketing_flutter/src/features/agent/data/models/trading_point.dart';

/// Searchable client selection dialog with multi-parameter search
/// Supports both Cyrillic and Latin script search
class SearchableClientDialog extends StatefulWidget {
  final List<TradingPoint> clients;
  final TradingPoint? selectedClient;
  final String? title;

  const SearchableClientDialog({
    super.key,
    required this.clients,
    this.selectedClient,
    this.title,
  });

  /// Show the dialog and return selected client
  static Future<TradingPoint?> show({
    required BuildContext context,
    required List<TradingPoint> clients,
    TradingPoint? selectedClient,
    String? title,
  }) {
    return showModalBottomSheet<TradingPoint>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchableClientDialog(
        clients: clients,
        selectedClient: selectedClient,
        title: title,
      ),
    );
  }

  @override
  State<SearchableClientDialog> createState() => _SearchableClientDialogState();
}

class _SearchableClientDialogState extends State<SearchableClientDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<TradingPoint> _filteredClients = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredClients = widget.clients;
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Filter clients based on search query
  /// Searches across multiple fields with Cyrillic/Latin transliteration support
  void _filterClients(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredClients = widget.clients;
      } else {
        _filteredClients = widget.clients.where((client) {
          // Search across all relevant fields
          return _matchesClient(client, query);
        }).toList();
      }
    });
  }

  /// Check if client matches the search query
  /// Searches: region, name, id (code), inn, phone numbers, type, signboard, referencePoint
  bool _matchesClient(TradingPoint client, String query) {
    // Build searchable text from all relevant fields
    final searchableFields = [
      client.region,           // biznes regioni
      client.name,             // nomi
      client.id,               // kodi
      client.inn,              // inn raqami
      client.phone,            // aloqa raqami
      client.responsiblePersonPhone, // javobgar shaxs telefoni
      client.tradePointType,   // turi
      client.signboard,        // belgisi
      client.referencePoint,   // mo'ljali
      client.address,          // manzil (bonus)
      client.ownerName,        // egasi nomi (bonus)
      client.contactPerson,    // aloqa shaxsi (bonus)
      client.district,         // tuman (bonus)
    ];

    // Check if any field matches the query
    for (final field in searchableFields) {
      if (field.isNotEmpty && matchesSearch(field, query)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
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
          Padding(
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
                    Icons.person_search,
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
                        widget.title ?? AppLocalizations.of(context)?.selectClientTitle ?? 'Select client',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)?.clientsAvailable(widget.clients.length) ?? '${widget.clients.length} clients available',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                  style: IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _filterClients,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)?.searchByNameCodeInn ?? 'Name, code, INN, phone, type...',
                prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterClients('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                filled: true,
                fillColor: colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colorScheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),

          // Search info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 14,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)?.searchInCyrillicOrLatin ?? 'Search in Cyrillic or Latin',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                if (_searchQuery.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context)?.foundCount(_filteredClients.length) ?? '${_filteredClients.length} found',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          const Divider(height: 1),

          // Client list
          Expanded(
            child: _filteredClients.isEmpty
                ? _buildEmptyState(colorScheme, theme)
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: bottomPadding + 16),
                    itemCount: _filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = _filteredClients[index];
                      final isSelected = widget.selectedClient?.id == client.id;
                      return _buildClientTile(client, isSelected, colorScheme, theme);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Build empty state when no clients match
  Widget _buildEmptyState(ColorScheme colorScheme, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.clientNotFound ?? 'Client not found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.tryDifferentSearch ?? 'Try a different search term',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Build client list tile
  Widget _buildClientTile(
    TradingPoint client,
    bool isSelected,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: () => Navigator.pop(context, client),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: colorScheme.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            // Client avatar/icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Client info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    client.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),

                  // Code and INN
                  Row(
                    children: [
                      _buildInfoChip(
                        Icons.tag,
                        client.id,
                        colorScheme,
                        theme,
                      ),
                      if (client.inn.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          Icons.badge_outlined,
                          'INN: ${client.inn}',
                          colorScheme,
                          theme,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Type and Region
                  Row(
                    children: [
                      if (client.tradePointType.isNotEmpty)
                        Flexible(
                          child: Text(
                            client.tradePointType,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (client.tradePointType.isNotEmpty && client.region.isNotEmpty)
                        Text(
                          ' • ',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      if (client.region.isNotEmpty)
                        Flexible(
                          child: Text(
                            client.region,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),

                  // Phone if available
                  if (client.phone.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          client.phone,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Selection indicator
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  /// Build small info chip
  Widget _buildInfoChip(
    IconData icon,
    String text,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
