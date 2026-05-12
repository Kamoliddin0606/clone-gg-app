import 'package:flutter/material.dart';

import '../../../../../l10n/app_localizations.dart';
import '../../../../core/auth/permission_codenames.dart';

/// Display metadata for a single backend codename: a localised label,
/// a Material icon, and the namespace this codename belongs to. Pulled
/// out of the widgets so the data sync card and the permissions tab
/// stay in lock-step on labels / categories without duplicating
/// switch statements.
class BackendPermissionLabel {
  final String codename;
  final String title;
  final IconData icon;
  final BackendPermissionCategory category;

  const BackendPermissionLabel({
    required this.codename,
    required this.title,
    required this.icon,
    required this.category,
  });
}

/// Logical grouping of codenames in the UI. Maps roughly to the
/// backend's namespace prefix (`customers.add_customer*` vs
/// `customers.*_photo`). Kept small so future namespaces (e.g.
/// `users.*`) can be appended without churning the existing entries.
enum BackendPermissionCategory { customers, photos }

extension BackendPermissionCategoryLabel on BackendPermissionCategory {
  String localised(AppLocalizations l10n) {
    switch (this) {
      case BackendPermissionCategory.customers:
        return l10n.backendPermissions_categoryCustomers;
      case BackendPermissionCategory.photos:
        return l10n.backendPermissions_categoryPhotos;
    }
  }

  IconData get icon {
    switch (this) {
      case BackendPermissionCategory.customers:
        return Icons.person_outline;
      case BackendPermissionCategory.photos:
        return Icons.photo_library_outlined;
    }
  }
}

/// Resolve [BackendPermissionLabel] entries for every owned codename
/// in the order they should render. Caller picks the language at
/// build-time via [l10n] so no rebuilds are needed on locale change
/// other than the existing l10n machinery.
List<BackendPermissionLabel> resolveBackendPermissionLabels(
  AppLocalizations l10n,
) {
  return <BackendPermissionLabel>[
    BackendPermissionLabel(
      codename: PermissionCodenames.customerAdd,
      title: l10n.backendPermissions_label_customerAdd,
      icon: Icons.person_add_alt_1_outlined,
      category: BackendPermissionCategory.customers,
    ),
    BackendPermissionLabel(
      codename: PermissionCodenames.customerChange,
      title: l10n.backendPermissions_label_customerChange,
      icon: Icons.edit_outlined,
      category: BackendPermissionCategory.customers,
    ),
    BackendPermissionLabel(
      codename: PermissionCodenames.customerChangeCoordinates,
      title: l10n.backendPermissions_label_customerChangeCoordinates,
      icon: Icons.location_on_outlined,
      category: BackendPermissionCategory.customers,
    ),
    BackendPermissionLabel(
      codename: PermissionCodenames.customerAddPhoto,
      title: l10n.backendPermissions_label_customerAddPhoto,
      icon: Icons.add_a_photo_outlined,
      category: BackendPermissionCategory.photos,
    ),
    BackendPermissionLabel(
      codename: PermissionCodenames.customerChangePhoto,
      title: l10n.backendPermissions_label_customerChangePhoto,
      icon: Icons.tune_outlined,
      category: BackendPermissionCategory.photos,
    ),
    BackendPermissionLabel(
      codename: PermissionCodenames.customerReplacePhoto,
      title: l10n.backendPermissions_label_customerReplacePhoto,
      icon: Icons.cameraswitch_outlined,
      category: BackendPermissionCategory.photos,
    ),
    BackendPermissionLabel(
      codename: PermissionCodenames.customerDeletePhoto,
      title: l10n.backendPermissions_label_customerDeletePhoto,
      icon: Icons.delete_outline,
      category: BackendPermissionCategory.photos,
    ),
  ];
}
