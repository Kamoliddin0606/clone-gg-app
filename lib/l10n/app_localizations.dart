import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Gloria Marketing'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome!'**
  String get welcome;

  /// No description provided for @enterCredentials.
  ///
  /// In en, this message translates to:
  /// **'Please enter your login credentials'**
  String get enterCredentials;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @orders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orders;

  /// No description provided for @tradingPoints.
  ///
  /// In en, this message translates to:
  /// **'Trading Points'**
  String get tradingPoints;

  /// No description provided for @tradingPointsFilter.
  ///
  /// In en, this message translates to:
  /// **'Trading Points'**
  String get tradingPointsFilter;

  /// No description provided for @warehouses.
  ///
  /// In en, this message translates to:
  /// **'Warehouses'**
  String get warehouses;

  /// No description provided for @contracts.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contracts;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get marketing;

  /// No description provided for @promotions.
  ///
  /// In en, this message translates to:
  /// **'Promotions'**
  String get promotions;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @totalSales.
  ///
  /// In en, this message translates to:
  /// **'Total Sales'**
  String get totalSales;

  /// No description provided for @activeAgents.
  ///
  /// In en, this message translates to:
  /// **'Active Agents'**
  String get activeAgents;

  /// No description provided for @orderCount.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get orderCount;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit the application?'**
  String get confirmLogout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @yes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get dateRange;

  /// No description provided for @allDates.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get allDates;

  /// No description provided for @clients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @quantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantity;

  /// No description provided for @price.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get price;

  /// No description provided for @sum.
  ///
  /// In en, this message translates to:
  /// **'Sum'**
  String get sum;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'UZS'**
  String get currency;

  /// No description provided for @orderDate.
  ///
  /// In en, this message translates to:
  /// **'Order Date'**
  String get orderDate;

  /// No description provided for @clientName.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get clientName;

  /// No description provided for @items.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @russian.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russian;

  /// No description provided for @uzbek.
  ///
  /// In en, this message translates to:
  /// **'Uzbek'**
  String get uzbek;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get settingsSaved;

  /// No description provided for @dataSync.
  ///
  /// In en, this message translates to:
  /// **'Data Synchronization'**
  String get dataSync;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get syncNow;

  /// No description provided for @lastSync.
  ///
  /// In en, this message translates to:
  /// **'Last sync'**
  String get lastSync;

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Synchronizing...'**
  String get syncing;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Synchronization completed'**
  String get syncComplete;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Synchronization error'**
  String get syncError;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternet;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline mode - cached data is displayed'**
  String get offlineMode;

  /// No description provided for @onlineMode.
  ///
  /// In en, this message translates to:
  /// **'Online mode'**
  String get onlineMode;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error'**
  String get serverError;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid username or password'**
  String get invalidCredentials;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired'**
  String get sessionExpired;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @fileNotFound.
  ///
  /// In en, this message translates to:
  /// **'File not found'**
  String get fileNotFound;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error occurred'**
  String get unknownError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get tryAgain;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @feedback.
  ///
  /// In en, this message translates to:
  /// **'Feedback'**
  String get feedback;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the app'**
  String get rateApp;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share the app'**
  String get shareApp;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @warehouseManagement.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Management'**
  String get warehouseManagement;

  /// No description provided for @packingDashboard.
  ///
  /// In en, this message translates to:
  /// **'Packing Dashboard'**
  String get packingDashboard;

  /// No description provided for @collectionDashboard.
  ///
  /// In en, this message translates to:
  /// **'Collection Dashboard'**
  String get collectionDashboard;

  /// No description provided for @bossDashboard.
  ///
  /// In en, this message translates to:
  /// **'Boss Dashboard'**
  String get bossDashboard;

  /// No description provided for @forwarderDashboard.
  ///
  /// In en, this message translates to:
  /// **'Forwarder Dashboard'**
  String get forwarderDashboard;

  /// No description provided for @agentDashboard.
  ///
  /// In en, this message translates to:
  /// **'Agent Dashboard'**
  String get agentDashboard;

  /// No description provided for @todayProductivity.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Productivity'**
  String get todayProductivity;

  /// No description provided for @ordersProcessed.
  ///
  /// In en, this message translates to:
  /// **'orders processed'**
  String get ordersProcessed;

  /// No description provided for @totalCollected.
  ///
  /// In en, this message translates to:
  /// **'Total Collected'**
  String get totalCollected;

  /// No description provided for @activeCollections.
  ///
  /// In en, this message translates to:
  /// **'Active Collections'**
  String get activeCollections;

  /// No description provided for @pendingCollections.
  ///
  /// In en, this message translates to:
  /// **'Pending Collections'**
  String get pendingCollections;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @inTransit.
  ///
  /// In en, this message translates to:
  /// **'In Transit'**
  String get inTransit;

  /// No description provided for @delivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get delivered;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @picking.
  ///
  /// In en, this message translates to:
  /// **'Picking'**
  String get picking;

  /// No description provided for @packed.
  ///
  /// In en, this message translates to:
  /// **'Packed'**
  String get packed;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @toPack.
  ///
  /// In en, this message translates to:
  /// **'To Pack'**
  String get toPack;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @lowStock.
  ///
  /// In en, this message translates to:
  /// **'Low Stock'**
  String get lowStock;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of Stock'**
  String get outOfStock;

  /// No description provided for @receiveGoods.
  ///
  /// In en, this message translates to:
  /// **'Receive Goods'**
  String get receiveGoods;

  /// No description provided for @issueGoods.
  ///
  /// In en, this message translates to:
  /// **'Issue Goods'**
  String get issueGoods;

  /// No description provided for @findItem.
  ///
  /// In en, this message translates to:
  /// **'Find Item'**
  String get findItem;

  /// No description provided for @scanBarcode.
  ///
  /// In en, this message translates to:
  /// **'Scan Barcode'**
  String get scanBarcode;

  /// No description provided for @warehouseCapacity.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Capacity'**
  String get warehouseCapacity;

  /// No description provided for @used.
  ///
  /// In en, this message translates to:
  /// **'used'**
  String get used;

  /// No description provided for @incoming.
  ///
  /// In en, this message translates to:
  /// **'Incoming'**
  String get incoming;

  /// No description provided for @outgoing.
  ///
  /// In en, this message translates to:
  /// **'Outgoing'**
  String get outgoing;

  /// No description provided for @supplier.
  ///
  /// In en, this message translates to:
  /// **'Supplier'**
  String get supplier;

  /// No description provided for @customer.
  ///
  /// In en, this message translates to:
  /// **'Customer'**
  String get customer;

  /// No description provided for @eta.
  ///
  /// In en, this message translates to:
  /// **'ETA'**
  String get eta;

  /// No description provided for @due.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get due;

  /// No description provided for @productDetails.
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetails;

  /// No description provided for @sku.
  ///
  /// In en, this message translates to:
  /// **'SKU'**
  String get sku;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @pcs.
  ///
  /// In en, this message translates to:
  /// **'pcs'**
  String get pcs;

  /// No description provided for @kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get kg;

  /// No description provided for @contractDetails.
  ///
  /// In en, this message translates to:
  /// **'Contract Details'**
  String get contractDetails;

  /// No description provided for @contractCode.
  ///
  /// In en, this message translates to:
  /// **'Contract Code'**
  String get contractCode;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @dateOfContract.
  ///
  /// In en, this message translates to:
  /// **'Date of Contract'**
  String get dateOfContract;

  /// No description provided for @termOfContract.
  ///
  /// In en, this message translates to:
  /// **'Term of Contract'**
  String get termOfContract;

  /// No description provided for @contractSum.
  ///
  /// In en, this message translates to:
  /// **'Contract Sum'**
  String get contractSum;

  /// No description provided for @typeOfContract.
  ///
  /// In en, this message translates to:
  /// **'Type of Contract'**
  String get typeOfContract;

  /// No description provided for @clientCode.
  ///
  /// In en, this message translates to:
  /// **'Client Code'**
  String get clientCode;

  /// No description provided for @organization.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// No description provided for @responsiblePerson.
  ///
  /// In en, this message translates to:
  /// **'Responsible Person'**
  String get responsiblePerson;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @inn.
  ///
  /// In en, this message translates to:
  /// **'INN'**
  String get inn;

  /// No description provided for @region.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get region;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @signboard.
  ///
  /// In en, this message translates to:
  /// **'Signboard'**
  String get signboard;

  /// No description provided for @referencePoint.
  ///
  /// In en, this message translates to:
  /// **'Reference Point'**
  String get referencePoint;

  /// No description provided for @tradePointType.
  ///
  /// In en, this message translates to:
  /// **'Trade Point Type'**
  String get tradePointType;

  /// No description provided for @ownerName.
  ///
  /// In en, this message translates to:
  /// **'Owner Name'**
  String get ownerName;

  /// No description provided for @responsiblePersonPhone.
  ///
  /// In en, this message translates to:
  /// **'Responsible Person Phone'**
  String get responsiblePersonPhone;

  /// No description provided for @visit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get visit;

  /// No description provided for @visitClient.
  ///
  /// In en, this message translates to:
  /// **'Visit Client'**
  String get visitClient;

  /// No description provided for @createOrder.
  ///
  /// In en, this message translates to:
  /// **'Create Order'**
  String get createOrder;

  /// No description provided for @unplannedOrder.
  ///
  /// In en, this message translates to:
  /// **'Unplanned Order'**
  String get unplannedOrder;

  /// No description provided for @viewContracts.
  ///
  /// In en, this message translates to:
  /// **'View Contracts'**
  String get viewContracts;

  /// No description provided for @refusal.
  ///
  /// In en, this message translates to:
  /// **'Refusal'**
  String get refusal;

  /// No description provided for @route.
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get route;

  /// No description provided for @refusalReason.
  ///
  /// In en, this message translates to:
  /// **'Refusal Reason'**
  String get refusalReason;

  /// No description provided for @selectReason.
  ///
  /// In en, this message translates to:
  /// **'Select refusal reason'**
  String get selectReason;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @specifyReason.
  ///
  /// In en, this message translates to:
  /// **'Please specify the reason'**
  String get specifyReason;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @visitReported.
  ///
  /// In en, this message translates to:
  /// **'Visit reported'**
  String get visitReported;

  /// No description provided for @orderCreated.
  ///
  /// In en, this message translates to:
  /// **'Order created'**
  String get orderCreated;

  /// No description provided for @contractViewed.
  ///
  /// In en, this message translates to:
  /// **'Contract viewed'**
  String get contractViewed;

  /// No description provided for @refusalSent.
  ///
  /// In en, this message translates to:
  /// **'Refusal sent'**
  String get refusalSent;

  /// No description provided for @locationPermission.
  ///
  /// In en, this message translates to:
  /// **'Location permission'**
  String get locationPermission;

  /// No description provided for @locationPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required for this feature'**
  String get locationPermissionRequired;

  /// No description provided for @requestPermission.
  ///
  /// In en, this message translates to:
  /// **'Request Permission'**
  String get requestPermission;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled'**
  String get locationServicesDisabled;

  /// No description provided for @enableLocationServices.
  ///
  /// In en, this message translates to:
  /// **'Please enable location services'**
  String get enableLocationServices;

  /// No description provided for @reportsMenu.
  ///
  /// In en, this message translates to:
  /// **'Reports Menu'**
  String get reportsMenu;

  /// No description provided for @selectReport.
  ///
  /// In en, this message translates to:
  /// **'Select Report'**
  String get selectReport;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @exportReport.
  ///
  /// In en, this message translates to:
  /// **'Export Report'**
  String get exportReport;

  /// No description provided for @reportGenerated.
  ///
  /// In en, this message translates to:
  /// **'Report generated successfully'**
  String get reportGenerated;

  /// No description provided for @reportGenerationError.
  ///
  /// In en, this message translates to:
  /// **'Error generating report'**
  String get reportGenerationError;

  /// No description provided for @akbSum.
  ///
  /// In en, this message translates to:
  /// **'AKB Sum'**
  String get akbSum;

  /// No description provided for @akbClient.
  ///
  /// In en, this message translates to:
  /// **'AKB Client'**
  String get akbClient;

  /// No description provided for @akbProduct.
  ///
  /// In en, this message translates to:
  /// **'AKB Product'**
  String get akbProduct;

  /// No description provided for @monthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Monthly Report'**
  String get monthlyReport;

  /// No description provided for @dailyReport.
  ///
  /// In en, this message translates to:
  /// **'Daily Report'**
  String get dailyReport;

  /// No description provided for @salesReport.
  ///
  /// In en, this message translates to:
  /// **'Sales Report'**
  String get salesReport;

  /// No description provided for @inventoryReport.
  ///
  /// In en, this message translates to:
  /// **'Inventory Report'**
  String get inventoryReport;

  /// No description provided for @financialReport.
  ///
  /// In en, this message translates to:
  /// **'Financial Report'**
  String get financialReport;

  /// No description provided for @kpiReport.
  ///
  /// In en, this message translates to:
  /// **'KPI Report'**
  String get kpiReport;

  /// No description provided for @cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get cash;

  /// No description provided for @nonCash.
  ///
  /// In en, this message translates to:
  /// **'Non-cash'**
  String get nonCash;

  /// No description provided for @totalOrders.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrders;

  /// No description provided for @visitedPoints.
  ///
  /// In en, this message translates to:
  /// **'Visited Points'**
  String get visitedPoints;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @averageOrder.
  ///
  /// In en, this message translates to:
  /// **'Average Order'**
  String get averageOrder;

  /// No description provided for @growthRate.
  ///
  /// In en, this message translates to:
  /// **'Growth Rate'**
  String get growthRate;

  /// No description provided for @efficiency.
  ///
  /// In en, this message translates to:
  /// **'Efficiency'**
  String get efficiency;

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @targets.
  ///
  /// In en, this message translates to:
  /// **'Targets'**
  String get targets;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @plan.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// No description provided for @fact.
  ///
  /// In en, this message translates to:
  /// **'Fact'**
  String get fact;

  /// No description provided for @percentage.
  ///
  /// In en, this message translates to:
  /// **'Percentage'**
  String get percentage;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @temperature.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperature;

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @pressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @forecast.
  ///
  /// In en, this message translates to:
  /// **'Forecast'**
  String get forecast;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @lastWeek.
  ///
  /// In en, this message translates to:
  /// **'Last Week'**
  String get lastWeek;

  /// No description provided for @lastMonth.
  ///
  /// In en, this message translates to:
  /// **'Last Month'**
  String get lastMonth;

  /// No description provided for @lastYear.
  ///
  /// In en, this message translates to:
  /// **'Last Year'**
  String get lastYear;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @from.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get from;

  /// No description provided for @to.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get to;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @beginning.
  ///
  /// In en, this message translates to:
  /// **'Beginning'**
  String get beginning;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @closed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @unavailable.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get unavailable;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @booleanTrue.
  ///
  /// In en, this message translates to:
  /// **'True'**
  String get booleanTrue;

  /// No description provided for @booleanFalse.
  ///
  /// In en, this message translates to:
  /// **'False'**
  String get booleanFalse;

  /// No description provided for @interfaceSettings.
  ///
  /// In en, this message translates to:
  /// **'Interface Settings'**
  String get interfaceSettings;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed successfully'**
  String get languageChanged;

  /// No description provided for @restartRequired.
  ///
  /// In en, this message translates to:
  /// **'Please restart the app to apply language changes'**
  String get restartRequired;

  /// No description provided for @currentLanguage.
  ///
  /// In en, this message translates to:
  /// **'Current Language'**
  String get currentLanguage;

  /// No description provided for @availableLanguages.
  ///
  /// In en, this message translates to:
  /// **'Available Languages'**
  String get availableLanguages;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changeLanguage;

  /// No description provided for @languageSelection.
  ///
  /// In en, this message translates to:
  /// **'Language Selection'**
  String get languageSelection;

  /// No description provided for @confirmLanguageChange.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to change the language?'**
  String get confirmLanguageChange;

  /// No description provided for @languageChangeWarning.
  ///
  /// In en, this message translates to:
  /// **'Changing the language will restart the app'**
  String get languageChangeWarning;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @prices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get prices;

  /// No description provided for @businessRegions.
  ///
  /// In en, this message translates to:
  /// **'Business Regions'**
  String get businessRegions;

  /// No description provided for @permissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @failure.
  ///
  /// In en, this message translates to:
  /// **'Failure'**
  String get failure;

  /// No description provided for @warning.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// No description provided for @debug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get debug;

  /// No description provided for @trace.
  ///
  /// In en, this message translates to:
  /// **'Trace'**
  String get trace;

  /// No description provided for @fatal.
  ///
  /// In en, this message translates to:
  /// **'Fatal'**
  String get fatal;

  /// No description provided for @critical.
  ///
  /// In en, this message translates to:
  /// **'Critical'**
  String get critical;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @notice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get notice;

  /// No description provided for @alert.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alert;

  /// No description provided for @agentPermissions.
  ///
  /// In en, this message translates to:
  /// **'Agent Permissions'**
  String get agentPermissions;

  /// No description provided for @userPermissionsAndVisitSteps.
  ///
  /// In en, this message translates to:
  /// **'User permissions and visit steps'**
  String get userPermissionsAndVisitSteps;

  /// No description provided for @dataValidation.
  ///
  /// In en, this message translates to:
  /// **'Data Validation'**
  String get dataValidation;

  /// No description provided for @visitManagement.
  ///
  /// In en, this message translates to:
  /// **'Visit Management'**
  String get visitManagement;

  /// No description provided for @visitSteps.
  ///
  /// In en, this message translates to:
  /// **'Visit Steps'**
  String get visitSteps;

  /// No description provided for @userCodeNotFound.
  ///
  /// In en, this message translates to:
  /// **'User code not found'**
  String get userCodeNotFound;

  /// No description provided for @errorLoadingPermissions.
  ///
  /// In en, this message translates to:
  /// **'Error loading permissions'**
  String get errorLoadingPermissions;

  /// No description provided for @skipTINDuplicateCheck.
  ///
  /// In en, this message translates to:
  /// **'Skip TIN duplicate check'**
  String get skipTINDuplicateCheck;

  /// No description provided for @allowCreationWithoutTIN.
  ///
  /// In en, this message translates to:
  /// **'Allow creation without TIN'**
  String get allowCreationWithoutTIN;

  /// No description provided for @allowCreatingPointOfSale.
  ///
  /// In en, this message translates to:
  /// **'Allow creating point of sale'**
  String get allowCreatingPointOfSale;

  /// No description provided for @strictSequence.
  ///
  /// In en, this message translates to:
  /// **'Strict Sequence'**
  String get strictSequence;

  /// No description provided for @plannedRoute.
  ///
  /// In en, this message translates to:
  /// **'Planned Route'**
  String get plannedRoute;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @mandatoryExecution.
  ///
  /// In en, this message translates to:
  /// **'Mandatory Execution'**
  String get mandatoryExecution;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optional;

  /// No description provided for @permissionsDataNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Permissions data not available'**
  String get permissionsDataNotAvailable;

  /// No description provided for @languageChangeError.
  ///
  /// In en, this message translates to:
  /// **'Error changing language'**
  String get languageChangeError;

  /// No description provided for @customers.
  ///
  /// In en, this message translates to:
  /// **'Customers'**
  String get customers;

  /// No description provided for @debitCredit.
  ///
  /// In en, this message translates to:
  /// **'Debit-Credit'**
  String get debitCredit;

  /// No description provided for @products.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get products;

  /// No description provided for @dbView.
  ///
  /// In en, this message translates to:
  /// **'DB View'**
  String get dbView;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// No description provided for @kpiDataUpdateError.
  ///
  /// In en, this message translates to:
  /// **'KPI data update error'**
  String get kpiDataUpdateError;

  /// No description provided for @onlineModeReturn.
  ///
  /// In en, this message translates to:
  /// **'Return to online mode'**
  String get onlineModeReturn;

  /// No description provided for @onlineModeReturnConfirm.
  ///
  /// In en, this message translates to:
  /// **'Do you want to check internet and server connection and return to online mode?'**
  String get onlineModeReturnConfirm;

  /// No description provided for @serverUrlNotFound.
  ///
  /// In en, this message translates to:
  /// **'Server URL not found'**
  String get serverUrlNotFound;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get connectionError;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @offline.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offline;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @okb.
  ///
  /// In en, this message translates to:
  /// **'OKB'**
  String get okb;

  /// No description provided for @akbPlan.
  ///
  /// In en, this message translates to:
  /// **'AKB Plan'**
  String get akbPlan;

  /// No description provided for @akbFact.
  ///
  /// In en, this message translates to:
  /// **'AKB Fact'**
  String get akbFact;

  /// No description provided for @forecastPercentOfFact.
  ///
  /// In en, this message translates to:
  /// **'Forecast % of Fact'**
  String get forecastPercentOfFact;

  /// No description provided for @totalPlan.
  ///
  /// In en, this message translates to:
  /// **'Total Plan'**
  String get totalPlan;

  /// No description provided for @totalFact.
  ///
  /// In en, this message translates to:
  /// **'Total Fact'**
  String get totalFact;

  /// No description provided for @charts.
  ///
  /// In en, this message translates to:
  /// **'Charts'**
  String get charts;

  /// No description provided for @akbProgress.
  ///
  /// In en, this message translates to:
  /// **'AKB Progress'**
  String get akbProgress;

  /// No description provided for @planVsFact.
  ///
  /// In en, this message translates to:
  /// **'Plan vs Fact'**
  String get planVsFact;

  /// No description provided for @planCompletion.
  ///
  /// In en, this message translates to:
  /// **'Plan Completion'**
  String get planCompletion;

  /// No description provided for @factVsRemaining.
  ///
  /// In en, this message translates to:
  /// **'Fact vs Remaining'**
  String get factVsRemaining;

  /// No description provided for @forecastTrend.
  ///
  /// In en, this message translates to:
  /// **'Forecast Trend'**
  String get forecastTrend;

  /// No description provided for @fromFactToForecast.
  ///
  /// In en, this message translates to:
  /// **'From Fact to Forecast'**
  String get fromFactToForecast;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @onTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get onTrack;

  /// No description provided for @atRisk.
  ///
  /// In en, this message translates to:
  /// **'At risk'**
  String get atRisk;

  /// No description provided for @insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// No description provided for @autoGeneratedHighlights.
  ///
  /// In en, this message translates to:
  /// **'Auto-generated highlights'**
  String get autoGeneratedHighlights;

  /// No description provided for @completion.
  ///
  /// In en, this message translates to:
  /// **'Completion'**
  String get completion;

  /// No description provided for @gapToPlan.
  ///
  /// In en, this message translates to:
  /// **'Gap to Plan'**
  String get gapToPlan;

  /// No description provided for @akbGap.
  ///
  /// In en, this message translates to:
  /// **'AKB Gap'**
  String get akbGap;

  /// No description provided for @forecastVsPlan.
  ///
  /// In en, this message translates to:
  /// **'Forecast vs Plan'**
  String get forecastVsPlan;

  /// No description provided for @todayPerformance.
  ///
  /// In en, this message translates to:
  /// **'Today Performance'**
  String get todayPerformance;

  /// No description provided for @planExecution.
  ///
  /// In en, this message translates to:
  /// **'Plan Execution'**
  String get planExecution;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @databaseView.
  ///
  /// In en, this message translates to:
  /// **'Database View'**
  String get databaseView;

  /// No description provided for @preferenceKey.
  ///
  /// In en, this message translates to:
  /// **'Preference Key'**
  String get preferenceKey;

  /// No description provided for @value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get value;

  /// No description provided for @id.
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @warehouseCode.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Code'**
  String get warehouseCode;

  /// No description provided for @codeProject.
  ///
  /// In en, this message translates to:
  /// **'Code Project'**
  String get codeProject;

  /// No description provided for @baseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get baseUrl;

  /// No description provided for @telegramId.
  ///
  /// In en, this message translates to:
  /// **'Telegram ID'**
  String get telegramId;

  /// No description provided for @chatId.
  ///
  /// In en, this message translates to:
  /// **'Chat ID'**
  String get chatId;

  /// No description provided for @topicId.
  ///
  /// In en, this message translates to:
  /// **'Topic ID'**
  String get topicId;

  /// No description provided for @createdAt.
  ///
  /// In en, this message translates to:
  /// **'Created At'**
  String get createdAt;

  /// No description provided for @updatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get updatedAt;

  /// No description provided for @totalPercent.
  ///
  /// In en, this message translates to:
  /// **'Total %'**
  String get totalPercent;

  /// No description provided for @forecastPercent.
  ///
  /// In en, this message translates to:
  /// **'Forecast %'**
  String get forecastPercent;

  /// No description provided for @akbPercent.
  ///
  /// In en, this message translates to:
  /// **'AKB %'**
  String get akbPercent;

  /// No description provided for @updateDate.
  ///
  /// In en, this message translates to:
  /// **'Update Date'**
  String get updateDate;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @confirmExit.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit?'**
  String get confirmExit;

  /// No description provided for @contactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contactPerson;

  /// No description provided for @lastVisitDate.
  ///
  /// In en, this message translates to:
  /// **'Last Visit'**
  String get lastVisitDate;

  /// No description provided for @hasOrders.
  ///
  /// In en, this message translates to:
  /// **'Has Orders'**
  String get hasOrders;

  /// No description provided for @hasContracts.
  ///
  /// In en, this message translates to:
  /// **'Has Contracts'**
  String get hasContracts;

  /// No description provided for @isVisited.
  ///
  /// In en, this message translates to:
  /// **'Is Visited'**
  String get isVisited;

  /// No description provided for @hasContract.
  ///
  /// In en, this message translates to:
  /// **'Has Contract'**
  String get hasContract;

  /// No description provided for @coordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get coordinates;

  /// No description provided for @creditLimit.
  ///
  /// In en, this message translates to:
  /// **'Credit Limit'**
  String get creditLimit;

  /// No description provided for @accumulatedCredit.
  ///
  /// In en, this message translates to:
  /// **'Accumulated Credit'**
  String get accumulatedCredit;

  /// No description provided for @codeRegion.
  ///
  /// In en, this message translates to:
  /// **'Code Region'**
  String get codeRegion;

  /// No description provided for @maps.
  ///
  /// In en, this message translates to:
  /// **'Maps'**
  String get maps;

  /// No description provided for @selectDefaultMap.
  ///
  /// In en, this message translates to:
  /// **'Select Default Map'**
  String get selectDefaultMap;

  /// No description provided for @googleMaps.
  ///
  /// In en, this message translates to:
  /// **'Google Maps'**
  String get googleMaps;

  /// No description provided for @yandexMaps.
  ///
  /// In en, this message translates to:
  /// **'Yandex Maps'**
  String get yandexMaps;

  /// No description provided for @openStreetMap.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap'**
  String get openStreetMap;

  /// No description provided for @mapProvider.
  ///
  /// In en, this message translates to:
  /// **'Map Provider'**
  String get mapProvider;

  /// No description provided for @apiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get apiKey;

  /// No description provided for @configured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get configured;

  /// No description provided for @notConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not Configured'**
  String get notConfigured;

  /// No description provided for @mapSettings.
  ///
  /// In en, this message translates to:
  /// **'Map Settings'**
  String get mapSettings;

  /// No description provided for @defaultMapChanged.
  ///
  /// In en, this message translates to:
  /// **'Default map changed successfully'**
  String get defaultMapChanged;

  /// No description provided for @currentMapProvider.
  ///
  /// In en, this message translates to:
  /// **'Current Map Provider'**
  String get currentMapProvider;

  /// No description provided for @availableMaps.
  ///
  /// In en, this message translates to:
  /// **'Available Maps'**
  String get availableMaps;

  /// No description provided for @mapConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Map Configuration'**
  String get mapConfiguration;

  /// No description provided for @visitProgress.
  ///
  /// In en, this message translates to:
  /// **'Visit Progress'**
  String get visitProgress;

  /// No description provided for @visitStepNumber.
  ///
  /// In en, this message translates to:
  /// **'Visit Step'**
  String get visitStepNumber;

  /// No description provided for @skipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skipped;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @mandatory.
  ///
  /// In en, this message translates to:
  /// **'Mandatory'**
  String get mandatory;

  /// No description provided for @completedAt.
  ///
  /// In en, this message translates to:
  /// **'Completed at'**
  String get completedAt;

  /// No description provided for @skippedAt.
  ///
  /// In en, this message translates to:
  /// **'Skipped at'**
  String get skippedAt;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @previousStepsRequired.
  ///
  /// In en, this message translates to:
  /// **'Previous steps must be completed'**
  String get previousStepsRequired;

  /// No description provided for @completeStep.
  ///
  /// In en, this message translates to:
  /// **'Complete Step'**
  String get completeStep;

  /// No description provided for @skipStep.
  ///
  /// In en, this message translates to:
  /// **'Skip Step'**
  String get skipStep;

  /// No description provided for @confirmCompletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm completion'**
  String get confirmCompletion;

  /// No description provided for @stepCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Step completed successfully'**
  String get stepCompletedSuccessfully;

  /// No description provided for @stepSkippedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Step skipped successfully'**
  String get stepSkippedSuccessfully;

  /// No description provided for @visitCompletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Visit completed successfully!'**
  String get visitCompletedSuccessfully;

  /// No description provided for @finishVisit.
  ///
  /// In en, this message translates to:
  /// **'Finish Visit'**
  String get finishVisit;

  /// No description provided for @allRequiredStepsMustBeCompleted.
  ///
  /// In en, this message translates to:
  /// **'All required steps must be completed'**
  String get allRequiredStepsMustBeCompleted;

  /// No description provided for @visitInfo.
  ///
  /// In en, this message translates to:
  /// **'Visit Information'**
  String get visitInfo;

  /// No description provided for @client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @totalSteps.
  ///
  /// In en, this message translates to:
  /// **'Total Steps'**
  String get totalSteps;

  /// No description provided for @requiredSteps.
  ///
  /// In en, this message translates to:
  /// **'Required Steps'**
  String get requiredSteps;

  /// No description provided for @unknownState.
  ///
  /// In en, this message translates to:
  /// **'Unknown state'**
  String get unknownState;

  /// No description provided for @cancelCompletion.
  ///
  /// In en, this message translates to:
  /// **'Cancel Completion'**
  String get cancelCompletion;

  /// No description provided for @confirmSkip.
  ///
  /// In en, this message translates to:
  /// **'Confirm Skip'**
  String get confirmSkip;

  /// No description provided for @enterNotesOptional.
  ///
  /// In en, this message translates to:
  /// **'Enter notes (optional)'**
  String get enterNotesOptional;

  /// No description provided for @enterSkipReason.
  ///
  /// In en, this message translates to:
  /// **'Enter skip reason'**
  String get enterSkipReason;

  /// No description provided for @stepCannotBeSkipped.
  ///
  /// In en, this message translates to:
  /// **'This step cannot be skipped'**
  String get stepCannotBeSkipped;

  /// No description provided for @allRequiredStepsCompleted.
  ///
  /// In en, this message translates to:
  /// **'All required steps completed'**
  String get allRequiredStepsCompleted;

  /// No description provided for @cancelVisit.
  ///
  /// In en, this message translates to:
  /// **'Cancel Visit'**
  String get cancelVisit;

  /// No description provided for @cancelVisitConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel this visit? All progress will be lost.'**
  String get cancelVisitConfirmation;

  /// No description provided for @soapRequest.
  ///
  /// In en, this message translates to:
  /// **'SOAP Request'**
  String get soapRequest;

  /// No description provided for @soapRequestCopied.
  ///
  /// In en, this message translates to:
  /// **'SOAP request copied'**
  String get soapRequestCopied;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @orderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order not found'**
  String get orderNotFound;

  /// No description provided for @readOnly.
  ///
  /// In en, this message translates to:
  /// **'Read-only'**
  String get readOnly;

  /// No description provided for @pageUnderDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Page under development'**
  String get pageUnderDevelopment;

  /// No description provided for @stepCompletedReadOnly.
  ///
  /// In en, this message translates to:
  /// **'This step is completed. View-only mode.'**
  String get stepCompletedReadOnly;

  /// No description provided for @stepTypeNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'This step type page is not implemented yet.'**
  String get stepTypeNotImplemented;

  /// No description provided for @orderDetailsNavigationErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error opening order details'**
  String get orderDetailsNavigationErrorPrefix;

  /// No description provided for @errorOccurredPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String get errorOccurredPrefix;

  /// No description provided for @stepErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Step error'**
  String get stepErrorPrefix;

  /// No description provided for @visitFinishErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error finishing visit'**
  String get visitFinishErrorPrefix;

  /// No description provided for @stepsCount.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get stepsCount;

  /// No description provided for @visitFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing visit...'**
  String get visitFinishing;

  /// No description provided for @orderNumber.
  ///
  /// In en, this message translates to:
  /// **'Order number'**
  String get orderNumber;

  String get dataSaveError;
  String get saveErrorPrefix;
  String get dataLoadError;
  String get productsLoadError;
  String get settingsUpdateError;
  String get clearOrder;
  String get suggestedOrders;
  String get productSelectionError;
  String get orderDataCleared;
  String get dataClearError;
  String get orderCreationError;
  String get deliveryDateChangedSuccess;
  String get dateChangeError;
  String get clearOrderConfirmTitle;
  String get clearOrderConfirmMessage;

  String get clientDataLoadError;
  String get locationNotAvailable;
  String get visitCompletedFor;
  String get contractsPageError;
  String get loadingClientImages;
  String get clientImagesLoaded;
  String get imageLoadError;
  String get disableVisitTodayFilter;
  String get showVisitTodayOnly;
  String get newClient;
  String get orderHistory;
  String get tradingPointsNotFound;
  String get clientCount;
  String get manageClientImages;

  String get ordersCount;
  String get orderNumberPrefix;
  String get clientOrdersFor;

  /// No description provided for @checkingDistance.
  ///
  /// In en, this message translates to:
  /// **'Checking distance to trading point...'**
  String get checkingDistance;

  /// No description provided for @distanceRestrictionError.
  ///
  /// In en, this message translates to:
  /// **'You are too far from the trading point to complete the visit.'**
  String get distanceRestrictionError;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ru': return AppLocalizationsRu();
    case 'uz': return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
