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
  /// **'Trading points'**
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
  /// **'Last sync: {time}'**
  String lastSync(String time);

  /// No description provided for @syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing...'**
  String get syncing;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Synchronization completed'**
  String get syncComplete;

  /// No description provided for @syncError.
  ///
  /// In en, this message translates to:
  /// **'Sync error: {error}'**
  String syncError(String error);

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
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get tryAgain;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
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
  /// **'Contract details'**
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

  /// No description provided for @languageAutoDetected.
  ///
  /// In en, this message translates to:
  /// **'Language auto-detected from system'**
  String get languageAutoDetected;

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
  /// **'AKB plan'**
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
  /// **'Updated: {date} {time}'**
  String updatedAt(String date, String time);

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
  /// **'This step is completed. Read-only mode.'**
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
  /// **'Order № {number}'**
  String orderNumber(String number);

  /// No description provided for @dataSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving data'**
  String get dataSaveError;

  /// No description provided for @saveErrorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Save error'**
  String get saveErrorPrefix;

  /// No description provided for @dataLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading data'**
  String get dataLoadError;

  /// No description provided for @productsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading products'**
  String get productsLoadError;

  /// No description provided for @settingsUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating settings'**
  String get settingsUpdateError;

  /// No description provided for @clearOrder.
  ///
  /// In en, this message translates to:
  /// **'Clear order'**
  String get clearOrder;

  /// No description provided for @suggestedOrders.
  ///
  /// In en, this message translates to:
  /// **'Suggested orders'**
  String get suggestedOrders;

  /// No description provided for @productSelectionError.
  ///
  /// In en, this message translates to:
  /// **'Error navigating to product selection'**
  String get productSelectionError;

  /// No description provided for @orderDataCleared.
  ///
  /// In en, this message translates to:
  /// **'Order data cleared'**
  String get orderDataCleared;

  /// No description provided for @dataClearError.
  ///
  /// In en, this message translates to:
  /// **'Error clearing data'**
  String get dataClearError;

  /// No description provided for @orderCreationError.
  ///
  /// In en, this message translates to:
  /// **'Error creating order'**
  String get orderCreationError;

  /// No description provided for @deliveryDateChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Delivery date changed successfully'**
  String get deliveryDateChangedSuccess;

  /// No description provided for @dateChangeError.
  ///
  /// In en, this message translates to:
  /// **'Error changing date'**
  String get dateChangeError;

  /// No description provided for @clearOrderConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear order'**
  String get clearOrderConfirmTitle;

  /// No description provided for @clearOrderConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'All selected products and related data will be deleted. Settings will be preserved. Do you want to continue?'**
  String get clearOrderConfirmMessage;

  /// No description provided for @clientDataLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading client data'**
  String get clientDataLoadError;

  /// No description provided for @locationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Location data not available. Visit cannot be completed.'**
  String get locationNotAvailable;

  /// No description provided for @visitCompletedFor.
  ///
  /// In en, this message translates to:
  /// **'visit completed successfully for'**
  String get visitCompletedFor;

  /// No description provided for @contractsPageError.
  ///
  /// In en, this message translates to:
  /// **'Error navigating to contracts page'**
  String get contractsPageError;

  /// No description provided for @loadingClientImages.
  ///
  /// In en, this message translates to:
  /// **'Loading client images...'**
  String get loadingClientImages;

  /// No description provided for @clientImagesLoaded.
  ///
  /// In en, this message translates to:
  /// **'Client images loaded'**
  String get clientImagesLoaded;

  /// No description provided for @imageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading image'**
  String get imageLoadError;

  /// No description provided for @disableVisitTodayFilter.
  ///
  /// In en, this message translates to:
  /// **'Disable today\'s visit filter'**
  String get disableVisitTodayFilter;

  /// No description provided for @showVisitTodayOnly.
  ///
  /// In en, this message translates to:
  /// **'Show only today\'s visit clients'**
  String get showVisitTodayOnly;

  /// No description provided for @newClient.
  ///
  /// In en, this message translates to:
  /// **'New client'**
  String get newClient;

  /// No description provided for @orderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order history'**
  String get orderHistory;

  /// No description provided for @tradingPointsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Trading points not found'**
  String get tradingPointsNotFound;

  /// No description provided for @clientCount.
  ///
  /// In en, this message translates to:
  /// **'Client count'**
  String get clientCount;

  /// No description provided for @manageClientImages.
  ///
  /// In en, this message translates to:
  /// **'Manage client images'**
  String get manageClientImages;

  /// No description provided for @ordersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} orders'**
  String ordersCount(int count);

  /// No description provided for @orderNumberPrefix.
  ///
  /// In en, this message translates to:
  /// **'Order №'**
  String get orderNumberPrefix;

  /// No description provided for @viewOrder.
  ///
  /// In en, this message translates to:
  /// **'View Order'**
  String get viewOrder;

  /// No description provided for @clientOrdersFor.
  ///
  /// In en, this message translates to:
  /// **'orders for client'**
  String get clientOrdersFor;

  /// No description provided for @locationServicesDisabledSortingNotWork.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled. Distance sorting will not work.'**
  String get locationServicesDisabledSortingNotWork;

  /// No description provided for @userDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'User data not found'**
  String get userDataNotFound;

  /// No description provided for @phoneNumberNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Phone number not specified'**
  String get phoneNumberNotSpecified;

  /// No description provided for @phoneCallFailed.
  ///
  /// In en, this message translates to:
  /// **'Phone call failed'**
  String get phoneCallFailed;

  /// No description provided for @connectedToInternet.
  ///
  /// In en, this message translates to:
  /// **'Connected to internet'**
  String get connectedToInternet;

  /// No description provided for @offlineModeActive.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get offlineModeActive;

  /// No description provided for @refusalReasonSent.
  ///
  /// In en, this message translates to:
  /// **'Refusal reason sent for'**
  String get refusalReasonSent;

  /// No description provided for @viewPanel.
  ///
  /// In en, this message translates to:
  /// **'View panel'**
  String get viewPanel;

  /// No description provided for @sortByDistanceRequiresPermission.
  ///
  /// In en, this message translates to:
  /// **'Location permission required for distance sorting'**
  String get sortByDistanceRequiresPermission;

  /// No description provided for @sortByDistance.
  ///
  /// In en, this message translates to:
  /// **'Sort by distance'**
  String get sortByDistance;

  /// No description provided for @sortAlphabeticalAZ.
  ///
  /// In en, this message translates to:
  /// **'Sort alphabetically (A-Z)'**
  String get sortAlphabeticalAZ;

  /// No description provided for @sortAlphabeticalZA.
  ///
  /// In en, this message translates to:
  /// **'Sort alphabetically (Z-A)'**
  String get sortAlphabeticalZA;

  /// No description provided for @serverSelected.
  ///
  /// In en, this message translates to:
  /// **'server selected'**
  String get serverSelected;

  /// No description provided for @noInternetNoSavedUser.
  ///
  /// In en, this message translates to:
  /// **'No internet and no saved user data found'**
  String get noInternetNoSavedUser;

  /// No description provided for @noInternetLoginMismatch.
  ///
  /// In en, this message translates to:
  /// **'No internet and entered login does not match saved login'**
  String get noInternetLoginMismatch;

  /// No description provided for @savedUserServerMismatch.
  ///
  /// In en, this message translates to:
  /// **'Saved user data does not match current server. Please change server.'**
  String get savedUserServerMismatch;

  /// No description provided for @noInternetUserNotInDb.
  ///
  /// In en, this message translates to:
  /// **'No internet and user data not found in database or does not match'**
  String get noInternetUserNotInDb;

  /// No description provided for @offlineLoginError.
  ///
  /// In en, this message translates to:
  /// **'Offline login error'**
  String get offlineLoginError;

  /// No description provided for @noInternetAvailable.
  ///
  /// In en, this message translates to:
  /// **'No internet available'**
  String get noInternetAvailable;

  /// No description provided for @offlineModeQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to enter offline mode as'**
  String get offlineModeQuestion;

  /// No description provided for @offlineModeDescription.
  ///
  /// In en, this message translates to:
  /// **'In offline mode you can work with existing data, but cannot load new data.'**
  String get offlineModeDescription;

  /// No description provided for @offlineLogin.
  ///
  /// In en, this message translates to:
  /// **'Offline login'**
  String get offlineLogin;

  /// No description provided for @dataUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating data...'**
  String get dataUpdating;

  /// No description provided for @errorPrefix.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorPrefix;

  /// No description provided for @cacheDataUsed.
  ///
  /// In en, this message translates to:
  /// **'Cache data is being used'**
  String get cacheDataUsed;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login Successful!'**
  String get loginSuccessful;

  /// No description provided for @onlineLoginError.
  ///
  /// In en, this message translates to:
  /// **'Online login processing error'**
  String get onlineLoginError;

  /// No description provided for @unknownUserRole.
  ///
  /// In en, this message translates to:
  /// **'Unknown user role'**
  String get unknownUserRole;

  /// No description provided for @enterField.
  ///
  /// In en, this message translates to:
  /// **'Please enter'**
  String get enterField;

  /// No description provided for @imageServiceNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Image service not available'**
  String get imageServiceNotAvailable;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @pullToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh'**
  String get pullToRefresh;

  /// No description provided for @pullToRefreshOrSyncData.
  ///
  /// In en, this message translates to:
  /// **'If pull to refresh doesn\'t work, use \'sync all data\' option in settings menu'**
  String get pullToRefreshOrSyncData;

  /// No description provided for @checkingDistance.
  ///
  /// In en, this message translates to:
  /// **'Checking distance...'**
  String get checkingDistance;

  /// No description provided for @distanceRestrictionError.
  ///
  /// In en, this message translates to:
  /// **'You are too far from the client. Please move closer to complete the visit.'**
  String get distanceRestrictionError;

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

  /// No description provided for @syncStatusIdle.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get syncStatusIdle;

  /// No description provided for @syncStatusProducts.
  ///
  /// In en, this message translates to:
  /// **'Syncing products'**
  String get syncStatusProducts;

  /// No description provided for @syncStatusBalances.
  ///
  /// In en, this message translates to:
  /// **'Syncing balances'**
  String get syncStatusBalances;

  /// No description provided for @syncStatusOrders.
  ///
  /// In en, this message translates to:
  /// **'Syncing orders'**
  String get syncStatusOrders;

  /// No description provided for @syncStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Sync completed'**
  String get syncStatusCompleted;

  /// No description provided for @syncStatusError.
  ///
  /// In en, this message translates to:
  /// **'Sync error'**
  String get syncStatusError;

  /// No description provided for @syncInProgress.
  ///
  /// In en, this message translates to:
  /// **'Synchronization in Progress'**
  String get syncInProgress;

  /// No description provided for @syncErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'User code not found'**
  String get syncErrorUserNotFound;

  /// No description provided for @syncAlreadyInProgress.
  ///
  /// In en, this message translates to:
  /// **'Sync already in progress'**
  String get syncAlreadyInProgress;

  /// No description provided for @syncCompleted.
  ///
  /// In en, this message translates to:
  /// **'Data updated successfully'**
  String get syncCompleted;

  /// No description provided for @clientBalance.
  ///
  /// In en, this message translates to:
  /// **'Client balance'**
  String get clientBalance;

  /// No description provided for @clientBalanceDetails.
  ///
  /// In en, this message translates to:
  /// **'Balance Details'**
  String get clientBalanceDetails;

  /// No description provided for @clientIsDebtor.
  ///
  /// In en, this message translates to:
  /// **'Client is debtor. Total debt: {amount} sum'**
  String clientIsDebtor(String amount);

  /// No description provided for @clientHasOverpayment.
  ///
  /// In en, this message translates to:
  /// **'Client has overpaid. Overpayment: {amount} sum'**
  String clientHasOverpayment(String amount);

  /// No description provided for @balanceIsZero.
  ///
  /// In en, this message translates to:
  /// **'Balance is zero'**
  String get balanceIsZero;

  /// No description provided for @totalDebt.
  ///
  /// In en, this message translates to:
  /// **'Total debt'**
  String get totalDebt;

  /// No description provided for @totalPayment.
  ///
  /// In en, this message translates to:
  /// **'Total Payment'**
  String get totalPayment;

  /// No description provided for @totalOrder.
  ///
  /// In en, this message translates to:
  /// **'Total Order'**
  String get totalOrder;

  /// No description provided for @unpaidOrders.
  ///
  /// In en, this message translates to:
  /// **'{count} unpaid'**
  String unpaidOrders(int count);

  /// No description provided for @overdueOrders.
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String overdueOrders(int count);

  /// No description provided for @balanceStatus.
  ///
  /// In en, this message translates to:
  /// **'Balance status'**
  String get balanceStatus;

  /// No description provided for @contractsTab.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contractsTab;

  /// No description provided for @ordersTab.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersTab;

  /// No description provided for @overviewTab.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTab;

  /// No description provided for @paymentAndDebtRatio.
  ///
  /// In en, this message translates to:
  /// **'Payment and Debt Ratio'**
  String get paymentAndDebtRatio;

  /// No description provided for @orderAndPaymentRatio.
  ///
  /// In en, this message translates to:
  /// **'Order and Payment Ratio'**
  String get orderAndPaymentRatio;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @partiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get partiallyPaid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @overdueDays.
  ///
  /// In en, this message translates to:
  /// **'Overdue {days} days'**
  String overdueDays(int days);

  /// No description provided for @refreshAfterSeconds.
  ///
  /// In en, this message translates to:
  /// **'Can refresh after {seconds} seconds'**
  String refreshAfterSeconds(int seconds);

  /// No description provided for @balanceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String balanceUpdated(String date);

  /// No description provided for @balanceServerDataUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Balance status as of: {date}'**
  String balanceServerDataUpdatedAt(String date);

  /// No description provided for @balanceDataMayBeOutdated.
  ///
  /// In en, this message translates to:
  /// **'Balance data may be outdated'**
  String get balanceDataMayBeOutdated;

  /// No description provided for @noBalanceData.
  ///
  /// In en, this message translates to:
  /// **'Balance data not found'**
  String get noBalanceData;

  /// No description provided for @balanceLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading balance'**
  String get balanceLoadError;

  /// No description provided for @balanceServiceNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Balance service not available'**
  String get balanceServiceNotAvailable;

  /// No description provided for @clientInnNotFound.
  ///
  /// In en, this message translates to:
  /// **'Client INN not found'**
  String get clientInnNotFound;

  /// No description provided for @statistics.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statistics;

  /// No description provided for @contractsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} contracts'**
  String contractsCount(int count);

  /// No description provided for @contract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// No description provided for @order.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get order;

  /// No description provided for @overpayment.
  ///
  /// In en, this message translates to:
  /// **'Overpayment'**
  String get overpayment;

  /// No description provided for @debt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debt;

  /// No description provided for @debtAndOverpaymentRatio.
  ///
  /// In en, this message translates to:
  /// **'Debt and Overpayment Ratio'**
  String get debtAndOverpaymentRatio;

  /// No description provided for @debtor.
  ///
  /// In en, this message translates to:
  /// **'Debtor'**
  String get debtor;

  /// No description provided for @excess.
  ///
  /// In en, this message translates to:
  /// **'Excess'**
  String get excess;

  /// No description provided for @orderAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Order'**
  String get orderAmountLabel;

  /// No description provided for @paidAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidAmountLabel;

  /// No description provided for @debtLabel.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debtLabel;

  /// No description provided for @excessLabel.
  ///
  /// In en, this message translates to:
  /// **'Excess'**
  String get excessLabel;

  /// No description provided for @ordersStatus.
  ///
  /// In en, this message translates to:
  /// **'Orders Status'**
  String get ordersStatus;

  /// No description provided for @clearBalanceCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Balance Cache'**
  String get clearBalanceCache;

  /// No description provided for @clearBalanceCacheConfirm.
  ///
  /// In en, this message translates to:
  /// **'All client balance data will be deleted. It will be reloaded next time balance is viewed.'**
  String get clearBalanceCacheConfirm;

  /// No description provided for @balanceCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Balance cache cleared'**
  String get balanceCacheCleared;

  /// No description provided for @fakturaNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error while connecting to Faktura.uz'**
  String get fakturaNetworkError;

  /// No description provided for @tradePointTypesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Trade point types list is empty. Please add trade points first.'**
  String get tradePointTypesEmpty;

  /// No description provided for @tradePointTypesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading trade point types.'**
  String get tradePointTypesLoadError;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get timeoutError;

  /// No description provided for @dataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Data not found.'**
  String get dataNotFound;

  /// No description provided for @invalidDataError.
  ///
  /// In en, this message translates to:
  /// **'Invalid data received.'**
  String get invalidDataError;

  /// No description provided for @unknownBalanceError.
  ///
  /// In en, this message translates to:
  /// **'An unknown error occurred.'**
  String get unknownBalanceError;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryButton;

  /// No description provided for @balanceFor.
  ///
  /// In en, this message translates to:
  /// **'Balance: {name}'**
  String balanceFor(String name);

  /// No description provided for @overviewTabShort.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTabShort;

  /// No description provided for @contractsTabShort.
  ///
  /// In en, this message translates to:
  /// **'Contracts'**
  String get contractsTabShort;

  /// No description provided for @ordersTabShort.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersTabShort;

  /// No description provided for @totalOrdered.
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrdered;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @contractsCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Contracts Count'**
  String get contractsCountLabel;

  /// No description provided for @ordersCountLabel.
  ///
  /// In en, this message translates to:
  /// **'Orders Count'**
  String get ordersCountLabel;

  /// No description provided for @unpaidOrdersLabel.
  ///
  /// In en, this message translates to:
  /// **'Unpaid Orders'**
  String get unpaidOrdersLabel;

  /// No description provided for @partiallyPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Partially Paid'**
  String get partiallyPaidLabel;

  /// No description provided for @overdueLabel.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdueLabel;

  /// No description provided for @contractWithCode.
  ///
  /// In en, this message translates to:
  /// **'Contract: {code}'**
  String contractWithCode(String code);

  /// No description provided for @totalSummary.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get totalSummary;

  /// No description provided for @paidSummary.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidSummary;

  /// No description provided for @partialSummary.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partialSummary;

  /// No description provided for @unpaidSummary.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaidSummary;

  /// No description provided for @excessSummary.
  ///
  /// In en, this message translates to:
  /// **'Excess'**
  String get excessSummary;

  /// No description provided for @ordersWithCount.
  ///
  /// In en, this message translates to:
  /// **'Orders ({count})'**
  String ordersWithCount(int count);

  /// No description provided for @overpaymentWithCount.
  ///
  /// In en, this message translates to:
  /// **'Overpayments ({count})'**
  String overpaymentWithCount(int count);

  /// No description provided for @orderWithNumber.
  ///
  /// In en, this message translates to:
  /// **'Order: {number}'**
  String orderWithNumber(String number);

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No data available'**
  String get noDataAvailable;

  /// No description provided for @noContractsFound.
  ///
  /// In en, this message translates to:
  /// **'No contracts found'**
  String get noContractsFound;

  /// No description provided for @noOrdersFound.
  ///
  /// In en, this message translates to:
  /// **'No orders found'**
  String get noOrdersFound;

  /// No description provided for @paidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLabel;

  /// No description provided for @debtLabelChart.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debtLabelChart;

  /// No description provided for @paymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get paymentLabel;

  /// No description provided for @partialLabel.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get partialLabel;

  /// No description provided for @unpaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaidLabel;

  /// No description provided for @countItems.
  ///
  /// In en, this message translates to:
  /// **'{count} items'**
  String countItems(int count);

  /// No description provided for @contractDialog.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contractDialog;

  /// No description provided for @codeLabel.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String codeLabel(String code);

  /// No description provided for @projectLabel.
  ///
  /// In en, this message translates to:
  /// **'Project: {project}'**
  String projectLabel(String project);

  /// No description provided for @idLabel.
  ///
  /// In en, this message translates to:
  /// **'ID: {id}'**
  String idLabel(String id);

  /// No description provided for @closeButton.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeButton;

  /// No description provided for @paymentAmount.
  ///
  /// In en, this message translates to:
  /// **'Payment: {amount}'**
  String paymentAmount(String amount);

  /// No description provided for @debtAmount.
  ///
  /// In en, this message translates to:
  /// **'Debt: {amount}'**
  String debtAmount(String amount);

  /// No description provided for @securityCheck.
  ///
  /// In en, this message translates to:
  /// **'Security Check'**
  String get securityCheck;

  /// No description provided for @securityCheckLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get securityCheckLoading;

  /// No description provided for @securityCheckVerifying.
  ///
  /// In en, this message translates to:
  /// **'Security verification...'**
  String get securityCheckVerifying;

  /// No description provided for @securityCheckAllowed.
  ///
  /// In en, this message translates to:
  /// **'Access granted'**
  String get securityCheckAllowed;

  /// No description provided for @securityCheckBlocked.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get securityCheckBlocked;

  /// No description provided for @securityCheckError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get securityCheckError;

  /// No description provided for @securityCheckLogin.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get securityCheckLogin;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access Denied'**
  String get accessDenied;

  /// No description provided for @accessDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your access to this application has been blocked.'**
  String get accessDeniedMessage;

  /// No description provided for @accessBlockedReasonAccountBound.
  ///
  /// In en, this message translates to:
  /// **'This account is linked to another device'**
  String get accessBlockedReasonAccountBound;

  /// No description provided for @accessBlockedReasonDeviceBound.
  ///
  /// In en, this message translates to:
  /// **'This device has another account'**
  String get accessBlockedReasonDeviceBound;

  /// No description provided for @accessBlockedReasonHighRisk.
  ///
  /// In en, this message translates to:
  /// **'Device does not meet security requirements'**
  String get accessBlockedReasonHighRisk;

  /// No description provided for @accessBlockedReasonPolicyViolation.
  ///
  /// In en, this message translates to:
  /// **'Security policy violated'**
  String get accessBlockedReasonPolicyViolation;

  /// No description provided for @accessBlockedReasonUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown reason'**
  String get accessBlockedReasonUnknown;

  /// No description provided for @retryCheck.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryCheck;

  /// No description provided for @contactSupportTeam.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupportTeam;

  /// No description provided for @logoutConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logoutConfirmTitle;

  /// No description provided for @logoutConfirmMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmMessage;

  /// No description provided for @newContract.
  ///
  /// In en, this message translates to:
  /// **'New contract'**
  String get newContract;

  /// No description provided for @createContract.
  ///
  /// In en, this message translates to:
  /// **'Create contract'**
  String get createContract;

  /// No description provided for @createContractTitle.
  ///
  /// In en, this message translates to:
  /// **'New Contract'**
  String get createContractTitle;

  /// No description provided for @createContractSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fill in all fields'**
  String get createContractSubtitle;

  /// No description provided for @contractCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Contract created successfully'**
  String get contractCreatedSuccess;

  /// No description provided for @contractCreatedError.
  ///
  /// In en, this message translates to:
  /// **'Error creating contract'**
  String get contractCreatedError;

  /// No description provided for @contractListRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Contract list refreshed'**
  String get contractListRefreshed;

  /// No description provided for @selectClient.
  ///
  /// In en, this message translates to:
  /// **'Select client'**
  String get selectClient;

  /// No description provided for @selectContractType.
  ///
  /// In en, this message translates to:
  /// **'Select contract type'**
  String get selectContractType;

  /// No description provided for @contractTypesNotFound.
  ///
  /// In en, this message translates to:
  /// **'Contract types not found'**
  String get contractTypesNotFound;

  /// No description provided for @reloadContractTypes.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reloadContractTypes;

  /// No description provided for @autoFilled.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled'**
  String get autoFilled;

  /// No description provided for @referenceNumber.
  ///
  /// In en, this message translates to:
  /// **'Reference number'**
  String get referenceNumber;

  /// No description provided for @referenceTermDate.
  ///
  /// In en, this message translates to:
  /// **'Term date'**
  String get referenceTermDate;

  /// No description provided for @certificateNumber.
  ///
  /// In en, this message translates to:
  /// **'Certificate number'**
  String get certificateNumber;

  /// No description provided for @certificateTermDate.
  ///
  /// In en, this message translates to:
  /// **'Certificate term date'**
  String get certificateTermDate;

  /// No description provided for @certificateUnlimited.
  ///
  /// In en, this message translates to:
  /// **'Certificate unlimited'**
  String get certificateUnlimited;

  /// No description provided for @passportNumber.
  ///
  /// In en, this message translates to:
  /// **'Passport number'**
  String get passportNumber;

  /// No description provided for @passportTermDate.
  ///
  /// In en, this message translates to:
  /// **'Passport term date'**
  String get passportTermDate;

  /// No description provided for @districtName.
  ///
  /// In en, this message translates to:
  /// **'District name'**
  String get districtName;

  /// No description provided for @districtCode.
  ///
  /// In en, this message translates to:
  /// **'District code'**
  String get districtCode;

  /// No description provided for @documentInfo.
  ///
  /// In en, this message translates to:
  /// **'Document information'**
  String get documentInfo;

  /// No description provided for @regionInfo.
  ///
  /// In en, this message translates to:
  /// **'Region information'**
  String get regionInfo;

  /// No description provided for @creatingContract.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creatingContract;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @serverTimeout.
  ///
  /// In en, this message translates to:
  /// **'Server connection timed out'**
  String get serverTimeout;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please connect to the internet'**
  String get noInternetConnection;

  /// No description provided for @createClientTitle.
  ///
  /// In en, this message translates to:
  /// **'New Client'**
  String get createClientTitle;

  /// No description provided for @createClientBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get createClientBasicInfo;

  /// No description provided for @createClientContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get createClientContactInfo;

  /// No description provided for @createClientAddressInfo.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get createClientAddressInfo;

  /// No description provided for @createClientBankInfo.
  ///
  /// In en, this message translates to:
  /// **'Bank Details (optional)'**
  String get createClientBankInfo;

  /// No description provided for @createClientClientName.
  ///
  /// In en, this message translates to:
  /// **'Client Name'**
  String get createClientClientName;

  /// No description provided for @createClientClientNameHint.
  ///
  /// In en, this message translates to:
  /// **'Store or company name'**
  String get createClientClientNameHint;

  /// No description provided for @createClientSignboard.
  ///
  /// In en, this message translates to:
  /// **'Signboard'**
  String get createClientSignboard;

  /// No description provided for @createClientSignboardHint.
  ///
  /// In en, this message translates to:
  /// **'External display name'**
  String get createClientSignboardHint;

  /// No description provided for @createClientInn.
  ///
  /// In en, this message translates to:
  /// **'TIN (Tax ID)'**
  String get createClientInn;

  /// No description provided for @createClientInnHint.
  ///
  /// In en, this message translates to:
  /// **'9 or 14 digits'**
  String get createClientInnHint;

  /// No description provided for @createClientTradePointType.
  ///
  /// In en, this message translates to:
  /// **'Trade Point Type'**
  String get createClientTradePointType;

  /// No description provided for @createClientSelectTradePointType.
  ///
  /// In en, this message translates to:
  /// **'Select trade point type'**
  String get createClientSelectTradePointType;

  /// No description provided for @createClientRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get createClientRegion;

  /// No description provided for @createClientSelectRegion.
  ///
  /// In en, this message translates to:
  /// **'Select region'**
  String get createClientSelectRegion;

  /// No description provided for @createClientContactPerson.
  ///
  /// In en, this message translates to:
  /// **'Contact Person'**
  String get createClientContactPerson;

  /// No description provided for @createClientContactPersonHint.
  ///
  /// In en, this message translates to:
  /// **'Responsible person name'**
  String get createClientContactPersonHint;

  /// No description provided for @createClientPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get createClientPhone;

  /// No description provided for @createClientPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'+998 XX XXX XX XX'**
  String get createClientPhoneHint;

  /// No description provided for @createClientResponsiblePhone.
  ///
  /// In en, this message translates to:
  /// **'Responsible Person Phone'**
  String get createClientResponsiblePhone;

  /// No description provided for @createClientResponsiblePhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Additional phone (optional)'**
  String get createClientResponsiblePhoneHint;

  /// No description provided for @createClientAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get createClientAddress;

  /// No description provided for @createClientAddressHint.
  ///
  /// In en, this message translates to:
  /// **'Full address'**
  String get createClientAddressHint;

  /// No description provided for @createClientDeliveryAddress.
  ///
  /// In en, this message translates to:
  /// **'Delivery Address'**
  String get createClientDeliveryAddress;

  /// No description provided for @createClientDeliveryAddressHint.
  ///
  /// In en, this message translates to:
  /// **'If different (optional)'**
  String get createClientDeliveryAddressHint;

  /// No description provided for @createClientLandmark.
  ///
  /// In en, this message translates to:
  /// **'Landmark'**
  String get createClientLandmark;

  /// No description provided for @createClientLandmarkHint.
  ///
  /// In en, this message translates to:
  /// **'Nearby recognizable place'**
  String get createClientLandmarkHint;

  /// No description provided for @createClientDirector.
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get createClientDirector;

  /// No description provided for @createClientDirectorHint.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get createClientDirectorHint;

  /// No description provided for @createClientMfo.
  ///
  /// In en, this message translates to:
  /// **'MFO'**
  String get createClientMfo;

  /// No description provided for @createClientMfoHint.
  ///
  /// In en, this message translates to:
  /// **'5-digit bank code'**
  String get createClientMfoHint;

  /// No description provided for @createClientBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank Account'**
  String get createClientBankAccount;

  /// No description provided for @createClientBankAccountHint.
  ///
  /// In en, this message translates to:
  /// **'20 digits'**
  String get createClientBankAccountHint;

  /// No description provided for @createClientLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get createClientLocation;

  /// No description provided for @createClientLocationDetecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting...'**
  String get createClientLocationDetecting;

  /// No description provided for @createClientLocationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Location not found'**
  String get createClientLocationNotFound;

  /// No description provided for @createClientRefreshLocation.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get createClientRefreshLocation;

  /// No description provided for @createClientSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create Client'**
  String get createClientSubmit;

  /// No description provided for @createClientCreating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get createClientCreating;

  /// No description provided for @createClientSuccess.
  ///
  /// In en, this message translates to:
  /// **'Client Created!'**
  String get createClientSuccess;

  /// No description provided for @createClientSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing data...'**
  String get createClientSyncing;

  /// No description provided for @createClientCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get createClientCode;

  /// No description provided for @createClientTerritoryWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'Important Notice!'**
  String get createClientTerritoryWarningTitle;

  /// No description provided for @createClientTerritoryWarningMessage.
  ///
  /// In en, this message translates to:
  /// **'Client creation must be performed within their trading territory. Otherwise, problems may occur when creating an order and its delivery.'**
  String get createClientTerritoryWarningMessage;

  /// No description provided for @createClientAutoFilledHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-filled. Modify if necessary.'**
  String get createClientAutoFilledHint;

  /// No description provided for @createClientAddressDetected.
  ///
  /// In en, this message translates to:
  /// **'Address detected and auto-filled'**
  String get createClientAddressDetected;

  /// No description provided for @createClientSelectRegionError.
  ///
  /// In en, this message translates to:
  /// **'Please select a region'**
  String get createClientSelectRegionError;

  /// No description provided for @createClientSelectTypeError.
  ///
  /// In en, this message translates to:
  /// **'Please select a trade point type'**
  String get createClientSelectTypeError;

  /// No description provided for @createClientLocationError.
  ///
  /// In en, this message translates to:
  /// **'Location data not found'**
  String get createClientLocationError;

  /// No description provided for @createClientUserCodeError.
  ///
  /// In en, this message translates to:
  /// **'User code not found'**
  String get createClientUserCodeError;

  /// No description provided for @createClientUnknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get createClientUnknownError;

  /// No description provided for @labelTradingPointType.
  ///
  /// In en, this message translates to:
  /// **'Trading Point Type'**
  String get labelTradingPointType;

  /// No description provided for @labelBusinessRegion.
  ///
  /// In en, this message translates to:
  /// **'Business Region'**
  String get labelBusinessRegion;

  /// No description provided for @labelStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get labelStatus;

  /// No description provided for @labelDateRange.
  ///
  /// In en, this message translates to:
  /// **'Date Range'**
  String get labelDateRange;

  /// No description provided for @labelClients.
  ///
  /// In en, this message translates to:
  /// **'Clients'**
  String get labelClients;

  /// No description provided for @refusalReasonTitle.
  ///
  /// In en, this message translates to:
  /// **'Refusal Reason'**
  String get refusalReasonTitle;

  /// No description provided for @selectRefusalReasonFor.
  ///
  /// In en, this message translates to:
  /// **'Select refusal reason for {name}:'**
  String selectRefusalReasonFor(String name);

  /// No description provided for @businessRegionLabel.
  ///
  /// In en, this message translates to:
  /// **'Business Region: {region}'**
  String businessRegionLabel(String region);

  /// No description provided for @contactLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact: {contact}'**
  String contactLabel(String contact);

  /// No description provided for @innLabel.
  ///
  /// In en, this message translates to:
  /// **'INN'**
  String innLabel(String inn);

  /// No description provided for @ownerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner: {owner}'**
  String ownerLabel(String owner);

  /// No description provided for @responsiblePersonLabel.
  ///
  /// In en, this message translates to:
  /// **'Responsible: {responsible}'**
  String responsiblePersonLabel(String responsible);

  /// No description provided for @responsiblePersonPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Responsible Phone: {phone}'**
  String responsiblePersonPhoneLabel(String phone);

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type: {type}'**
  String typeLabel(String type);

  /// No description provided for @regionDistrictLabel.
  ///
  /// In en, this message translates to:
  /// **'{region}, {district}'**
  String regionDistrictLabel(String region, String district);

  /// No description provided for @signboardLabel.
  ///
  /// In en, this message translates to:
  /// **'Signboard: {signboard}'**
  String signboardLabel(String signboard);

  /// No description provided for @landmarkLabel.
  ///
  /// In en, this message translates to:
  /// **'Landmark: {landmark}'**
  String landmarkLabel(String landmark);

  /// No description provided for @waitingForLocation.
  ///
  /// In en, this message translates to:
  /// **'Waiting for location data...'**
  String get waitingForLocation;

  /// No description provided for @visitCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Visit Completed'**
  String get visitCompletedTitle;

  /// No description provided for @stepsCompletedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} steps completed'**
  String stepsCompletedCount(int count);

  /// No description provided for @returnToHome.
  ///
  /// In en, this message translates to:
  /// **'Return to Home'**
  String get returnToHome;

  /// No description provided for @completedAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed: {date}'**
  String completedAtLabel(String date);

  /// No description provided for @orderCaption.
  ///
  /// In en, this message translates to:
  /// **'Order {id}'**
  String orderCaption(String id);

  /// No description provided for @maxQuantityMessage.
  ///
  /// In en, this message translates to:
  /// **'Max quantity: {stock} pcs'**
  String maxQuantityMessage(int stock);

  /// No description provided for @productPriceZeroError.
  ///
  /// In en, this message translates to:
  /// **'Cannot add product with price 0 or less'**
  String get productPriceZeroError;

  /// No description provided for @quantityUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating quantity'**
  String get quantityUpdateError;

  /// No description provided for @confirmationError.
  ///
  /// In en, this message translates to:
  /// **'Error confirming selection'**
  String get confirmationError;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @productSelectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Product Selection'**
  String get productSelectionTitle;

  /// No description provided for @productsSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products selected'**
  String productsSelectedCount(int count);

  /// No description provided for @noProductsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No products available'**
  String get noProductsAvailable;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @totalProductsCount.
  ///
  /// In en, this message translates to:
  /// **'Total products: {count}'**
  String totalProductsCount(int count);

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount: {amount}'**
  String totalAmount(String amount);

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'Error occurred'**
  String errorOccurred(String error);

  /// No description provided for @cameraPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Camera permission denied'**
  String get cameraPermissionDenied;

  /// No description provided for @cameraInitError.
  ///
  /// In en, this message translates to:
  /// **'Error initializing camera: {error}'**
  String cameraInitError(String error);

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'Camera error: {error}'**
  String cameraError(String error);

  /// No description provided for @cameraInUseMessage.
  ///
  /// In en, this message translates to:
  /// **'Camera is being used by another app. Attempting to reconnect...'**
  String get cameraInUseMessage;

  /// No description provided for @imageSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image saved successfully'**
  String get imageSavedSuccessfully;

  /// No description provided for @imageSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving image: {error}'**
  String imageSaveError(String error);

  /// No description provided for @cameraNotReady.
  ///
  /// In en, this message translates to:
  /// **'Camera not ready'**
  String get cameraNotReady;

  /// No description provided for @cameraNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Camera not available or not working'**
  String get cameraNotAvailable;

  /// No description provided for @imageCounter.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total}'**
  String imageCounter(int current, int total);

  /// No description provided for @imageCapturedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Image captured successfully'**
  String get imageCapturedSuccessfully;

  /// No description provided for @imageCaptureError.
  ///
  /// In en, this message translates to:
  /// **'Error capturing image: {error}'**
  String imageCaptureError(String error);

  /// No description provided for @xmlRequestLabel.
  ///
  /// In en, this message translates to:
  /// **'XML Request'**
  String get xmlRequestLabel;

  /// No description provided for @xmlCopied.
  ///
  /// In en, this message translates to:
  /// **'XML copied'**
  String get xmlCopied;

  /// No description provided for @enterNumberHint.
  ///
  /// In en, this message translates to:
  /// **'Enter number'**
  String get enterNumberHint;

  /// No description provided for @balanceStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Balance Status'**
  String get balanceStatusTitle;

  /// No description provided for @productNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'Product information not found: {code}'**
  String productNotFoundMessage(String code);

  /// No description provided for @clientCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'New client created successfully!'**
  String get clientCreatedSuccessfully;

  /// No description provided for @callClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Call Client'**
  String get callClientTitle;

  /// No description provided for @callClientConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you want to call the client?\n{phone}'**
  String callClientConfirmation(String phone);

  /// No description provided for @dialerNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Dialer not available'**
  String get dialerNotAvailable;

  /// No description provided for @updateCoordinatesNotImplemented.
  ///
  /// In en, this message translates to:
  /// **'Update coordinates - functionality to be implemented'**
  String get updateCoordinatesNotImplemented;

  /// No description provided for @osmNotLoadedFallback.
  ///
  /// In en, this message translates to:
  /// **'OpenStreetMap not loaded. Using Google Maps.'**
  String get osmNotLoadedFallback;

  /// No description provided for @confirmLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocationTitle;

  /// No description provided for @orderDetailsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Order details not found.'**
  String get orderDetailsNotFound;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get locationPermissionDenied;

  /// No description provided for @permissionCheckError.
  ///
  /// In en, this message translates to:
  /// **'Error checking permission: {error}'**
  String permissionCheckError(String error);

  /// No description provided for @locationDetectionError.
  ///
  /// In en, this message translates to:
  /// **'Error detecting location: {error}'**
  String locationDetectionError(String error);

  /// No description provided for @userLocationNotFound.
  ///
  /// In en, this message translates to:
  /// **'User location not found'**
  String get userLocationNotFound;

  /// No description provided for @routeInfo.
  ///
  /// In en, this message translates to:
  /// **'Route: {distance} km, estimated {time}'**
  String routeInfo(String distance, String time);

  /// No description provided for @routeCreationError.
  ///
  /// In en, this message translates to:
  /// **'Error creating route: {error}'**
  String routeCreationError(String error);

  /// No description provided for @cameraMoveError.
  ///
  /// In en, this message translates to:
  /// **'Error moving camera: {error}'**
  String cameraMoveError(String error);

  /// No description provided for @permissionsCheckError.
  ///
  /// In en, this message translates to:
  /// **'Error checking permissions: {error}'**
  String permissionsCheckError(String error);

  /// No description provided for @locationUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating location...'**
  String get locationUpdating;

  /// No description provided for @clientLocationUpdated.
  ///
  /// In en, this message translates to:
  /// **'Client location updated successfully'**
  String get clientLocationUpdated;

  /// No description provided for @locationUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating location: {error}'**
  String locationUpdateError(String error);

  /// No description provided for @calculatingRoute.
  ///
  /// In en, this message translates to:
  /// **'Calculating route...'**
  String get calculatingRoute;

  /// No description provided for @regionsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading regions: {error}'**
  String regionsLoadError(String error);

  /// No description provided for @locationGetError.
  ///
  /// In en, this message translates to:
  /// **'Error getting location: {error}'**
  String locationGetError(String error);

  /// No description provided for @apiKeySavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'API key saved successfully'**
  String get apiKeySavedSuccessfully;

  /// No description provided for @minimumInterval60Minutes.
  ///
  /// In en, this message translates to:
  /// **'Minimum interval is 60 minutes'**
  String get minimumInterval60Minutes;

  /// No description provided for @pageLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading page: {error}'**
  String pageLoadError(String error);

  /// No description provided for @imageSetAsPrimary.
  ///
  /// In en, this message translates to:
  /// **'Image set as primary'**
  String get imageSetAsPrimary;

  /// No description provided for @imagesUploadedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} images uploaded successfully'**
  String imagesUploadedCount(int count);

  /// No description provided for @serverImagesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading server images: {error}'**
  String serverImagesLoadError(String error);

  /// No description provided for @gallerySelectionError.
  ///
  /// In en, this message translates to:
  /// **'Error selecting from gallery: {error}'**
  String gallerySelectionError(String error);

  /// No description provided for @cameraCaptureError.
  ///
  /// In en, this message translates to:
  /// **'Error capturing from camera: {error}'**
  String cameraCaptureError(String error);

  /// No description provided for @imagesUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Images uploaded successfully'**
  String get imagesUploadedSuccessfully;

  /// No description provided for @imagesUploadError.
  ///
  /// In en, this message translates to:
  /// **'Error uploading images: {error}'**
  String imagesUploadError(String error);

  /// No description provided for @orderDraftSaved.
  ///
  /// In en, this message translates to:
  /// **'Order Draft saved: {fileName}'**
  String orderDraftSaved(String fileName);

  /// No description provided for @tablesLabel.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get tablesLabel;

  /// No description provided for @tableColumns.
  ///
  /// In en, this message translates to:
  /// **'{tableName} columns'**
  String tableColumns(String tableName);

  /// No description provided for @orderDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Order details'**
  String get orderDetailsTitle;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @clientImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'{clientName} - Images'**
  String clientImagesTitle(String clientName);

  /// No description provided for @tradingPointImagesTitle.
  ///
  /// In en, this message translates to:
  /// **'{pointName} - Images'**
  String tradingPointImagesTitle(String pointName);

  /// No description provided for @uploadToServer.
  ///
  /// In en, this message translates to:
  /// **'Upload to Server ({count} images)'**
  String uploadToServer(int count);

  /// No description provided for @kpiDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'KPI Dashboard'**
  String get kpiDashboardTitle;

  /// No description provided for @reportSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Report Sent'**
  String get reportSentTitle;

  /// No description provided for @editFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Edit feature coming soon'**
  String get editFeatureComingSoon;

  /// No description provided for @sendPdf.
  ///
  /// In en, this message translates to:
  /// **'Send PDF'**
  String get sendPdf;

  /// No description provided for @printFeatureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Print feature coming soon'**
  String get printFeatureComingSoon;

  /// No description provided for @print.
  ///
  /// In en, this message translates to:
  /// **'Print'**
  String get print;

  /// No description provided for @stepCompleted.
  ///
  /// In en, this message translates to:
  /// **'{stepName} completed'**
  String stepCompleted(String stepName);

  /// No description provided for @stepSkip.
  ///
  /// In en, this message translates to:
  /// **'{stepName} skip'**
  String stepSkip(String stepName);

  /// No description provided for @syncWithDependencies.
  ///
  /// In en, this message translates to:
  /// **'Sync with dependencies'**
  String get syncWithDependencies;

  /// No description provided for @recommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// No description provided for @syncTableOnly.
  ///
  /// In en, this message translates to:
  /// **'Sync table only'**
  String get syncTableOnly;

  /// No description provided for @syncWarning.
  ///
  /// In en, this message translates to:
  /// **'May fail if dependencies not synced'**
  String get syncWarning;

  /// No description provided for @tableOnly.
  ///
  /// In en, this message translates to:
  /// **'Table only'**
  String get tableOnly;

  /// No description provided for @withDependencies.
  ///
  /// In en, this message translates to:
  /// **'With dependencies'**
  String get withDependencies;

  /// No description provided for @syncEntireGroup.
  ///
  /// In en, this message translates to:
  /// **'Sync Entire Group'**
  String get syncEntireGroup;

  /// No description provided for @statusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get statusNew;

  /// No description provided for @retail.
  ///
  /// In en, this message translates to:
  /// **'Retail'**
  String get retail;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @previousStepsMustBeCompleted.
  ///
  /// In en, this message translates to:
  /// **'Previous steps must be completed'**
  String get previousStepsMustBeCompleted;

  /// No description provided for @reload.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reload;

  /// No description provided for @imageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Image deleted'**
  String get imageDeleted;

  /// No description provided for @imageDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting image: {error}'**
  String imageDeleteError(String error);

  /// No description provided for @deleteImageTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Image'**
  String get deleteImageTitle;

  /// No description provided for @deleteImageConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this image?'**
  String get deleteImageConfirmation;

  /// No description provided for @photoAfterTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo AFTER (Facing correction)'**
  String get photoAfterTitle;

  /// No description provided for @photoBeforeTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo BEFORE (Facing correction)'**
  String get photoBeforeTitle;

  /// No description provided for @photosNotLoadedYet.
  ///
  /// In en, this message translates to:
  /// **'Photos not loaded yet'**
  String get photosNotLoadedYet;

  /// No description provided for @timeUnknown.
  ///
  /// In en, this message translates to:
  /// **'Time unknown'**
  String get timeUnknown;

  /// No description provided for @unitOfMeasure.
  ///
  /// In en, this message translates to:
  /// **'Unit of Measure'**
  String get unitOfMeasure;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @series.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get series;

  /// No description provided for @barcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get barcode;

  /// No description provided for @vendorCode.
  ///
  /// In en, this message translates to:
  /// **'Vendor Code'**
  String get vendorCode;

  /// No description provided for @warehouseInformation.
  ///
  /// In en, this message translates to:
  /// **'Warehouse Information'**
  String get warehouseInformation;

  /// No description provided for @reserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get reserved;

  /// No description provided for @physicalProperties.
  ///
  /// In en, this message translates to:
  /// **'Physical Properties'**
  String get physicalProperties;

  /// No description provided for @weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weight;

  /// No description provided for @volume.
  ///
  /// In en, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @productsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Products not found'**
  String get productsNotFound;

  /// No description provided for @bonusesNotFound.
  ///
  /// In en, this message translates to:
  /// **'Bonuses not found'**
  String get bonusesNotFound;

  /// No description provided for @classInformationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Class information not found'**
  String get classInformationNotFound;

  /// No description provided for @searchResultsNotFound.
  ///
  /// In en, this message translates to:
  /// **'Search results not found'**
  String get searchResultsNotFound;

  /// No description provided for @promotionConditions.
  ///
  /// In en, this message translates to:
  /// **'Promotion Conditions'**
  String get promotionConditions;

  /// No description provided for @minimalProductCount.
  ///
  /// In en, this message translates to:
  /// **'Minimal product count: {count}'**
  String minimalProductCount(int count);

  /// No description provided for @bonusCount.
  ///
  /// In en, this message translates to:
  /// **'Bonus count: {count}'**
  String bonusCount(int count);

  /// No description provided for @readOnlyMode.
  ///
  /// In en, this message translates to:
  /// **'Read Only'**
  String get readOnlyMode;

  /// No description provided for @shelfAuditTitle.
  ///
  /// In en, this message translates to:
  /// **'Shelf Audit (Remains)'**
  String get shelfAuditTitle;

  /// No description provided for @pageInDevelopment.
  ///
  /// In en, this message translates to:
  /// **'Page is currently under development'**
  String get pageInDevelopment;

  /// No description provided for @apiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'API Key: {status}'**
  String apiKeyLabel(String status);

  /// No description provided for @apiKeyConfigured.
  ///
  /// In en, this message translates to:
  /// **'Configured'**
  String get apiKeyConfigured;

  /// No description provided for @apiKeyNotRequired.
  ///
  /// In en, this message translates to:
  /// **'Key not required'**
  String get apiKeyNotRequired;

  /// No description provided for @apiKeyNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get apiKeyNotConfigured;

  /// No description provided for @editInformation.
  ///
  /// In en, this message translates to:
  /// **'Edit Information'**
  String get editInformation;

  /// No description provided for @editClientCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Edit Client Coordinates'**
  String get editClientCoordinates;

  /// No description provided for @clientPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Client Photos'**
  String get clientPhotosTitle;

  /// No description provided for @clientPhotosDescription.
  ///
  /// In en, this message translates to:
  /// **'Here are photos related to the client {name}'**
  String clientPhotosDescription(String name);

  /// No description provided for @notSent.
  ///
  /// In en, this message translates to:
  /// **'Not sent'**
  String get notSent;

  /// No description provided for @sendToServer.
  ///
  /// In en, this message translates to:
  /// **'Send to server ({count} photos)'**
  String sendToServer(int count);

  /// No description provided for @mainImage.
  ///
  /// In en, this message translates to:
  /// **'Main image'**
  String get mainImage;

  /// No description provided for @image.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get image;

  /// No description provided for @noImagesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No images available'**
  String get noImagesAvailable;

  /// No description provided for @clickPlusToAddImage.
  ///
  /// In en, this message translates to:
  /// **'Click the + button to add an image'**
  String get clickPlusToAddImage;

  /// No description provided for @setAsMainImage.
  ///
  /// In en, this message translates to:
  /// **'Set as main image'**
  String get setAsMainImage;

  /// No description provided for @clientNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Client name'**
  String get clientNameLabel;

  /// No description provided for @orderNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Order number'**
  String get orderNumberLabel;

  /// No description provided for @orderDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Order date'**
  String get orderDateLabel;

  /// No description provided for @orderTotalLabel.
  ///
  /// In en, this message translates to:
  /// **'Order total'**
  String get orderTotalLabel;

  /// No description provided for @mainStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Main status'**
  String get mainStatusLabel;

  /// No description provided for @statusCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Status code'**
  String get statusCodeLabel;

  /// No description provided for @totalProductsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total products'**
  String get totalProductsLabel;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productNameLabel;

  /// No description provided for @articleLabel.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get articleLabel;

  /// No description provided for @quantityLabel.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @priceTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Price type'**
  String get priceTypeLabel;

  /// No description provided for @noProductsInOrder.
  ///
  /// In en, this message translates to:
  /// **'No products in order'**
  String get noProductsInOrder;

  /// No description provided for @productListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Product list is empty'**
  String get productListEmpty;

  /// No description provided for @productsNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Products not selected'**
  String get productsNotSelected;

  /// No description provided for @clickPlusToAddProduct.
  ///
  /// In en, this message translates to:
  /// **'Click the + button to add a product'**
  String get clickPlusToAddProduct;

  /// No description provided for @reportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Report period'**
  String get reportPeriod;

  /// No description provided for @monthlyOKB.
  ///
  /// In en, this message translates to:
  /// **'Monthly OKB'**
  String get monthlyOKB;

  /// No description provided for @selectPeriod.
  ///
  /// In en, this message translates to:
  /// **'Select Period'**
  String get selectPeriod;

  /// No description provided for @creatingLocation.
  ///
  /// In en, this message translates to:
  /// **'Detecting...'**
  String get creatingLocation;

  /// No description provided for @locationNotFound.
  ///
  /// In en, this message translates to:
  /// **'Location not found'**
  String get locationNotFound;

  /// No description provided for @createClient.
  ///
  /// In en, this message translates to:
  /// **'Create Client'**
  String get createClient;

  /// No description provided for @swipeToRefresh.
  ///
  /// In en, this message translates to:
  /// **'Try swiping down to refresh!'**
  String get swipeToRefresh;

  /// No description provided for @ifSwipeNotWorking.
  ///
  /// In en, this message translates to:
  /// **'If swiping down doesn\'t work, perform the \"refresh all data\" action located in the settings menu'**
  String get ifSwipeNotWorking;

  /// No description provided for @imageCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{count} photos'**
  String imageCountLabel(int count);

  /// No description provided for @photosNotLoadedDescription.
  ///
  /// In en, this message translates to:
  /// **'Here are photos related to the client {clientName}'**
  String photosNotLoadedDescription(String clientName);

  /// No description provided for @totalLabel.
  ///
  /// In en, this message translates to:
  /// **'Total:'**
  String get totalLabel;

  /// No description provided for @articleLabelShort.
  ///
  /// In en, this message translates to:
  /// **'Art:'**
  String get articleLabelShort;

  /// No description provided for @availableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available:'**
  String get availableLabel;

  /// No description provided for @pieces.
  ///
  /// In en, this message translates to:
  /// **'pieces'**
  String get pieces;

  /// No description provided for @shippingDate.
  ///
  /// In en, this message translates to:
  /// **'Shipping Date'**
  String get shippingDate;

  /// No description provided for @changeShippingDate.
  ///
  /// In en, this message translates to:
  /// **'Change Shipping Date'**
  String get changeShippingDate;

  /// No description provided for @totalValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Total Value'**
  String get totalValueLabel;

  /// No description provided for @productsLabel.
  ///
  /// In en, this message translates to:
  /// **'Products'**
  String get productsLabel;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @creating.
  ///
  /// In en, this message translates to:
  /// **'Creating...'**
  String get creating;

  /// No description provided for @refreshLabel.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshLabel;

  /// No description provided for @refreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing...'**
  String get refreshing;

  /// No description provided for @changePeriod.
  ///
  /// In en, this message translates to:
  /// **'Change Period'**
  String get changePeriod;

  /// No description provided for @server.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// No description provided for @addImage.
  ///
  /// In en, this message translates to:
  /// **'Add Image'**
  String get addImage;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @deleteImage.
  ///
  /// In en, this message translates to:
  /// **'Delete Image'**
  String get deleteImage;

  /// No description provided for @deleteImageConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this image?'**
  String get deleteImageConfirm;

  /// No description provided for @noReportsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No reports available'**
  String get noReportsAvailable;

  /// No description provided for @tables.
  ///
  /// In en, this message translates to:
  /// **'Tables'**
  String get tables;

  /// No description provided for @sendPdfLabel.
  ///
  /// In en, this message translates to:
  /// **'Send PDF'**
  String get sendPdfLabel;

  /// No description provided for @warehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get warehouse;

  /// No description provided for @takePhotoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get takePhotoTooltip;

  /// No description provided for @changeShippingDateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change shipping date'**
  String get changeShippingDateTooltip;

  /// No description provided for @sendReportViaTelegram.
  ///
  /// In en, this message translates to:
  /// **'Send report via Telegram bot'**
  String get sendReportViaTelegram;

  /// No description provided for @fullscreen.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// No description provided for @updateCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Update coordinates'**
  String get updateCoordinates;

  /// No description provided for @list.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get list;

  /// No description provided for @grid.
  ///
  /// In en, this message translates to:
  /// **'Grid'**
  String get grid;

  /// No description provided for @every1Hour.
  ///
  /// In en, this message translates to:
  /// **'Every 1 hour'**
  String get every1Hour;

  /// No description provided for @every4Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 4 hours'**
  String get every4Hours;

  /// No description provided for @every6Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 6 hours'**
  String get every6Hours;

  /// No description provided for @every12Hours.
  ///
  /// In en, this message translates to:
  /// **'Every 12 hours'**
  String get every12Hours;

  /// No description provided for @daily24h.
  ///
  /// In en, this message translates to:
  /// **'Daily (24h)'**
  String get daily24h;

  /// No description provided for @weekly1Week.
  ///
  /// In en, this message translates to:
  /// **'Weekly (1 week)'**
  String get weekly1Week;

  /// No description provided for @customIntervalMinutes.
  ///
  /// In en, this message translates to:
  /// **'Custom Interval (Minutes)'**
  String get customIntervalMinutes;

  /// No description provided for @organizationLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organizationLabel;

  /// No description provided for @codeLabel2.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get codeLabel2;

  /// No description provided for @regionsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading regions...'**
  String get regionsLoading;

  /// No description provided for @cyclingRegular.
  ///
  /// In en, this message translates to:
  /// **'Regular bicycle'**
  String get cyclingRegular;

  /// No description provided for @cyclingRoad.
  ///
  /// In en, this message translates to:
  /// **'Road bicycle'**
  String get cyclingRoad;

  /// No description provided for @cyclingMountain.
  ///
  /// In en, this message translates to:
  /// **'Mountain bicycle'**
  String get cyclingMountain;

  /// No description provided for @cyclingSafe.
  ///
  /// In en, this message translates to:
  /// **'Safe bicycle'**
  String get cyclingSafe;

  /// No description provided for @productsPage.
  ///
  /// In en, this message translates to:
  /// **'Products Page'**
  String get productsPage;

  /// No description provided for @quantityHint.
  ///
  /// In en, this message translates to:
  /// **'0 to {stock}'**
  String quantityHint(int stock);

  /// No description provided for @minimum60Minutes.
  ///
  /// In en, this message translates to:
  /// **'Minimum 60 minutes'**
  String get minimum60Minutes;

  /// No description provided for @enterQuantity.
  ///
  /// In en, this message translates to:
  /// **'Enter quantity'**
  String get enterQuantity;

  /// No description provided for @maxAvailable.
  ///
  /// In en, this message translates to:
  /// **'Maximum available: {stock} pieces'**
  String maxAvailable(int stock);

  /// No description provided for @imageNumber.
  ///
  /// In en, this message translates to:
  /// **'Image {number}'**
  String imageNumber(int number);

  /// No description provided for @selectPriceType.
  ///
  /// In en, this message translates to:
  /// **'Select Price Type'**
  String get selectPriceType;

  /// No description provided for @selectPriceTypeHint.
  ///
  /// In en, this message translates to:
  /// **'Click the filter button above to select a price type from the filter panel'**
  String get selectPriceTypeHint;

  /// No description provided for @productsCount.
  ///
  /// In en, this message translates to:
  /// **'Products count: {count}'**
  String productsCount(int count);

  /// No description provided for @categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categories;

  /// No description provided for @selectBrandFirst.
  ///
  /// In en, this message translates to:
  /// **'Select brand first'**
  String get selectBrandFirst;

  /// No description provided for @reportsSection.
  ///
  /// In en, this message translates to:
  /// **'Reports section'**
  String get reportsSection;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @locationError.
  ///
  /// In en, this message translates to:
  /// **'Error getting location: {error}'**
  String locationError(String error);

  /// No description provided for @addressDetected.
  ///
  /// In en, this message translates to:
  /// **'Address detected and auto-filled'**
  String get addressDetected;

  /// No description provided for @pleaseSelectRegion.
  ///
  /// In en, this message translates to:
  /// **'Please select a region'**
  String get pleaseSelectRegion;

  /// No description provided for @pleaseSelectTradePointType.
  ///
  /// In en, this message translates to:
  /// **'Please select a trade point type'**
  String get pleaseSelectTradePointType;

  /// No description provided for @locationDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Location data not found'**
  String get locationDataNotFound;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @closeEditMode.
  ///
  /// In en, this message translates to:
  /// **'Close edit mode'**
  String get closeEditMode;

  /// No description provided for @activeClients.
  ///
  /// In en, this message translates to:
  /// **'Active clients'**
  String get activeClients;

  /// No description provided for @activeClientsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clients with active orders today'**
  String get activeClientsTooltip;

  /// No description provided for @cashless.
  ///
  /// In en, this message translates to:
  /// **'Cashless'**
  String get cashless;

  /// No description provided for @ordersTotal.
  ///
  /// In en, this message translates to:
  /// **'Total orders'**
  String get ordersTotal;

  /// No description provided for @visitedTradingPoints.
  ///
  /// In en, this message translates to:
  /// **'Visited trading points'**
  String get visitedTradingPoints;

  /// No description provided for @visitedTradingPointsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Number of visited trading points'**
  String get visitedTradingPointsTooltip;

  /// No description provided for @territoryOKB.
  ///
  /// In en, this message translates to:
  /// **'Territory OKB'**
  String get territoryOKB;

  /// No description provided for @territoryOKBTooltip.
  ///
  /// In en, this message translates to:
  /// **'Territory client base coverage'**
  String get territoryOKBTooltip;

  /// No description provided for @todayMainIndicators.
  ///
  /// In en, this message translates to:
  /// **'Today — main indicators'**
  String get todayMainIndicators;

  /// No description provided for @last7Days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get last30Days;

  /// No description provided for @monthlyPlanFactForecast.
  ///
  /// In en, this message translates to:
  /// **'Monthly Plan / Fact / Forecast'**
  String get monthlyPlanFactForecast;

  /// No description provided for @monthlyOkbAkb.
  ///
  /// In en, this message translates to:
  /// **'Monthly OKB/AKB'**
  String get monthlyOkbAkb;

  /// No description provided for @contractsNotFound.
  ///
  /// In en, this message translates to:
  /// **'No contracts found'**
  String get contractsNotFound;

  /// No description provided for @contractsListRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Contracts list refreshed'**
  String get contractsListRefreshed;

  /// No description provided for @contractAmount.
  ///
  /// In en, this message translates to:
  /// **'Contract amount'**
  String get contractAmount;

  /// No description provided for @contractDocument.
  ///
  /// In en, this message translates to:
  /// **'Contract document'**
  String get contractDocument;

  /// No description provided for @clientOrders.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s orders'**
  String clientOrders(String name);

  /// No description provided for @filterApplyError.
  ///
  /// In en, this message translates to:
  /// **'Error applying filter'**
  String get filterApplyError;

  /// No description provided for @main.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get main;

  /// No description provided for @contents.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get contents;

  /// No description provided for @mainReports.
  ///
  /// In en, this message translates to:
  /// **'Main reports'**
  String get mainReports;

  /// No description provided for @mainReportsDescription.
  ///
  /// In en, this message translates to:
  /// **'KPI indicators and main statistics'**
  String get mainReportsDescription;

  /// No description provided for @visitsReport.
  ///
  /// In en, this message translates to:
  /// **'Visits report'**
  String get visitsReport;

  /// No description provided for @visitsReportDescription.
  ///
  /// In en, this message translates to:
  /// **'Information about visits to clients'**
  String get visitsReportDescription;

  /// No description provided for @completedVisits.
  ///
  /// In en, this message translates to:
  /// **'Completed visits'**
  String get completedVisits;

  /// No description provided for @plannedVisits.
  ///
  /// In en, this message translates to:
  /// **'Planned visits'**
  String get plannedVisits;

  /// No description provided for @visitEfficiency.
  ///
  /// In en, this message translates to:
  /// **'Visit efficiency'**
  String get visitEfficiency;

  /// No description provided for @lastVisits.
  ///
  /// In en, this message translates to:
  /// **'Last visits'**
  String get lastVisits;

  /// No description provided for @dataLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading data...'**
  String get dataLoading;

  /// No description provided for @successful.
  ///
  /// In en, this message translates to:
  /// **'Successful'**
  String get successful;

  /// No description provided for @orderPlaced.
  ///
  /// In en, this message translates to:
  /// **'Order placed'**
  String get orderPlaced;

  /// No description provided for @rejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// No description provided for @reportDataRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Report data refreshed successfully'**
  String get reportDataRefreshed;

  /// No description provided for @apiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API key saved successfully'**
  String get apiKeySaved;

  /// No description provided for @saveError.
  ///
  /// In en, this message translates to:
  /// **'Save error: {error}'**
  String saveError(String error);

  /// No description provided for @userDataLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading user data: {error}'**
  String userDataLoadError(String error);

  /// No description provided for @warehouseDataLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading warehouse data: {error}'**
  String warehouseDataLoadError(String error);

  /// No description provided for @justSaved.
  ///
  /// In en, this message translates to:
  /// **'Just saved'**
  String get justSaved;

  /// No description provided for @savedMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'Saved {minutes} minutes ago'**
  String savedMinutesAgo(int minutes);

  /// No description provided for @savedHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'Saved {hours} hours ago'**
  String savedHoursAgo(int hours);

  /// No description provided for @notSaved.
  ///
  /// In en, this message translates to:
  /// **'Not saved'**
  String get notSaved;

  /// No description provided for @selectDateRange.
  ///
  /// In en, this message translates to:
  /// **'Select date range'**
  String get selectDateRange;

  /// No description provided for @selectPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Select period'**
  String get selectPeriodTitle;

  /// No description provided for @selectedPeriod.
  ///
  /// In en, this message translates to:
  /// **'Selected period'**
  String get selectedPeriod;

  /// No description provided for @selectTable.
  ///
  /// In en, this message translates to:
  /// **'Select table'**
  String get selectTable;

  /// No description provided for @selectRegionValidator.
  ///
  /// In en, this message translates to:
  /// **'Select region'**
  String get selectRegionValidator;

  /// No description provided for @selectTradePointTypeValidator.
  ///
  /// In en, this message translates to:
  /// **'Select trade point type'**
  String get selectTradePointTypeValidator;

  /// No description provided for @currentMonth.
  ///
  /// In en, this message translates to:
  /// **'Current month'**
  String get currentMonth;

  /// No description provided for @selectReportDatesHint.
  ///
  /// In en, this message translates to:
  /// **'Set start and end dates for the report'**
  String get selectReportDatesHint;

  /// No description provided for @offlineCannotRefresh.
  ///
  /// In en, this message translates to:
  /// **'Cannot refresh data in offline mode'**
  String get offlineCannotRefresh;

  /// No description provided for @distanceRequirementMessage.
  ///
  /// In en, this message translates to:
  /// **'You need to meet the distance requirement to visit {name}.'**
  String distanceRequirementMessage(String name);

  /// No description provided for @requiredDistance.
  ///
  /// In en, this message translates to:
  /// **'Required distance: {distance}m'**
  String requiredDistance(int distance);

  /// No description provided for @orderStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get orderStatusDelivered;

  /// No description provided for @orderStatusInProcess.
  ///
  /// In en, this message translates to:
  /// **'In process'**
  String get orderStatusInProcess;

  /// No description provided for @orderStatusReturn.
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get orderStatusReturn;

  /// No description provided for @orderStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get orderStatusExpired;

  /// No description provided for @contractStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get contractStatusActive;

  /// No description provided for @contractStatusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get contractStatusExpired;

  /// No description provided for @contractStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get contractStatusCancelled;

  /// No description provided for @contractStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Not approved'**
  String get contractStatusPending;

  /// No description provided for @contractStatusSuspended.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get contractStatusSuspended;

  /// No description provided for @contractTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get contractTabAll;

  /// No description provided for @appPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing app...'**
  String get appPreparing;

  /// No description provided for @permissionsChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking permissions...'**
  String get permissionsChecking;

  /// No description provided for @permissionsCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Permissions Check'**
  String get permissionsCheckTitle;

  /// No description provided for @permissionsCheckDescription.
  ///
  /// In en, this message translates to:
  /// **'The following permissions are required for the app to work properly:'**
  String get permissionsCheckDescription;

  /// No description provided for @permissionFileStorage.
  ///
  /// In en, this message translates to:
  /// **'File Storage'**
  String get permissionFileStorage;

  /// No description provided for @permissionFileStorageDesc.
  ///
  /// In en, this message translates to:
  /// **'To save data'**
  String get permissionFileStorageDesc;

  /// No description provided for @permissionLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get permissionLocation;

  /// No description provided for @permissionLocationDesc.
  ///
  /// In en, this message translates to:
  /// **'For maps and distance calculation'**
  String get permissionLocationDesc;

  /// No description provided for @permissionCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get permissionCamera;

  /// No description provided for @permissionCameraDesc.
  ///
  /// In en, this message translates to:
  /// **'To take photos'**
  String get permissionCameraDesc;

  /// No description provided for @permissionMicrophone.
  ///
  /// In en, this message translates to:
  /// **'Microphone'**
  String get permissionMicrophone;

  /// No description provided for @permissionMicrophoneDesc.
  ///
  /// In en, this message translates to:
  /// **'To record audio'**
  String get permissionMicrophoneDesc;

  /// No description provided for @permissionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get permissionNotifications;

  /// No description provided for @permissionNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'To show messages'**
  String get permissionNotificationsDesc;

  /// No description provided for @permissionAudio.
  ///
  /// In en, this message translates to:
  /// **'Music and Audio'**
  String get permissionAudio;

  /// No description provided for @permissionAudioDesc.
  ///
  /// In en, this message translates to:
  /// **'To work with audio files'**
  String get permissionAudioDesc;

  /// No description provided for @permissionPhotosVideos.
  ///
  /// In en, this message translates to:
  /// **'Photos and Videos'**
  String get permissionPhotosVideos;

  /// No description provided for @permissionPhotosVideosDesc.
  ///
  /// In en, this message translates to:
  /// **'To work with media files'**
  String get permissionPhotosVideosDesc;

  /// No description provided for @permissionsLimitedWarning.
  ///
  /// In en, this message translates to:
  /// **'Without permissions, the app will work in limited mode.'**
  String get permissionsLimitedWarning;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// No description provided for @permissionStorageTitle.
  ///
  /// In en, this message translates to:
  /// **'File Storage Permission'**
  String get permissionStorageTitle;

  /// No description provided for @permissionStorageDescAndroid13.
  ///
  /// In en, this message translates to:
  /// **'Select folder to save app data'**
  String get permissionStorageDescAndroid13;

  /// No description provided for @permissionStorageDescOther.
  ///
  /// In en, this message translates to:
  /// **'To save and load app data'**
  String get permissionStorageDescOther;

  /// No description provided for @permissionStoragePurposeAndroid13.
  ///
  /// In en, this message translates to:
  /// **'Select a folder to save photos, documents and data'**
  String get permissionStoragePurposeAndroid13;

  /// No description provided for @permissionStoragePurposeOther.
  ///
  /// In en, this message translates to:
  /// **'To save photos, documents and data'**
  String get permissionStoragePurposeOther;

  /// No description provided for @permissionLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Location Permission'**
  String get permissionLocationTitle;

  /// No description provided for @permissionLocationDescription.
  ///
  /// In en, this message translates to:
  /// **'To sort trading points by distance'**
  String get permissionLocationDescription;

  /// No description provided for @permissionLocationPurpose.
  ///
  /// In en, this message translates to:
  /// **'To show location on map and calculate distance'**
  String get permissionLocationPurpose;

  /// No description provided for @permissionLocationAlwaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Background Location Permission'**
  String get permissionLocationAlwaysTitle;

  /// No description provided for @permissionLocationAlwaysDescription.
  ///
  /// In en, this message translates to:
  /// **'To detect location when app is in background'**
  String get permissionLocationAlwaysDescription;

  /// No description provided for @permissionLocationAlwaysPurpose.
  ///
  /// In en, this message translates to:
  /// **'Background service and notifications'**
  String get permissionLocationAlwaysPurpose;

  /// No description provided for @permissionCameraTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera Permission'**
  String get permissionCameraTitle;

  /// No description provided for @permissionCameraDescription.
  ///
  /// In en, this message translates to:
  /// **'To take photos and scan barcodes'**
  String get permissionCameraDescription;

  /// No description provided for @permissionCameraPurpose.
  ///
  /// In en, this message translates to:
  /// **'To photograph products and trading points'**
  String get permissionCameraPurpose;

  /// No description provided for @permissionMicrophoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone Permission'**
  String get permissionMicrophoneTitle;

  /// No description provided for @permissionMicrophoneDescription.
  ///
  /// In en, this message translates to:
  /// **'For voice recording and audio messages'**
  String get permissionMicrophoneDescription;

  /// No description provided for @permissionMicrophonePurpose.
  ///
  /// In en, this message translates to:
  /// **'Voice notes and audio recordings'**
  String get permissionMicrophonePurpose;

  /// No description provided for @permissionNotificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Permission'**
  String get permissionNotificationTitle;

  /// No description provided for @permissionNotificationDescription.
  ///
  /// In en, this message translates to:
  /// **'To show important messages'**
  String get permissionNotificationDescription;

  /// No description provided for @permissionNotificationPurpose.
  ///
  /// In en, this message translates to:
  /// **'Reminders, news and notifications'**
  String get permissionNotificationPurpose;

  /// No description provided for @permissionAudioTitle.
  ///
  /// In en, this message translates to:
  /// **'Music and Audio Permission'**
  String get permissionAudioTitle;

  /// No description provided for @permissionAudioDescription.
  ///
  /// In en, this message translates to:
  /// **'To work with audio files'**
  String get permissionAudioDescription;

  /// No description provided for @permissionAudioPurpose.
  ///
  /// In en, this message translates to:
  /// **'Music, audio messages and voice files'**
  String get permissionAudioPurpose;

  /// No description provided for @permissionPhotosVideosTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos and Videos Permission'**
  String get permissionPhotosVideosTitle;

  /// No description provided for @permissionPhotosVideosDescription.
  ///
  /// In en, this message translates to:
  /// **'To work with media files'**
  String get permissionPhotosVideosDescription;

  /// No description provided for @permissionPhotosVideosPurpose.
  ///
  /// In en, this message translates to:
  /// **'Photos, videos and media files'**
  String get permissionPhotosVideosPurpose;

  /// No description provided for @permissionRequired.
  ///
  /// In en, this message translates to:
  /// **'{permission} required'**
  String permissionRequired(String permission);

  /// No description provided for @permissionRequiredSettings.
  ///
  /// In en, this message translates to:
  /// **'{description}. Please grant permission in app settings.'**
  String permissionRequiredSettings(String description);

  /// No description provided for @laterButton.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get laterButton;

  /// No description provided for @goToSettings.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings'**
  String get goToSettings;

  /// No description provided for @permissionPurpose.
  ///
  /// In en, this message translates to:
  /// **'Purpose: {purpose}'**
  String permissionPurpose(String purpose);

  /// No description provided for @allowPermissionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Would you like to grant permission?'**
  String get allowPermissionQuestion;

  /// No description provided for @grantPermission.
  ///
  /// In en, this message translates to:
  /// **'Grant Permission'**
  String get grantPermission;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checking;

  /// No description provided for @initializingSyncEngine.
  ///
  /// In en, this message translates to:
  /// **'Initializing sync engine...'**
  String get initializingSyncEngine;

  /// No description provided for @dataSynchronization.
  ///
  /// In en, this message translates to:
  /// **'Data Synchronization'**
  String get dataSynchronization;

  /// No description provided for @tablesSynced.
  ///
  /// In en, this message translates to:
  /// **'{synced} of {total} tables synced'**
  String tablesSynced(int synced, int total);

  /// No description provided for @syncAllData.
  ///
  /// In en, this message translates to:
  /// **'Sync All Data'**
  String get syncAllData;

  /// No description provided for @syncAllTablesInOrder.
  ///
  /// In en, this message translates to:
  /// **'This will sync all tables in dependency order'**
  String get syncAllTablesInOrder;

  /// No description provided for @dataGroups.
  ///
  /// In en, this message translates to:
  /// **'Data Groups'**
  String get dataGroups;

  /// No description provided for @backgroundAutoSync.
  ///
  /// In en, this message translates to:
  /// **'Background Auto-Sync'**
  String get backgroundAutoSync;

  /// No description provided for @backgroundSyncDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep your data fresh even when the app is closed. Requires internet connection.'**
  String get backgroundSyncDescription;

  /// No description provided for @syncInterval.
  ///
  /// In en, this message translates to:
  /// **'Sync Interval'**
  String get syncInterval;

  /// No description provided for @customIntervalNote.
  ///
  /// In en, this message translates to:
  /// **'* Custom interval takes priority if set to 60 or more'**
  String get customIntervalNote;

  /// No description provided for @clientBalanceCache.
  ///
  /// In en, this message translates to:
  /// **'Client Balance Cache'**
  String get clientBalanceCache;

  /// No description provided for @clientBalancesCached.
  ///
  /// In en, this message translates to:
  /// **'{count} client balances cached'**
  String clientBalancesCached(int count);

  /// No description provided for @balanceCacheDescription.
  ///
  /// In en, this message translates to:
  /// **'Client balance data is stored in local cache. You can clear the cache if the data is outdated.'**
  String get balanceCacheDescription;

  /// No description provided for @clearing.
  ///
  /// In en, this message translates to:
  /// **'Clearing...'**
  String get clearing;

  /// No description provided for @clearCache.
  ///
  /// In en, this message translates to:
  /// **'Clear Cache'**
  String get clearCache;

  /// No description provided for @backgroundSyncEnabled.
  ///
  /// In en, this message translates to:
  /// **'Background sync enabled'**
  String get backgroundSyncEnabled;

  /// No description provided for @backgroundSyncDisabled.
  ///
  /// In en, this message translates to:
  /// **'Background sync disabled'**
  String get backgroundSyncDisabled;

  /// No description provided for @minimumIntervalIs60.
  ///
  /// In en, this message translates to:
  /// **'Minimum interval is 60 minutes'**
  String get minimumIntervalIs60;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgo(int days);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks ago'**
  String weeksAgo(int weeks);

  /// No description provided for @unknownProduct.
  ///
  /// In en, this message translates to:
  /// **'Unknown product'**
  String get unknownProduct;

  /// No description provided for @errorOccurredTitle.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurredTitle;

  /// No description provided for @akbClientReport.
  ///
  /// In en, this message translates to:
  /// **'AKB clients report'**
  String get akbClientReport;

  /// No description provided for @akbClients.
  ///
  /// In en, this message translates to:
  /// **'AKB clients'**
  String get akbClients;

  /// No description provided for @akbPercentage.
  ///
  /// In en, this message translates to:
  /// **'AKB percentage'**
  String get akbPercentage;

  /// No description provided for @akbClientsList.
  ///
  /// In en, this message translates to:
  /// **'AKB clients list'**
  String get akbClientsList;

  /// No description provided for @daysAgoShort.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String daysAgoShort(int days);

  /// No description provided for @locationPermissionNeeded.
  ///
  /// In en, this message translates to:
  /// **'Location permission required'**
  String get locationPermissionNeeded;

  /// No description provided for @locationPermissionRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'Your location is needed to sort trading points by distance and display on the map. Do you allow?'**
  String get locationPermissionRequestMessage;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @locationSettingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Location permission is required for sorting by distance and map functions. Please grant location permission from app settings.'**
  String get locationSettingsMessage;

  /// No description provided for @enableLocationServicesMessage.
  ///
  /// In en, this message translates to:
  /// **'Location services must be enabled for sorting by distance and map functions. Please enable location services.'**
  String get enableLocationServicesMessage;

  /// No description provided for @locationSettings.
  ///
  /// In en, this message translates to:
  /// **'Location settings'**
  String get locationSettings;

  /// No description provided for @dataRefreshError.
  ///
  /// In en, this message translates to:
  /// **'Error refreshing data'**
  String get dataRefreshError;

  /// No description provided for @dateFromTo.
  ///
  /// In en, this message translates to:
  /// **'{start} to {end}'**
  String dateFromTo(String start, String end);

  /// No description provided for @akbByRegions.
  ///
  /// In en, this message translates to:
  /// **'AKB by regions'**
  String get akbByRegions;

  /// No description provided for @akbByProductCategories.
  ///
  /// In en, this message translates to:
  /// **'AKB by product categories'**
  String get akbByProductCategories;

  /// No description provided for @tradingPointAbbr.
  ///
  /// In en, this message translates to:
  /// **'t.p.'**
  String get tradingPointAbbr;

  /// No description provided for @footerNoteText.
  ///
  /// In en, this message translates to:
  /// **'Data imported from Telegram report. You can change the text to switch to a new source — UI will be updated.'**
  String get footerNoteText;

  /// No description provided for @syncStepCheckingUser.
  ///
  /// In en, this message translates to:
  /// **'Checking user...'**
  String get syncStepCheckingUser;

  /// No description provided for @syncStepClearingData.
  ///
  /// In en, this message translates to:
  /// **'Clearing old data...'**
  String get syncStepClearingData;

  /// No description provided for @syncStepSyncingKpi.
  ///
  /// In en, this message translates to:
  /// **'Loading KPI data...'**
  String get syncStepSyncingKpi;

  /// No description provided for @syncStepSyncingClients.
  ///
  /// In en, this message translates to:
  /// **'Loading clients list...'**
  String get syncStepSyncingClients;

  /// No description provided for @syncStepSyncingProducts.
  ///
  /// In en, this message translates to:
  /// **'Loading products...'**
  String get syncStepSyncingProducts;

  /// No description provided for @syncStepSyncingPriceTypes.
  ///
  /// In en, this message translates to:
  /// **'Loading price types...'**
  String get syncStepSyncingPriceTypes;

  /// No description provided for @syncStepSyncingBusinessRegions.
  ///
  /// In en, this message translates to:
  /// **'Loading business regions...'**
  String get syncStepSyncingBusinessRegions;

  /// No description provided for @syncStepSyncingUserWarehouses.
  ///
  /// In en, this message translates to:
  /// **'Loading user warehouses...'**
  String get syncStepSyncingUserWarehouses;

  /// No description provided for @syncStepSyncingProductPrices.
  ///
  /// In en, this message translates to:
  /// **'Loading product prices...'**
  String get syncStepSyncingProductPrices;

  /// No description provided for @syncStepSyncingProductBalances.
  ///
  /// In en, this message translates to:
  /// **'Loading product balances...'**
  String get syncStepSyncingProductBalances;

  /// No description provided for @syncStepSyncingClientContracts.
  ///
  /// In en, this message translates to:
  /// **'Loading client contracts...'**
  String get syncStepSyncingClientContracts;

  /// No description provided for @syncStepUpdatingClientContractStatus.
  ///
  /// In en, this message translates to:
  /// **'Updating client contract statuses...'**
  String get syncStepUpdatingClientContractStatus;

  /// No description provided for @syncStepSyncingContractTypes.
  ///
  /// In en, this message translates to:
  /// **'Loading contract types...'**
  String get syncStepSyncingContractTypes;

  /// No description provided for @syncStepSyncingDistrictContracting.
  ///
  /// In en, this message translates to:
  /// **'Loading districts...'**
  String get syncStepSyncingDistrictContracting;

  /// No description provided for @syncStepSyncingOrderStatuses.
  ///
  /// In en, this message translates to:
  /// **'Loading order statuses...'**
  String get syncStepSyncingOrderStatuses;

  /// No description provided for @syncStepSyncingOrders.
  ///
  /// In en, this message translates to:
  /// **'Loading orders...'**
  String get syncStepSyncingOrders;

  /// No description provided for @syncStepSyncingSalesReqPermissions.
  ///
  /// In en, this message translates to:
  /// **'Loading agent permissions...'**
  String get syncStepSyncingSalesReqPermissions;

  /// No description provided for @syncStepSyncingPlannedRoutes.
  ///
  /// In en, this message translates to:
  /// **'Loading planned routes...'**
  String get syncStepSyncingPlannedRoutes;

  /// No description provided for @syncStepSyncingUserOrganizations.
  ///
  /// In en, this message translates to:
  /// **'Loading user organizations...'**
  String get syncStepSyncingUserOrganizations;

  /// No description provided for @syncStepSyncingUserProjects.
  ///
  /// In en, this message translates to:
  /// **'Loading user projects...'**
  String get syncStepSyncingUserProjects;

  /// No description provided for @syncStepSyncingPromotions.
  ///
  /// In en, this message translates to:
  /// **'Loading promotions...'**
  String get syncStepSyncingPromotions;

  /// No description provided for @syncStepSyncingMapTokens.
  ///
  /// In en, this message translates to:
  /// **'Loading map tokens...'**
  String get syncStepSyncingMapTokens;

  /// No description provided for @syncStepSyncingReports.
  ///
  /// In en, this message translates to:
  /// **'Loading reports...'**
  String get syncStepSyncingReports;

  /// No description provided for @syncStepSyncingThumbnails.
  ///
  /// In en, this message translates to:
  /// **'Loading images...'**
  String get syncStepSyncingThumbnails;

  /// No description provided for @syncStepCompleted.
  ///
  /// In en, this message translates to:
  /// **'Data updated!'**
  String get syncStepCompleted;

  /// No description provided for @syncStepError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get syncStepError;

  /// No description provided for @syncSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Success!'**
  String get syncSuccessTitle;

  /// No description provided for @syncUpdatingTitle.
  ///
  /// In en, this message translates to:
  /// **'Updating data...'**
  String get syncUpdatingTitle;

  /// No description provided for @syncSkippedRecent.
  ///
  /// In en, this message translates to:
  /// **'Skipped (recently synced)'**
  String get syncSkippedRecent;

  /// No description provided for @syncBackgroundContinues.
  ///
  /// In en, this message translates to:
  /// **'Sync continues in background'**
  String get syncBackgroundContinues;

  /// No description provided for @paymentRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Payment required. Please check your subscription.'**
  String get paymentRequiredError;

  /// No description provided for @authenticationError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Please login again.'**
  String get authenticationError;

  /// No description provided for @accessForbiddenError.
  ///
  /// In en, this message translates to:
  /// **'Access forbidden. You don\'t have permission.'**
  String get accessForbiddenError;

  /// No description provided for @serviceNotFoundError.
  ///
  /// In en, this message translates to:
  /// **'Service not found. Please contact support.'**
  String get serviceNotFoundError;

  /// No description provided for @serverUnavailableError.
  ///
  /// In en, this message translates to:
  /// **'Server unavailable. Please try again later.'**
  String get serverUnavailableError;

  /// No description provided for @dataUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Error updating data. Using cached data.'**
  String get dataUpdateError;

  /// No description provided for @syncStatusErrors.
  ///
  /// In en, this message translates to:
  /// **'Errors'**
  String get syncStatusErrors;

  /// No description provided for @syncStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get syncStatusSynced;

  /// No description provided for @syncStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get syncStatusPartial;

  /// No description provided for @syncStatusNotSynced.
  ///
  /// In en, this message translates to:
  /// **'Not synced'**
  String get syncStatusNotSynced;

  /// No description provided for @tablesOfTotalSynced.
  ///
  /// In en, this message translates to:
  /// **'{synced} of {total} tables synced'**
  String tablesOfTotalSynced(int synced, int total);

  /// No description provided for @tablesInThisGroup.
  ///
  /// In en, this message translates to:
  /// **'Tables in this group'**
  String get tablesInThisGroup;

  /// No description provided for @yesterdayText.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterdayText;

  /// No description provided for @neverSynced.
  ///
  /// In en, this message translates to:
  /// **'Never synced'**
  String get neverSynced;

  /// No description provided for @tableEmpty.
  ///
  /// In en, this message translates to:
  /// **'Table is empty'**
  String get tableEmpty;

  /// No description provided for @recordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} records'**
  String recordsCount(int count);

  /// No description provided for @lastSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {time}'**
  String lastSyncLabel(String time);

  /// No description provided for @syncTable.
  ///
  /// In en, this message translates to:
  /// **'Sync table'**
  String get syncTable;

  /// No description provided for @dependencies.
  ///
  /// In en, this message translates to:
  /// **'Dependencies'**
  String get dependencies;

  /// No description provided for @willCascadeTo.
  ///
  /// In en, this message translates to:
  /// **'Will cascade to'**
  String get willCascadeTo;

  /// No description provided for @tradingPointsLabel.
  ///
  /// In en, this message translates to:
  /// **'Trading points'**
  String get tradingPointsLabel;

  /// No description provided for @tradingPointsNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Trading points not available'**
  String get tradingPointsNotAvailable;

  /// No description provided for @dateRangeLabel.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRangeLabel;

  /// No description provided for @allDatesLabel.
  ///
  /// In en, this message translates to:
  /// **'All dates'**
  String get allDatesLabel;

  /// No description provided for @clearLabel.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @statusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get statusAll;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusInactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @clientContractsCount.
  ///
  /// In en, this message translates to:
  /// **'{name} client\'s contracts ({count})'**
  String clientContractsCount(String name, int count);

  /// No description provided for @refreshError.
  ///
  /// In en, this message translates to:
  /// **'Refresh error'**
  String refreshError(String error);

  /// No description provided for @dataTab.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get dataTab;

  /// No description provided for @documentTab.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentTab;

  /// No description provided for @clientLabel.
  ///
  /// In en, this message translates to:
  /// **'Client: {name}'**
  String clientLabel(String name);

  /// No description provided for @startDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start: {date}'**
  String startDateLabel(String date);

  /// No description provided for @endDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End: {date}'**
  String endDateLabel(String date);

  /// No description provided for @unknownDate.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknownDate;

  /// No description provided for @statusAndType.
  ///
  /// In en, this message translates to:
  /// **'Status and type'**
  String get statusAndType;

  /// No description provided for @typeLabel2.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel2;

  /// No description provided for @additionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional information'**
  String get additionalInfo;

  /// No description provided for @certificateLimited.
  ///
  /// In en, this message translates to:
  /// **'Certificate limited'**
  String get certificateLimited;

  /// No description provided for @yesText.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yesText;

  /// No description provided for @noText.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get noText;

  /// No description provided for @referenceNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Reference number'**
  String get referenceNumberLabel;

  /// No description provided for @certificateNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Certificate number'**
  String get certificateNumberLabel;

  /// No description provided for @passportNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Passport number'**
  String get passportNumberLabel;

  /// No description provided for @districtCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'District code'**
  String get districtCodeLabel;

  /// No description provided for @districtNameLabel.
  ///
  /// In en, this message translates to:
  /// **'District name'**
  String get districtNameLabel;

  /// No description provided for @projectCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Project code'**
  String get projectCodeLabel;

  /// No description provided for @projectFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get projectFieldLabel;

  /// No description provided for @selectProject.
  ///
  /// In en, this message translates to:
  /// **'Select project'**
  String get selectProject;

  /// No description provided for @projectRequired.
  ///
  /// In en, this message translates to:
  /// **'Project selection is required'**
  String get projectRequired;

  /// No description provided for @projectInfoTooltip.
  ///
  /// In en, this message translates to:
  /// **'Contract number will be generated based on the selected project's numbering system'**
  String get projectInfoTooltip;

  /// No description provided for @projectInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Project information'**
  String get projectInfoSection;

  /// No description provided for @creditLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get creditLabel;

  /// No description provided for @fullPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'100% payment'**
  String get fullPaymentLabel;

  /// No description provided for @uzbekLanguage.
  ///
  /// In en, this message translates to:
  /// **'Uzbek'**
  String get uzbekLanguage;

  /// No description provided for @russianLanguage.
  ///
  /// In en, this message translates to:
  /// **'Russian'**
  String get russianLanguage;

  /// No description provided for @pdfPreparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing PDF...'**
  String get pdfPreparing;

  /// No description provided for @tapToReveal.
  ///
  /// In en, this message translates to:
  /// **'Tap'**
  String get tapToReveal;

  /// No description provided for @warehousesTitle.
  ///
  /// In en, this message translates to:
  /// **'Warehouses'**
  String get warehousesTitle;

  /// No description provided for @warehousesNotFound.
  ///
  /// In en, this message translates to:
  /// **'Warehouses not found'**
  String get warehousesNotFound;

  /// No description provided for @warehousesCount.
  ///
  /// In en, this message translates to:
  /// **'Warehouses count: {count}'**
  String warehousesCount(int count);

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created: {date}'**
  String createdLabel(String date);

  /// No description provided for @updatedLabel.
  ///
  /// In en, this message translates to:
  /// **'Updated: {date}'**
  String updatedLabel(String date);

  /// No description provided for @visitCompletedToday.
  ///
  /// In en, this message translates to:
  /// **'Visit completed today'**
  String get visitCompletedToday;

  /// No description provided for @visitExpectedToday.
  ///
  /// In en, this message translates to:
  /// **'Visit expected today'**
  String get visitExpectedToday;

  /// No description provided for @visitNotPlannedToday.
  ///
  /// In en, this message translates to:
  /// **'Visit not planned today'**
  String get visitNotPlannedToday;

  /// No description provided for @visitOrderLabel.
  ///
  /// In en, this message translates to:
  /// **'Visit order: {number}'**
  String visitOrderLabel(int number);

  /// No description provided for @selectClientTitle.
  ///
  /// In en, this message translates to:
  /// **'Select client'**
  String get selectClientTitle;

  /// No description provided for @clientsAvailable.
  ///
  /// In en, this message translates to:
  /// **'{count} clients available'**
  String clientsAvailable(int count);

  /// No description provided for @searchByNameCodeInn.
  ///
  /// In en, this message translates to:
  /// **'Name, code, INN, phone, type...'**
  String get searchByNameCodeInn;

  /// No description provided for @searchInCyrillicOrLatin.
  ///
  /// In en, this message translates to:
  /// **'Search in Cyrillic or Latin'**
  String get searchInCyrillicOrLatin;

  /// No description provided for @foundCount.
  ///
  /// In en, this message translates to:
  /// **'{count} found'**
  String foundCount(int count);

  /// No description provided for @clientNotFound.
  ///
  /// In en, this message translates to:
  /// **'Client not found'**
  String get clientNotFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @confirmButton.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirmButton;

  /// No description provided for @cancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelButton;

  /// No description provided for @newContractTitle.
  ///
  /// In en, this message translates to:
  /// **'New contract'**
  String get newContractTitle;

  /// No description provided for @fillAllFields.
  ///
  /// In en, this message translates to:
  /// **'Fill in all fields'**
  String get fillAllFields;

  /// No description provided for @contractTypesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading contract types'**
  String get contractTypesLoadError;

  /// No description provided for @pleaseSelectClient.
  ///
  /// In en, this message translates to:
  /// **'Please select a client'**
  String get pleaseSelectClient;

  /// No description provided for @pleaseSelectContractType.
  ///
  /// In en, this message translates to:
  /// **'Please select a contract type'**
  String get pleaseSelectContractType;

  /// No description provided for @contractCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Contract created successfully'**
  String get contractCreatedSuccessfully;

  /// No description provided for @contractCreationError.
  ///
  /// In en, this message translates to:
  /// **'Error creating contract'**
  String get contractCreationError;

  /// No description provided for @documentInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Document information'**
  String get documentInfoSection;

  /// No description provided for @regionInfoSection.
  ///
  /// In en, this message translates to:
  /// **'Region information'**
  String get regionInfoSection;

  /// No description provided for @referenceNumberField.
  ///
  /// In en, this message translates to:
  /// **'Reference number'**
  String get referenceNumberField;

  /// No description provided for @termLabel.
  ///
  /// In en, this message translates to:
  /// **'Term'**
  String get termLabel;

  /// No description provided for @certificateNumberField.
  ///
  /// In en, this message translates to:
  /// **'Certificate number'**
  String get certificateNumberField;

  /// No description provided for @certificateUnlimitedField.
  ///
  /// In en, this message translates to:
  /// **'Certificate unlimited'**
  String get certificateUnlimitedField;

  /// No description provided for @passportNumberField.
  ///
  /// In en, this message translates to:
  /// **'Passport number'**
  String get passportNumberField;

  /// No description provided for @clientCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Client code'**
  String get clientCodeLabel;

  /// No description provided for @organizationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Organization code'**
  String get organizationCodeLabel;

  /// No description provided for @courierLabel.
  ///
  /// In en, this message translates to:
  /// **'Courier'**
  String get courierLabel;

  /// No description provided for @vehicleLabel.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicleLabel;

  /// No description provided for @licensePlateLabel.
  ///
  /// In en, this message translates to:
  /// **'License plate'**
  String get licensePlateLabel;

  /// No description provided for @supervisorCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Supervisor comment'**
  String get supervisorCommentLabel;

  /// No description provided for @logistCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Logist comment'**
  String get logistCommentLabel;

  /// No description provided for @agentCommentLabel.
  ///
  /// In en, this message translates to:
  /// **'Agent comment'**
  String get agentCommentLabel;

  /// No description provided for @networkErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your internet connection.'**
  String get networkErrorMessage;

  /// No description provided for @serverTimeoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Server connection timed out.'**
  String get serverTimeoutMessage;

  /// No description provided for @orderDetailsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading order details.'**
  String get orderDetailsLoadError;

  /// No description provided for @dataLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Data loading failed: {error}'**
  String dataLoadFailed(String error);

  /// No description provided for @brands.
  ///
  /// In en, this message translates to:
  /// **'Brands'**
  String get brands;

  /// No description provided for @fileStoragePermission.
  ///
  /// In en, this message translates to:
  /// **'File storage permission'**
  String get fileStoragePermission;

  /// No description provided for @fileStorageDescriptionAndroid13.
  ///
  /// In en, this message translates to:
  /// **'Select folder to save app data'**
  String get fileStorageDescriptionAndroid13;

  /// No description provided for @fileStorageDescription.
  ///
  /// In en, this message translates to:
  /// **'To save and load app data'**
  String get fileStorageDescription;

  /// No description provided for @fileStoragePurposeAndroid13.
  ///
  /// In en, this message translates to:
  /// **'Select folder to save images, documents and data'**
  String get fileStoragePurposeAndroid13;

  /// No description provided for @fileStoragePurpose.
  ///
  /// In en, this message translates to:
  /// **'Save images, documents and data'**
  String get fileStoragePurpose;

  /// No description provided for @locationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Location permission'**
  String get locationPermissionTitle;

  /// No description provided for @locationPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'To sort trading points by distance'**
  String get locationPermissionDescription;

  /// No description provided for @locationPermissionPurpose.
  ///
  /// In en, this message translates to:
  /// **'Show location on map and calculate distance'**
  String get locationPermissionPurpose;

  /// No description provided for @alwaysLocationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Always location permission'**
  String get alwaysLocationPermissionTitle;

  /// No description provided for @alwaysLocationPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'To detect location when app is in background'**
  String get alwaysLocationPermissionDescription;

  /// No description provided for @alwaysLocationPermissionPurpose.
  ///
  /// In en, this message translates to:
  /// **'Background service and notifications'**
  String get alwaysLocationPermissionPurpose;

  /// No description provided for @cameraPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera permission'**
  String get cameraPermissionTitle;

  /// No description provided for @cameraPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'To take photos and scan barcodes'**
  String get cameraPermissionDescription;

  /// No description provided for @cameraPermissionPurpose.
  ///
  /// In en, this message translates to:
  /// **'Take photos of products and trading points'**
  String get cameraPermissionPurpose;

  /// No description provided for @microphonePermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission'**
  String get microphonePermissionTitle;

  /// No description provided for @microphonePermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'For voice recording and audio messages'**
  String get microphonePermissionDescription;

  /// No description provided for @microphonePermissionPurpose.
  ///
  /// In en, this message translates to:
  /// **'Voice notes and audio records'**
  String get microphonePermissionPurpose;

  /// No description provided for @notificationPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification permission'**
  String get notificationPermissionTitle;

  /// No description provided for @notificationPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'To show important messages'**
  String get notificationPermissionDescription;

  /// No description provided for @notificationPermissionPurpose.
  ///
  /// In en, this message translates to:
  /// **'Reminders, news and notifications'**
  String get notificationPermissionPurpose;

  /// No description provided for @audioPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Music and audio permission'**
  String get audioPermissionTitle;

  /// No description provided for @audioPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'To work with audio files'**
  String get audioPermissionDescription;

  /// No description provided for @audioPermissionPurpose.
  ///
  /// In en, this message translates to:
  /// **'Music, audio messages and voice files'**
  String get audioPermissionPurpose;

  /// No description provided for @photosAndVideosPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Photos and videos permission'**
  String get photosAndVideosPermissionTitle;

  /// No description provided for @photosAndVideosPermissionDescription.
  ///
  /// In en, this message translates to:
  /// **'To work with media files'**
  String get photosAndVideosPermissionDescription;

  /// No description provided for @photosAndVideosPermissionPurpose.
  ///
  /// In en, this message translates to:
  /// **'Work with photos, videos and media files'**
  String get photosAndVideosPermissionPurpose;

  /// No description provided for @permissionRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'{description}. Please grant permission in app settings.'**
  String permissionRequiredMessage(String description);

  /// No description provided for @goToSettingsButton.
  ///
  /// In en, this message translates to:
  /// **'Go to settings'**
  String get goToSettingsButton;

  /// No description provided for @grantPermissionButton.
  ///
  /// In en, this message translates to:
  /// **'Grant permission'**
  String get grantPermissionButton;

  /// No description provided for @checkingPermission.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checkingPermission;

  /// No description provided for @permissionCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission check'**
  String get permissionCheckTitle;

  /// No description provided for @permissionCheckMessage.
  ///
  /// In en, this message translates to:
  /// **'The app needs the following permissions to work properly:'**
  String get permissionCheckMessage;

  /// No description provided for @permissionSaveData.
  ///
  /// In en, this message translates to:
  /// **'Save data'**
  String get permissionSaveData;

  /// No description provided for @permissionMapDistance.
  ///
  /// In en, this message translates to:
  /// **'Map and distance calculation'**
  String get permissionMapDistance;

  /// No description provided for @permissionTakePhotos.
  ///
  /// In en, this message translates to:
  /// **'Take photos'**
  String get permissionTakePhotos;

  /// No description provided for @permissionRecordVoice.
  ///
  /// In en, this message translates to:
  /// **'Record voice'**
  String get permissionRecordVoice;

  /// No description provided for @permissionShowMessages.
  ///
  /// In en, this message translates to:
  /// **'Show messages'**
  String get permissionShowMessages;

  /// No description provided for @permissionLimitedMode.
  ///
  /// In en, this message translates to:
  /// **'Without permissions the app will work in limited mode.'**
  String get permissionLimitedMode;

  /// No description provided for @purposeLabel.
  ///
  /// In en, this message translates to:
  /// **'Purpose: {purpose}'**
  String purposeLabel(String purpose);

  /// No description provided for @grantPermissionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to grant permission?'**
  String get grantPermissionQuestion;

  /// No description provided for @serviceInitError.
  ///
  /// In en, this message translates to:
  /// **'Error initializing services'**
  String get serviceInitError;

  /// No description provided for @clientInnNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Client INN not available'**
  String get clientInnNotAvailable;

  /// No description provided for @clientBalanceZero.
  ///
  /// In en, this message translates to:
  /// **'Client balance is zero.'**
  String get clientBalanceZero;

  /// No description provided for @balanceDataNotFound.
  ///
  /// In en, this message translates to:
  /// **'Balance data not found'**
  String get balanceDataNotFound;

  /// No description provided for @updatedAtTime.
  ///
  /// In en, this message translates to:
  /// **'Updated: {time}'**
  String updatedAtTime(String time);

  /// No description provided for @clientDebtorStatus.
  ///
  /// In en, this message translates to:
  /// **'Client is debtor'**
  String get clientDebtorStatus;

  /// No description provided for @overpaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Overpayment'**
  String get overpaymentStatus;

  /// No description provided for @balanceZeroStatus.
  ///
  /// In en, this message translates to:
  /// **'Balance is zero'**
  String get balanceZeroStatus;

  /// No description provided for @savingStatus.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get savingStatus;

  /// No description provided for @unsavedChangesStatus.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChangesStatus;

  /// No description provided for @offlineStatus.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineStatus;

  /// No description provided for @pendingSyncCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending sync'**
  String pendingSyncCount(int count);

  /// No description provided for @allSyncedStatus.
  ///
  /// In en, this message translates to:
  /// **'All synced'**
  String get allSyncedStatus;

  /// No description provided for @autoSaving.
  ///
  /// In en, this message translates to:
  /// **'Auto-saving...'**
  String get autoSaving;

  /// No description provided for @savingStepData.
  ///
  /// In en, this message translates to:
  /// **'Saving step data...'**
  String get savingStepData;

  /// No description provided for @mandatoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Mandatory'**
  String get mandatoryLabel;

  /// No description provided for @optionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalLabel;

  /// No description provided for @currentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentLabel;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @skippedLabel.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get skippedLabel;

  /// No description provided for @notesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes: {notes}'**
  String notesLabel(String notes);

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String reasonLabel(String reason);

  /// No description provided for @reasonHint.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reasonHint;

  /// No description provided for @syncStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting sync...'**
  String get syncStarting;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mo'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tu'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'We'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Th'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fr'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sa'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Su'**
  String get weekdaySun;

  /// No description provided for @copyLabel.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyLabel;

  /// No description provided for @reloadLabel.
  ///
  /// In en, this message translates to:
  /// **'Reload'**
  String get reloadLabel;

  /// No description provided for @refreshContractTypesAndRegions.
  ///
  /// In en, this message translates to:
  /// **'Refresh contract types and regions'**
  String get refreshContractTypesAndRegions;

  /// No description provided for @orderStatusNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get orderStatusNew;

  /// No description provided for @orderStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get orderStatusConfirmed;

  /// No description provided for @orderStatusDelivering.
  ///
  /// In en, this message translates to:
  /// **'In delivery'**
  String get orderStatusDelivering;

  /// No description provided for @orderStatusReturnRequested.
  ///
  /// In en, this message translates to:
  /// **'Return requested'**
  String get orderStatusReturnRequested;

  /// No description provided for @orderStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get orderStatusCancelled;

  /// No description provided for @orderStatusDeliveredUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Delivered, unpaid'**
  String get orderStatusDeliveredUnpaid;

  /// No description provided for @orderStatusDeliveredPartiallyPaid.
  ///
  /// In en, this message translates to:
  /// **'Delivered, partially paid'**
  String get orderStatusDeliveredPartiallyPaid;

  /// No description provided for @orderStatusUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get orderStatusUnknown;

  /// No description provided for @filterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filterTooltip;

  /// No description provided for @fullscreenTooltip.
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreenTooltip;

  /// No description provided for @refusalReasonClientNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Client not available'**
  String get refusalReasonClientNotAvailable;

  /// No description provided for @refusalReasonNoTime.
  ///
  /// In en, this message translates to:
  /// **'No time'**
  String get refusalReasonNoTime;

  /// No description provided for @refusalReasonProductNotNeeded.
  ///
  /// In en, this message translates to:
  /// **'Product not needed'**
  String get refusalReasonProductNotNeeded;

  /// No description provided for @refusalReasonPriceNotSuitable.
  ///
  /// In en, this message translates to:
  /// **'Price not suitable'**
  String get refusalReasonPriceNotSuitable;

  /// No description provided for @refusalReasonWorksWithOtherSupplier.
  ///
  /// In en, this message translates to:
  /// **'Works with other supplier'**
  String get refusalReasonWorksWithOtherSupplier;

  /// No description provided for @refusalReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other reason'**
  String get refusalReasonOther;

  /// No description provided for @apiKeyStatusConfigured.
  ///
  /// In en, this message translates to:
  /// **'configured'**
  String get apiKeyStatusConfigured;

  /// No description provided for @apiKeyStatusNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get apiKeyStatusNotConfigured;

  /// No description provided for @visited.
  ///
  /// In en, this message translates to:
  /// **'Visited'**
  String get visited;

  /// No description provided for @plannedForToday.
  ///
  /// In en, this message translates to:
  /// **'Planned for today'**
  String get plannedForToday;

  /// No description provided for @additionalInformation.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get additionalInformation;

  /// No description provided for @locationInformation.
  ///
  /// In en, this message translates to:
  /// **'Location Information'**
  String get locationInformation;

  /// No description provided for @businessInformation.
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformation;

  /// No description provided for @apiKeyStatusNotRequired.
  ///
  /// In en, this message translates to:
  /// **'key not required'**
  String get apiKeyStatusNotRequired;

  /// No description provided for @apiKeyStatusError.
  ///
  /// In en, this message translates to:
  /// **'error'**
  String get apiKeyStatusError;

  /// No description provided for @fakturaFetchCompanyData.
  ///
  /// In en, this message translates to:
  /// **'Load'**
  String get fakturaFetchCompanyData;

  /// No description provided for @fakturaRefreshCompanyData.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get fakturaRefreshCompanyData;

  /// No description provided for @fakturaEnterInn.
  ///
  /// In en, this message translates to:
  /// **'Please enter TIN number'**
  String get fakturaEnterInn;

  /// No description provided for @fakturaInvalidInnFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid TIN format. Must be 9 or 14 digits'**
  String get fakturaInvalidInnFormat;

  /// No description provided for @fakturaCompanyDataLoaded.
  ///
  /// In en, this message translates to:
  /// **'Company data successfully loaded: {companyName}'**
  String fakturaCompanyDataLoaded(String companyName);

  /// No description provided for @fakturaRegionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Region not found: {regionName}. Please select manually'**
  String fakturaRegionNotFound(String regionName);

  /// No description provided for @fakturaAuthError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error'**
  String get fakturaAuthError;

  /// No description provided for @fakturaAuthErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Authentication error. Please try again'**
  String get fakturaAuthErrorRetry;

  /// No description provided for @fakturaCompanyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Company not found. Check TIN number'**
  String get fakturaCompanyNotFound;

  /// No description provided for @fakturaInvalidRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid request. Check TIN format'**
  String get fakturaInvalidRequest;

  /// No description provided for @fakturaServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error: {statusCode}'**
  String fakturaServerError(String statusCode);

  /// No description provided for @fakturaInnEmpty.
  ///
  /// In en, this message translates to:
  /// **'TIN cannot be empty'**
  String get fakturaInnEmpty;

  /// No description provided for @fakturaTokenRefreshError.
  ///
  /// In en, this message translates to:
  /// **'Token refresh error'**
  String get fakturaTokenRefreshError;

  /// No description provided for @reportMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports menu'**
  String get reportMenuTitle;

  /// No description provided for @reportAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'Report has already been sent to your Telegram group. Do you want to send it again?'**
  String get reportAlreadySent;

  /// No description provided for @reportSentSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report sent'**
  String get reportSentSuccess;

  /// No description provided for @resendReport.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resendReport;

  /// No description provided for @toggleHeaderShow.
  ///
  /// In en, this message translates to:
  /// **'Show header'**
  String get toggleHeaderShow;

  /// No description provided for @toggleHeaderHide.
  ///
  /// In en, this message translates to:
  /// **'Hide header'**
  String get toggleHeaderHide;

  /// No description provided for @periodNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Period not selected'**
  String get periodNotSelected;

  /// No description provided for @dataSyncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing data...'**
  String get dataSyncing;

  /// No description provided for @reportsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reports updated'**
  String get reportsUpdated;

  /// No description provided for @applyButton.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get applyButton;

  /// No description provided for @reportMainEvyap.
  ///
  /// In en, this message translates to:
  /// **'Main reports(for EVYAP)'**
  String get reportMainEvyap;

  /// No description provided for @reportMainEvyapDesc.
  ///
  /// In en, this message translates to:
  /// **'KPI indicators and main statistics'**
  String get reportMainEvyapDesc;

  /// No description provided for @reportVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits report'**
  String get reportVisits;

  /// No description provided for @reportVisitsDesc.
  ///
  /// In en, this message translates to:
  /// **'Information about visits to clients'**
  String get reportVisitsDesc;

  /// No description provided for @reportAkbClient.
  ///
  /// In en, this message translates to:
  /// **'AKB Client'**
  String get reportAkbClient;

  /// No description provided for @reportAkbClientDesc.
  ///
  /// In en, this message translates to:
  /// **'Report on AKB clients'**
  String get reportAkbClientDesc;

  /// No description provided for @reportAkbSum.
  ///
  /// In en, this message translates to:
  /// **'AKB Sum'**
  String get reportAkbSum;

  /// No description provided for @reportAkbSumDesc.
  ///
  /// In en, this message translates to:
  /// **'Financial report on AKB amounts'**
  String get reportAkbSumDesc;

  /// No description provided for @reportAkbProduct.
  ///
  /// In en, this message translates to:
  /// **'AKB Product'**
  String get reportAkbProduct;

  /// No description provided for @reportAkbProductDesc.
  ///
  /// In en, this message translates to:
  /// **'Report on AKB products'**
  String get reportAkbProductDesc;

  /// No description provided for @reportCategory.
  ///
  /// In en, this message translates to:
  /// **'Category reports'**
  String get reportCategory;

  /// No description provided for @reportCategoryDesc.
  ///
  /// In en, this message translates to:
  /// **'Sales analysis by categories'**
  String get reportCategoryDesc;

  /// No description provided for @reportMonthlyResults.
  ///
  /// In en, this message translates to:
  /// **'Monthly results'**
  String get reportMonthlyResults;

  /// No description provided for @reportMonthlyResultsDesc.
  ///
  /// In en, this message translates to:
  /// **'Monthly sales results and trends'**
  String get reportMonthlyResultsDesc;

  /// No description provided for @reportMonthlyKpi.
  ///
  /// In en, this message translates to:
  /// **'Monthly KPI (salary)'**
  String get reportMonthlyKpi;

  /// No description provided for @reportMonthlyKpiDesc.
  ///
  /// In en, this message translates to:
  /// **'Monthly KPI completion and salary report'**
  String get reportMonthlyKpiDesc;

  /// No description provided for @akbAmount.
  ///
  /// In en, this message translates to:
  /// **'AKB amount'**
  String get akbAmount;

  /// No description provided for @akbProducts.
  ///
  /// In en, this message translates to:
  /// **'AKB products'**
  String get akbProducts;

  /// No description provided for @productTypes.
  ///
  /// In en, this message translates to:
  /// **'Product types'**
  String get productTypes;

  /// No description provided for @categoriesCount.
  ///
  /// In en, this message translates to:
  /// **'Categories count'**
  String get categoriesCount;

  /// No description provided for @topSelling.
  ///
  /// In en, this message translates to:
  /// **'Top selling'**
  String get topSelling;

  /// No description provided for @monthlySales.
  ///
  /// In en, this message translates to:
  /// **'Monthly sales'**
  String get monthlySales;

  /// No description provided for @monthlyGrowth.
  ///
  /// In en, this message translates to:
  /// **'Monthly growth'**
  String get monthlyGrowth;

  /// No description provided for @kpiCompletion.
  ///
  /// In en, this message translates to:
  /// **'KPI completion'**
  String get kpiCompletion;

  /// No description provided for @salaryAmount.
  ///
  /// In en, this message translates to:
  /// **'Salary amount'**
  String get salaryAmount;

  /// No description provided for @scannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Document Scanner'**
  String get scannerTitle;

  /// No description provided for @scannerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scan certificate to auto-fill form'**
  String get scannerSubtitle;

  /// No description provided for @scannerTakePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get scannerTakePhoto;

  /// No description provided for @scannerChoosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get scannerChoosePhoto;

  /// No description provided for @scannerProcessing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing document...'**
  String get scannerProcessing;

  /// No description provided for @scannerPleaseWait.
  ///
  /// In en, this message translates to:
  /// **'AI is extracting data from the image'**
  String get scannerPleaseWait;

  /// No description provided for @scannerDataExtracted.
  ///
  /// In en, this message translates to:
  /// **'{count} fields extracted successfully'**
  String scannerDataExtracted(int count);

  /// No description provided for @scannerCameraError.
  ///
  /// In en, this message translates to:
  /// **'Failed to access camera. Please check permissions'**
  String get scannerCameraError;

  /// No description provided for @scannerGalleryError.
  ///
  /// In en, this message translates to:
  /// **'Failed to access gallery. Please check permissions'**
  String get scannerGalleryError;

  /// No description provided for @scannerImageEmpty.
  ///
  /// In en, this message translates to:
  /// **'Selected image is empty or corrupted'**
  String get scannerImageEmpty;

  /// No description provided for @scannerNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error. Please check your internet connection'**
  String get scannerNetworkError;

  /// No description provided for @scannerAuthError.
  ///
  /// In en, this message translates to:
  /// **'AI service authentication failed. Please try again'**
  String get scannerAuthError;

  /// No description provided for @scannerRateLimitError.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment'**
  String get scannerRateLimitError;

  /// No description provided for @scannerNoDataExtracted.
  ///
  /// In en, this message translates to:
  /// **'Could not extract data from the document. Please try a clearer image'**
  String get scannerNoDataExtracted;

  /// No description provided for @scannerParseError.
  ///
  /// In en, this message translates to:
  /// **'Failed to process AI response. Please try again'**
  String get scannerParseError;

  /// No description provided for @scannerUnknownError.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again'**
  String get scannerUnknownError;

  /// No description provided for @scannerFormUpdated.
  ///
  /// In en, this message translates to:
  /// **'Form updated with scanned data'**
  String get scannerFormUpdated;

  /// No description provided for @scannerVerifyingWithFaktura.
  ///
  /// In en, this message translates to:
  /// **'Verifying data with Faktura.uz...'**
  String get scannerVerifyingWithFaktura;

  /// No description provided for @scannerDataVerified.
  ///
  /// In en, this message translates to:
  /// **'Data verified and updated from Faktura.uz'**
  String get scannerDataVerified;

  /// No description provided for @scannerDataMismatch.
  ///
  /// In en, this message translates to:
  /// **'{count} fields updated from Faktura.uz'**
  String scannerDataMismatch(int count);

  /// No description provided for @faqPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Regulations'**
  String get faqPageTitle;

  /// No description provided for @faqSupervisorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Supervisor duties'**
  String get faqSupervisorSubtitle;

  /// No description provided for @faqSalesRepSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sales representative regulations'**
  String get faqSalesRepSubtitle;

  /// No description provided for @faqRoleSupervisor.
  ///
  /// In en, this message translates to:
  /// **'Supervisor'**
  String get faqRoleSupervisor;

  /// No description provided for @faqRoleSalesRep.
  ///
  /// In en, this message translates to:
  /// **'Sales Representative'**
  String get faqRoleSalesRep;

  /// No description provided for @faqSectionsCount.
  ///
  /// In en, this message translates to:
  /// **'sections'**
  String get faqSectionsCount;

  /// No description provided for @faqSvGpsTitle.
  ///
  /// In en, this message translates to:
  /// **'GPS Monitoring'**
  String get faqSvGpsTitle;

  /// No description provided for @faqSvGpsMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning report (by 9:15)'**
  String get faqSvGpsMorningTitle;

  /// No description provided for @faqSvGpsMorningContent.
  ///
  /// In en, this message translates to:
  /// **'Daily by 9:15 AM, the supervisor must send a report to the work group about the status of sales representatives\' route departure.'**
  String get faqSvGpsMorningContent;

  /// No description provided for @faqSvGpsEveningTitle.
  ///
  /// In en, this message translates to:
  /// **'Evening report (by 18:00)'**
  String get faqSvGpsEveningTitle;

  /// No description provided for @faqSvGpsEveningContent.
  ///
  /// In en, this message translates to:
  /// **'By 18:00 — the final GPS report is sent at the end of the work day.'**
  String get faqSvGpsEveningContent;

  /// No description provided for @faqSvSalesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sales Report'**
  String get faqSvSalesTitle;

  /// No description provided for @faqSvSalesInterimTitle.
  ///
  /// In en, this message translates to:
  /// **'Interim report (by 13:00)'**
  String get faqSvSalesInterimTitle;

  /// No description provided for @faqSvSalesInterimContent.
  ///
  /// In en, this message translates to:
  /// **'By 13:00 — an interim report is sent with the sum and number of collected orders.'**
  String get faqSvSalesInterimContent;

  /// No description provided for @faqSvSalesFinalTitle.
  ///
  /// In en, this message translates to:
  /// **'Final report (by 18:00)'**
  String get faqSvSalesFinalTitle;

  /// No description provided for @faqSvSalesFinalContent.
  ///
  /// In en, this message translates to:
  /// **'By 18:00 — final report including: total sales for the day, number of orders, departure plan and forecast for the next day, returns report.'**
  String get faqSvSalesFinalContent;

  /// No description provided for @faqSvKpiTitle.
  ///
  /// In en, this message translates to:
  /// **'KPI and Planning'**
  String get faqSvKpiTitle;

  /// No description provided for @faqSvKpiMondayTitle.
  ///
  /// In en, this message translates to:
  /// **'Office day (Monday)'**
  String get faqSvKpiMondayTitle;

  /// No description provided for @faqSvKpiMondayContent.
  ///
  /// In en, this message translates to:
  /// **'Every Monday is an office day.'**
  String get faqSvKpiMondayContent;

  /// No description provided for @faqSvKpiAnalysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis and tasks'**
  String get faqSvKpiAnalysisTitle;

  /// No description provided for @faqSvKpiAnalysisContent.
  ///
  /// In en, this message translates to:
  /// **'Weekly results are summarized, KPI analysis is conducted, and tasks for the current week are set.'**
  String get faqSvKpiAnalysisContent;

  /// No description provided for @faqSvTravelTitle.
  ///
  /// In en, this message translates to:
  /// **'Travel Plans'**
  String get faqSvTravelTitle;

  /// No description provided for @faqSvTravelMonthlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly planning'**
  String get faqSvTravelMonthlyTitle;

  /// No description provided for @faqSvTravelMonthlyContent.
  ///
  /// In en, this message translates to:
  /// **'Monthly, on the 30th-31st, supervisors send individual Travel Plans for the next month to the regional manager.'**
  String get faqSvTravelMonthlyContent;

  /// No description provided for @faqSvTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Time Tracking'**
  String get faqSvTimeTitle;

  /// No description provided for @faqSvTimeWeeklyTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly timesheet'**
  String get faqSvTimeWeeklyTitle;

  /// No description provided for @faqSvTimeWeeklyContent.
  ///
  /// In en, this message translates to:
  /// **'The timesheet is compiled weekly (on Mondays) indicating the number of days worked by sales representatives.'**
  String get faqSvTimeWeeklyContent;

  /// No description provided for @faqSvTimeMonthlyTitle.
  ///
  /// In en, this message translates to:
  /// **'Monthly timesheet'**
  String get faqSvTimeMonthlyTitle;

  /// No description provided for @faqSvTimeMonthlyContent.
  ///
  /// In en, this message translates to:
  /// **'The final monthly timesheet is provided on the last day of the calendar month.'**
  String get faqSvTimeMonthlyContent;

  /// No description provided for @faqSvSalaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Salary and KPI'**
  String get faqSvSalaryTitle;

  /// No description provided for @faqSvSalaryKpiTitle.
  ///
  /// In en, this message translates to:
  /// **'KPI summary'**
  String get faqSvSalaryKpiTitle;

  /// No description provided for @faqSvSalaryKpiContent.
  ///
  /// In en, this message translates to:
  /// **'Monthly, from the 1st to 3rd (depending on weekends), the supervisor must summarize KPI results for the entire month.'**
  String get faqSvSalaryKpiContent;

  /// No description provided for @faqSvSalaryCalcTitle.
  ///
  /// In en, this message translates to:
  /// **'Salary calculation'**
  String get faqSvSalaryCalcTitle;

  /// No description provided for @faqSvSalaryCalcContent.
  ///
  /// In en, this message translates to:
  /// **'Prepare and submit salary calculations for EVYAP sales representatives based on achieved indicators.'**
  String get faqSvSalaryCalcContent;

  /// No description provided for @faqTpGeneralTitle.
  ///
  /// In en, this message translates to:
  /// **'General Provisions'**
  String get faqTpGeneralTitle;

  /// No description provided for @faqTpGeneralPurposeTitle.
  ///
  /// In en, this message translates to:
  /// **'Document purpose'**
  String get faqTpGeneralPurposeTitle;

  /// No description provided for @faqTpGeneralPurposeContent.
  ///
  /// In en, this message translates to:
  /// **'This regulation establishes rules for organizing and performing duties by sales representatives. The goal is to ensure discipline, transparency and efficiency.'**
  String get faqTpGeneralPurposeContent;

  /// No description provided for @faqTpHoursTitle.
  ///
  /// In en, this message translates to:
  /// **'Working Hours and Route'**
  String get faqTpHoursTitle;

  /// No description provided for @faqTpHoursScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Work schedule'**
  String get faqTpHoursScheduleTitle;

  /// No description provided for @faqTpHoursScheduleContent.
  ///
  /// In en, this message translates to:
  /// **'The work day starts at 9:00 and ends at 18:00.'**
  String get faqTpHoursScheduleContent;

  /// No description provided for @faqTpHoursRouteTitle.
  ///
  /// In en, this message translates to:
  /// **'Route departure'**
  String get faqTpHoursRouteTitle;

  /// No description provided for @faqTpHoursRouteContent.
  ///
  /// In en, this message translates to:
  /// **'The sales representative must leave for the route on time according to the approved schedule.'**
  String get faqTpHoursRouteContent;

  /// No description provided for @faqTpHoursDelayTitle.
  ///
  /// In en, this message translates to:
  /// **'Delays'**
  String get faqTpHoursDelayTitle;

  /// No description provided for @faqTpHoursDelayContent.
  ///
  /// In en, this message translates to:
  /// **'Being more than 15 minutes late without a valid reason is recorded as a violation of labor discipline.'**
  String get faqTpHoursDelayContent;

  /// No description provided for @faqTpVisitsTitle.
  ///
  /// In en, this message translates to:
  /// **'Trade Point Visits'**
  String get faqTpVisitsTitle;

  /// No description provided for @faqTpVisitsDailyTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily visits'**
  String get faqTpVisitsDailyTitle;

  /// No description provided for @faqTpVisitsDailyContent.
  ///
  /// In en, this message translates to:
  /// **'Each sales representative must visit all trade points daily according to the route.'**
  String get faqTpVisitsDailyContent;

  /// No description provided for @faqTpVisitsChangesTitle.
  ///
  /// In en, this message translates to:
  /// **'Route changes'**
  String get faqTpVisitsChangesTitle;

  /// No description provided for @faqTpVisitsChangesContent.
  ///
  /// In en, this message translates to:
  /// **'In case of route changes (client absence, point closure, etc.), notify the work chat with the reason.'**
  String get faqTpVisitsChangesContent;

  /// No description provided for @faqTpVisitsPhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Photo/video report'**
  String get faqTpVisitsPhotoTitle;

  /// No description provided for @faqTpVisitsPhotoContent.
  ///
  /// In en, this message translates to:
  /// **'For each point, a photo or video report must be provided (display, activity, order).'**
  String get faqTpVisitsPhotoContent;

  /// No description provided for @faqTpVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Video Reports (Telegram)'**
  String get faqTpVideoTitle;

  /// No description provided for @faqTpVideoMorningTitle.
  ///
  /// In en, this message translates to:
  /// **'Morning video report'**
  String get faqTpVideoMorningTitle;

  /// No description provided for @faqTpVideoMorningContent.
  ///
  /// In en, this message translates to:
  /// **'At the start of the work day (by 9:30), the sales representative must send a video message to the Telegram chat.'**
  String get faqTpVideoMorningContent;

  /// No description provided for @faqTpVideoDuringTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports during the day'**
  String get faqTpVideoDuringTitle;

  /// No description provided for @faqTpVideoDuringContent.
  ///
  /// In en, this message translates to:
  /// **'During the day, sending short video messages from trade points is encouraged — demonstrating displays, new products or activities.'**
  String get faqTpVideoDuringContent;

  /// No description provided for @faqTpVideoEndTitle.
  ///
  /// In en, this message translates to:
  /// **'End of day video report'**
  String get faqTpVideoEndTitle;

  /// No description provided for @faqTpVideoEndContent.
  ///
  /// In en, this message translates to:
  /// **'At the end of the day, a brief video report with results is recommended.'**
  String get faqTpVideoEndContent;

  /// No description provided for @faqTpReportingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reporting'**
  String get faqTpReportingTitle;

  /// No description provided for @faqTpReportingRealTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'Real-time submission'**
  String get faqTpReportingRealTimeTitle;

  /// No description provided for @faqTpReportingRealTimeContent.
  ///
  /// In en, this message translates to:
  /// **'All photos, videos and comments on the route must be sent at the time of the visit.'**
  String get faqTpReportingRealTimeContent;

  /// No description provided for @faqTpReportingConsequenceTitle.
  ///
  /// In en, this message translates to:
  /// **'Non-compliance consequences'**
  String get faqTpReportingConsequenceTitle;

  /// No description provided for @faqTpReportingConsequenceContent.
  ///
  /// In en, this message translates to:
  /// **'Failure to submit daily reports is considered as not going on the route or lack of activity.'**
  String get faqTpReportingConsequenceContent;

  /// No description provided for @faqTpResponsibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Responsibility'**
  String get faqTpResponsibilityTitle;

  /// No description provided for @faqTpResponsibilityRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Disciplinary responsibility'**
  String get faqTpResponsibilityRulesTitle;

  /// No description provided for @faqTpResponsibilityRulesContent.
  ///
  /// In en, this message translates to:
  /// **'Non-compliance with these regulations entails disciplinary responsibility in accordance with company internal rules.'**
  String get faqTpResponsibilityRulesContent;

  /// No description provided for @faqTpResponsibilityMeasuresTitle.
  ///
  /// In en, this message translates to:
  /// **'Penalty measures'**
  String get faqTpResponsibilityMeasuresTitle;

  /// No description provided for @faqTpResponsibilityMeasuresContent.
  ///
  /// In en, this message translates to:
  /// **'Responsibility measures: warning → reprimand → bonus deduction.'**
  String get faqTpResponsibilityMeasuresContent;

  /// No description provided for @productImageLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading image...'**
  String get productImageLoading;

  /// No description provided for @productImageError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get productImageError;

  /// No description provided for @productNoImage.
  ///
  /// In en, this message translates to:
  /// **'No image available'**
  String get productNoImage;

  /// No description provided for @productImageSyncProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing images: {current}/{total}'**
  String productImageSyncProgress(int current, int total);

  /// No description provided for @productImageSyncComplete.
  ///
  /// In en, this message translates to:
  /// **'Image sync complete'**
  String get productImageSyncComplete;

  /// No description provided for @productImageSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Image sync failed'**
  String get productImageSyncFailed;

  /// No description provided for @productImageTapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view full image'**
  String get productImageTapToView;

  /// No description provided for @productImageCount.
  ///
  /// In en, this message translates to:
  /// **'{count} images'**
  String productImageCount(int count);

  /// No description provided for @productBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get productBasicInfo;

  /// No description provided for @productPricingInfo.
  ///
  /// In en, this message translates to:
  /// **'Pricing Information'**
  String get productPricingInfo;

  /// No description provided for @productStockInfo.
  ///
  /// In en, this message translates to:
  /// **'Stock Information'**
  String get productStockInfo;

  /// No description provided for @productAdditionalInfo.
  ///
  /// In en, this message translates to:
  /// **'Additional Information'**
  String get productAdditionalInfo;

  /// No description provided for @productCode.
  ///
  /// In en, this message translates to:
  /// **'Product Code'**
  String get productCode;

  /// No description provided for @productVendorCode.
  ///
  /// In en, this message translates to:
  /// **'Article'**
  String get productVendorCode;

  /// No description provided for @productBarcode.
  ///
  /// In en, this message translates to:
  /// **'Barcode'**
  String get productBarcode;

  /// No description provided for @productCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get productCategory;

  /// No description provided for @productSeries.
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get productSeries;

  /// No description provided for @productPriceType.
  ///
  /// In en, this message translates to:
  /// **'Price Type'**
  String get productPriceType;

  /// No description provided for @productPrice.
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get productPrice;

  /// No description provided for @productPriceValidFrom.
  ///
  /// In en, this message translates to:
  /// **'Valid From'**
  String get productPriceValidFrom;

  /// No description provided for @productPriceValidTo.
  ///
  /// In en, this message translates to:
  /// **'Valid To'**
  String get productPriceValidTo;

  /// No description provided for @productWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Warehouse'**
  String get productWarehouse;

  /// No description provided for @productStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get productStock;

  /// No description provided for @productQuantity.
  ///
  /// In en, this message translates to:
  /// **'Total Quantity'**
  String get productQuantity;

  /// No description provided for @productReserved.
  ///
  /// In en, this message translates to:
  /// **'Reserved'**
  String get productReserved;

  /// No description provided for @productAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get productAvailable;

  /// No description provided for @productUnit.
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get productUnit;

  /// No description provided for @productWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get productWeight;

  /// No description provided for @productCapacity.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get productCapacity;

  /// No description provided for @productBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get productBrand;

  /// No description provided for @productProject.
  ///
  /// In en, this message translates to:
  /// **'Project Code'**
  String get productProject;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @productInfoCopied.
  ///
  /// In en, this message translates to:
  /// **'Product information copied'**
  String get productInfoCopied;

  /// No description provided for @checkingCache.
  ///
  /// In en, this message translates to:
  /// **'Checking cache...'**
  String get checkingCache;

  /// No description provided for @loadingFromDatabase.
  ///
  /// In en, this message translates to:
  /// **'Loading from database...'**
  String get loadingFromDatabase;

  /// No description provided for @syncingFromServer.
  ///
  /// In en, this message translates to:
  /// **'Syncing from server...'**
  String get syncingFromServer;

  /// No description provided for @databaseEmpty.
  ///
  /// In en, this message translates to:
  /// **'No orders found locally'**
  String get databaseEmpty;

  /// No description provided for @databaseEmptyDescription.
  ///
  /// In en, this message translates to:
  /// **'Would you like to sync orders from the server?'**
  String get databaseEmptyDescription;

  /// No description provided for @syncFromServer.
  ///
  /// In en, this message translates to:
  /// **'Sync from Server'**
  String get syncFromServer;

  /// No description provided for @refreshingData.
  ///
  /// In en, this message translates to:
  /// **'Refreshing data...'**
  String get refreshingData;

  /// No description provided for @dataLoadedFromCache.
  ///
  /// In en, this message translates to:
  /// **'Data loaded from cache'**
  String get dataLoadedFromCache;

  /// No description provided for @dataLoadedFromDatabase.
  ///
  /// In en, this message translates to:
  /// **'Data loaded from database'**
  String get dataLoadedFromDatabase;

  /// No description provided for @dataSyncedFromServer.
  ///
  /// In en, this message translates to:
  /// **'Orders synced successfully'**
  String get dataSyncedFromServer;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Please try again.'**
  String get syncFailed;

  /// No description provided for @noInternetForSync.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Please check your network.'**
  String get noInternetForSync;

  /// No description provided for @retrySync.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retrySync;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {time}'**
  String lastUpdated(String time);

  /// No description provided for @connectionRestored.
  ///
  /// In en, this message translates to:
  /// **'Connection restored'**
  String get connectionRestored;

  /// No description provided for @youAreOffline.
  ///
  /// In en, this message translates to:
  /// **'You are offline'**
  String get youAreOffline;

  /// No description provided for @lineTotal.
  ///
  /// In en, this message translates to:
  /// **'Line Total'**
  String get lineTotal;

  /// No description provided for @totalMismatchWarning.
  ///
  /// In en, this message translates to:
  /// **'Calculated total differs from server value'**
  String get totalMismatchWarning;

  /// No description provided for @bonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get bonus;

  /// No description provided for @unitPrice.
  ///
  /// In en, this message translates to:
  /// **'Unit Price'**
  String get unitPrice;

  /// No description provided for @orderTotalMismatch.
  ///
  /// In en, this message translates to:
  /// **'Order total mismatch detected'**
  String get orderTotalMismatch;

  /// No description provided for @accessControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Access Verification'**
  String get accessControlTitle;

  /// No description provided for @accessControlChecking.
  ///
  /// In en, this message translates to:
  /// **'Verifying access...'**
  String get accessControlChecking;

  /// No description provided for @accessControlCheckingInternet.
  ///
  /// In en, this message translates to:
  /// **'Checking internet connection...'**
  String get accessControlCheckingInternet;

  /// No description provided for @accessControlVerifyingTime.
  ///
  /// In en, this message translates to:
  /// **'Verifying time...'**
  String get accessControlVerifyingTime;

  /// No description provided for @accessControlGranted.
  ///
  /// In en, this message translates to:
  /// **'Access granted'**
  String get accessControlGranted;

  /// No description provided for @accessControlDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get accessControlDenied;

  /// No description provided for @accessExpired.
  ///
  /// In en, this message translates to:
  /// **'Access Expired'**
  String get accessExpired;

  /// No description provided for @accessExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your access period has expired. Please contact support to renew access.'**
  String get accessExpiredMessage;

  /// No description provided for @accessExpiredDate.
  ///
  /// In en, this message translates to:
  /// **'Expired on: {date}'**
  String accessExpiredDate(String date);

  /// No description provided for @accessValidUntil.
  ///
  /// In en, this message translates to:
  /// **'Valid until: {date}'**
  String accessValidUntil(String date);

  /// No description provided for @accessDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'{days} days remaining'**
  String accessDaysRemaining(int days);

  /// No description provided for @accessTimeManipulation.
  ///
  /// In en, this message translates to:
  /// **'Time Manipulation Detected'**
  String get accessTimeManipulation;

  /// No description provided for @accessTimeManipulationMessage.
  ///
  /// In en, this message translates to:
  /// **'Device time has been manipulated. Please ensure your device time is set correctly.'**
  String get accessTimeManipulationMessage;

  /// No description provided for @accessInternetRequired.
  ///
  /// In en, this message translates to:
  /// **'Internet Required'**
  String get accessInternetRequired;

  /// No description provided for @accessInternetRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Internet connection is required for first-time setup. Please connect to the internet and try again.'**
  String get accessInternetRequiredMessage;

  /// No description provided for @accessOfflineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline Mode'**
  String get accessOfflineMode;

  /// No description provided for @accessOfflineModeMessage.
  ///
  /// In en, this message translates to:
  /// **'You are using the app in offline mode. Some features may be limited.'**
  String get accessOfflineModeMessage;

  /// No description provided for @accessVerificationError.
  ///
  /// In en, this message translates to:
  /// **'Verification Error'**
  String get accessVerificationError;

  /// No description provided for @accessVerificationErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while verifying access. Please try again.'**
  String get accessVerificationErrorMessage;

  /// No description provided for @accessContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get accessContactSupport;

  /// No description provided for @accessRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get accessRetry;

  /// No description provided for @accessExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get accessExit;

  /// No description provided for @accessCheckingStatus.
  ///
  /// In en, this message translates to:
  /// **'Checking access status...'**
  String get accessCheckingStatus;

  /// No description provided for @accessWaitingForInternet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for internet connection...'**
  String get accessWaitingForInternet;

  /// No description provided for @accessVerifyingWithServer.
  ///
  /// In en, this message translates to:
  /// **'Verifying with server...'**
  String get accessVerifyingWithServer;

  /// No description provided for @accessLoadingApp.
  ///
  /// In en, this message translates to:
  /// **'Loading application...'**
  String get accessLoadingApp;

  /// No description provided for @accessWarningExpiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Access Expiring Soon'**
  String get accessWarningExpiringSoon;

  /// No description provided for @accessWarningExpiringSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'Your access will expire in {days} days. Please contact support to renew.'**
  String accessWarningExpiringSoonMessage(int days);

  /// No description provided for @accessContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get accessContinue;

  /// No description provided for @accessRemindLater.
  ///
  /// In en, this message translates to:
  /// **'Remind Later'**
  String get accessRemindLater;

  /// No description provided for @accessNoInternetOfflineCheck.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Using offline verification.'**
  String get accessNoInternetOfflineCheck;

  /// No description provided for @accessInternetRestored.
  ///
  /// In en, this message translates to:
  /// **'Internet connection restored. Verifying...'**
  String get accessInternetRestored;

  /// No description provided for @accessCleaningData.
  ///
  /// In en, this message translates to:
  /// **'Cleaning up data...'**
  String get accessCleaningData;

  /// No description provided for @accessRevoking.
  ///
  /// In en, this message translates to:
  /// **'Revoking access...'**
  String get accessRevoking;

  /// No description provided for @syncRequiredFirstTime.
  ///
  /// In en, this message translates to:
  /// **'Sync required for first login'**
  String get syncRequiredFirstTime;

  /// No description provided for @syncRecommended.
  ///
  /// In en, this message translates to:
  /// **'Data sync recommended'**
  String get syncRecommended;

  /// No description provided for @goToSyncSettings.
  ///
  /// In en, this message translates to:
  /// **'Open sync settings to update data'**
  String get goToSyncSettings;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettings;

  /// No description provided for @initialSyncRequired.
  ///
  /// In en, this message translates to:
  /// **'Data Synchronization Required'**
  String get initialSyncRequired;

  /// No description provided for @initialSyncMessage.
  ///
  /// In en, this message translates to:
  /// **'This is your first login. We need to download essential data to get started. This may take a few minutes.'**
  String get initialSyncMessage;

  /// No description provided for @dataSyncRequired.
  ///
  /// In en, this message translates to:
  /// **'Data Synchronization Required'**
  String get dataSyncRequired;

  /// No description provided for @dataSyncMessage.
  ///
  /// In en, this message translates to:
  /// **'Your local data needs to be updated. Would you like to synchronize now?'**
  String get dataSyncMessage;

  /// No description provided for @startSync.
  ///
  /// In en, this message translates to:
  /// **'Start Sync'**
  String get startSync;

  /// No description provided for @syncLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get syncLater;

  /// No description provided for @syncCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Data synchronization completed successfully!'**
  String get syncCompleteMessage;

  /// No description provided for @syncWillContinueBackground.
  ///
  /// In en, this message translates to:
  /// **'Sync will continue in the background'**
  String get syncWillContinueBackground;

  /// No description provided for @geminiApiKeyNotFound.
  ///
  /// In en, this message translates to:
  /// **'Gemini API key not configured'**
  String get geminiApiKeyNotFound;

  /// No description provided for @geminiNetworkError.
  ///
  /// In en, this message translates to:
  /// **'Network error occurred. Please check your connection'**
  String get geminiNetworkError;

  /// No description provided for @geminiAuthError.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please check your API key in settings'**
  String get geminiAuthError;

  /// No description provided for @geminiRateLimitError.
  ///
  /// In en, this message translates to:
  /// **'Rate limit exceeded. Please try again in a few minutes'**
  String get geminiRateLimitError;

  /// No description provided for @geminiServerError.
  ///
  /// In en, this message translates to:
  /// **'Server error occurred. Please try again later'**
  String get geminiServerError;

  /// No description provided for @geminiTimeoutError.
  ///
  /// In en, this message translates to:
  /// **'Request timeout. Please check your internet connection'**
  String get geminiTimeoutError;

  /// No description provided for @geminiApiKeyConfigured.
  ///
  /// In en, this message translates to:
  /// **'Gemini API key configured successfully'**
  String get geminiApiKeyConfigured;

  /// No description provided for @geminiApiKeyLabel.
  ///
  /// In en, this message translates to:
  /// **'Gemini API Key'**
  String get geminiApiKeyLabel;

  /// No description provided for @geminiApiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your Gemini API key (starts with AIza)'**
  String get geminiApiKeyHint;

  /// No description provided for @geminiApiKeyDescription.
  ///
  /// In en, this message translates to:
  /// **'Used for document scanning and AI features'**
  String get geminiApiKeyDescription;

  /// No description provided for @geminiApiKeyInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid API key format. Key should start with \'AIza\''**
  String get geminiApiKeyInvalid;

  /// No description provided for @syncOptimizedMode.
  ///
  /// In en, this message translates to:
  /// **'Optimized sync mode'**
  String get syncOptimizedMode;

  /// No description provided for @syncParallelProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing {count} tables in parallel...'**
  String syncParallelProgress(int count);

  /// No description provided for @syncDeltaMode.
  ///
  /// In en, this message translates to:
  /// **'Incremental update'**
  String get syncDeltaMode;

  /// No description provided for @syncSkippedUnchanged.
  ///
  /// In en, this message translates to:
  /// **'Skipped {count} unchanged records'**
  String syncSkippedUnchanged(int count);

  /// No description provided for @syncInserted.
  ///
  /// In en, this message translates to:
  /// **'{count} new records added'**
  String syncInserted(int count);

  /// No description provided for @syncUpdated.
  ///
  /// In en, this message translates to:
  /// **'{count} records updated'**
  String syncUpdated(int count);

  /// No description provided for @syncDeleted.
  ///
  /// In en, this message translates to:
  /// **'{count} records removed'**
  String syncDeleted(int count);

  /// No description provided for @syncLevelProgress.
  ///
  /// In en, this message translates to:
  /// **'Level {level}/{total}: {tables}'**
  String syncLevelProgress(int level, int total, String tables);

  /// No description provided for @syncCacheSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {count} duplicate API calls'**
  String syncCacheSaved(int count);

  /// No description provided for @syncOptimizedComplete.
  ///
  /// In en, this message translates to:
  /// **'Optimized sync completed in {seconds}s'**
  String syncOptimizedComplete(String seconds);

  /// No description provided for @serverConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'Server connection failed'**
  String get serverConnectionFailed;

  /// No description provided for @tryingAlternativeServer.
  ///
  /// In en, this message translates to:
  /// **'Trying alternative server...'**
  String get tryingAlternativeServer;

  /// No description provided for @connectedToAlternativeServer.
  ///
  /// In en, this message translates to:
  /// **'Connected to alternative server'**
  String get connectedToAlternativeServer;

  /// No description provided for @allServersUnavailable.
  ///
  /// In en, this message translates to:
  /// **'All servers are unavailable'**
  String get allServersUnavailable;

  /// No description provided for @checkInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Please check your internet connection'**
  String get checkInternetConnection;

  /// No description provided for @usingFallbackServer.
  ///
  /// In en, this message translates to:
  /// **'Using backup server'**
  String get usingFallbackServer;

  /// No description provided for @primaryServerRestored.
  ///
  /// In en, this message translates to:
  /// **'Primary server connection restored'**
  String get primaryServerRestored;

  /// No description provided for @serverSwitchedTo.
  ///
  /// In en, this message translates to:
  /// **'Server switched to: {url}'**
  String serverSwitchedTo(String url);

  /// No description provided for @retryingPrimaryServer.
  ///
  /// In en, this message translates to:
  /// **'Retrying primary server...'**
  String get retryingPrimaryServer;

  /// No description provided for @connectionAttempt.
  ///
  /// In en, this message translates to:
  /// **'Connection attempt {current}/{total}'**
  String connectionAttempt(int current, int total);

  /// No description provided for @serverUrlInfo.
  ///
  /// In en, this message translates to:
  /// **'Server: {name} ({type})'**
  String serverUrlInfo(String name, String type);

  /// No description provided for @primaryServer.
  ///
  /// In en, this message translates to:
  /// **'Primary'**
  String get primaryServer;

  /// No description provided for @backupServer.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backupServer;

  /// No description provided for @visitDuration.
  ///
  /// In en, this message translates to:
  /// **'Visit Duration'**
  String get visitDuration;

  /// No description provided for @stepDuration.
  ///
  /// In en, this message translates to:
  /// **'Step Duration'**
  String get stepDuration;

  /// No description provided for @totalVisitTime.
  ///
  /// In en, this message translates to:
  /// **'Total Visit Time'**
  String get totalVisitTime;

  /// No description provided for @stepTime.
  ///
  /// In en, this message translates to:
  /// **'Step Time'**
  String get stepTime;

  /// No description provided for @elapsedTime.
  ///
  /// In en, this message translates to:
  /// **'Elapsed Time'**
  String get elapsedTime;

  /// No description provided for @timeLimitExpired.
  ///
  /// In en, this message translates to:
  /// **'Access Period Expired'**
  String get timeLimitExpired;

  /// No description provided for @timeLimitExpiredMessage.
  ///
  /// In en, this message translates to:
  /// **'Your access period has expired. Please contact support to renew your access.'**
  String get timeLimitExpiredMessage;

  /// No description provided for @timeLimitExpiredNote.
  ///
  /// In en, this message translates to:
  /// **'All local data will be cleared for security.'**
  String get timeLimitExpiredNote;

  /// No description provided for @offlineAccessBlocked.
  ///
  /// In en, this message translates to:
  /// **'Internet Connection Required'**
  String get offlineAccessBlocked;

  /// No description provided for @offlineAccessBlockedMessage.
  ///
  /// In en, this message translates to:
  /// **'First-time access requires an internet connection. Please connect and try again.'**
  String get offlineAccessBlockedMessage;

  /// No description provided for @offlineAccessBlockedNote.
  ///
  /// In en, this message translates to:
  /// **'After first connection, you can use the app offline.'**
  String get offlineAccessBlockedNote;

  /// No description provided for @offlineAccessNoLimit.
  ///
  /// In en, this message translates to:
  /// **'Offline Access Unavailable'**
  String get offlineAccessNoLimit;

  /// No description provided for @offlineAccessNoLimitMessage.
  ///
  /// In en, this message translates to:
  /// **'You need to connect to the internet at least once before using offline mode.'**
  String get offlineAccessNoLimitMessage;

  /// No description provided for @retryConnection.
  ///
  /// In en, this message translates to:
  /// **'Retry Connection'**
  String get retryConnection;

  /// No description provided for @connectToInternet.
  ///
  /// In en, this message translates to:
  /// **'Connect to Internet'**
  String get connectToInternet;

  /// No description provided for @verifyingAccess.
  ///
  /// In en, this message translates to:
  /// **'Verifying access...'**
  String get verifyingAccess;

  /// No description provided for @accessVerified.
  ///
  /// In en, this message translates to:
  /// **'Access verified successfully'**
  String get accessVerified;

  /// No description provided for @verificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed'**
  String get verificationFailed;

  /// No description provided for @timeLimitUpdated.
  ///
  /// In en, this message translates to:
  /// **'Access period updated'**
  String get timeLimitUpdated;

  /// No description provided for @promoOrder.
  ///
  /// In en, this message translates to:
  /// **'Promo Order'**
  String get promoOrder;

  /// No description provided for @marketingDataRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Marketing data is refreshing...'**
  String get marketingDataRefreshing;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @news.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get news;

  /// No description provided for @announcementsPage.
  ///
  /// In en, this message translates to:
  /// **'Announcements page'**
  String get announcementsPage;

  /// No description provided for @newsPage.
  ///
  /// In en, this message translates to:
  /// **'News page'**
  String get newsPage;

  /// No description provided for @pricesPage.
  ///
  /// In en, this message translates to:
  /// **'Prices page'**
  String get pricesPage;

  /// No description provided for @dataLoadingErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error loading data: {error}'**
  String dataLoadingErrorWithMessage(String error);

  /// No description provided for @promotionsRefreshError.
  ///
  /// In en, this message translates to:
  /// **'Error refreshing promotions: {error}'**
  String promotionsRefreshError(String error);

  /// No description provided for @refreshErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Refresh error: {error}'**
  String refreshErrorWithMessage(String error);

  /// No description provided for @offlineModeShowingCachedData.
  ///
  /// In en, this message translates to:
  /// **'Offline mode - showing cached data'**
  String get offlineModeShowingCachedData;

  /// No description provided for @promotionsNotFound.
  ///
  /// In en, this message translates to:
  /// **'No promotions found'**
  String get promotionsNotFound;

  /// No description provided for @promotionDescriptionFormat.
  ///
  /// In en, this message translates to:
  /// **'{type} promotion. {productCount} products, {bonusCount} bonuses.'**
  String promotionDescriptionFormat(String type, int productCount, int bonusCount);

  /// No description provided for @aboutPromotion.
  ///
  /// In en, this message translates to:
  /// **'About promotion'**
  String get aboutPromotion;

  /// No description provided for @promotionOfType.
  ///
  /// In en, this message translates to:
  /// **'{type} type promotion'**
  String promotionOfType(String type);

  /// No description provided for @participatingProductsCount.
  ///
  /// In en, this message translates to:
  /// **'Products participating in promotion: {count} SKU'**
  String participatingProductsCount(int count);

  /// No description provided for @bonusProductsCount.
  ///
  /// In en, this message translates to:
  /// **'Products available as bonus: {count} SKU'**
  String bonusProductsCount(int count);

  /// No description provided for @bonuses.
  ///
  /// In en, this message translates to:
  /// **'Bonuses'**
  String get bonuses;

  /// No description provided for @productClass.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get productClass;

  /// No description provided for @salesChannel.
  ///
  /// In en, this message translates to:
  /// **'Sales Channel'**
  String get salesChannel;

  /// No description provided for @salesChannelRequired.
  ///
  /// In en, this message translates to:
  /// **'Sales Channel *'**
  String get salesChannelRequired;

  /// No description provided for @clientClass.
  ///
  /// In en, this message translates to:
  /// **'Client Class'**
  String get clientClass;

  /// No description provided for @clientClassRequired.
  ///
  /// In en, this message translates to:
  /// **'Client Class *'**
  String get clientClassRequired;

  /// No description provided for @tradingPointTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Trading Point Type *'**
  String get tradingPointTypeRequired;

  /// No description provided for @regionRequired.
  ///
  /// In en, this message translates to:
  /// **'Region *'**
  String get regionRequired;

  /// No description provided for @pleaseSelectSalesChannel.
  ///
  /// In en, this message translates to:
  /// **'Please select sales channel'**
  String get pleaseSelectSalesChannel;

  /// No description provided for @pleaseSelectClientClass.
  ///
  /// In en, this message translates to:
  /// **'Please select client class'**
  String get pleaseSelectClientClass;

  /// No description provided for @salesChannelsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading channels...'**
  String get salesChannelsLoading;

  /// No description provided for @clientClassesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading classes...'**
  String get clientClassesLoading;

  /// No description provided for @tradingPointTypesLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading trading point types...'**
  String get tradingPointTypesLoading;

  /// No description provided for @pleaseSelectChannelFirst.
  ///
  /// In en, this message translates to:
  /// **'Please select channel first'**
  String get pleaseSelectChannelFirst;

  /// No description provided for @tradingPointTypesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading trading point types'**
  String get tradingPointTypesLoadError;

  /// No description provided for @initialOrderSettings.
  ///
  /// In en, this message translates to:
  /// **'Initial Order Settings'**
  String get initialOrderSettings;

  /// No description provided for @initialOrderSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Please configure the following settings before creating your first order. These settings will be used as defaults for this order.'**
  String get initialOrderSettingsDescription;

  /// No description provided for @selectOrganization.
  ///
  /// In en, this message translates to:
  /// **'Select Organization'**
  String get selectOrganization;

  /// No description provided for @selectWarehouse.
  ///
  /// In en, this message translates to:
  /// **'Select Warehouse'**
  String get selectWarehouse;

  /// No description provided for @organizationRequired.
  ///
  /// In en, this message translates to:
  /// **'Organization is required'**
  String get organizationRequired;

  /// No description provided for @warehouseRequired.
  ///
  /// In en, this message translates to:
  /// **'Warehouse is required'**
  String get warehouseRequired;

  /// No description provided for @priceTypeRequired.
  ///
  /// In en, this message translates to:
  /// **'Price type is required'**
  String get priceTypeRequired;

  /// No description provided for @continueToOrder.
  ///
  /// In en, this message translates to:
  /// **'Continue to Order'**
  String get continueToOrder;

  /// No description provided for @settingsNotComplete.
  ///
  /// In en, this message translates to:
  /// **'Please complete all required settings'**
  String get settingsNotComplete;

  /// No description provided for @noOrganizationsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No organizations available'**
  String get noOrganizationsAvailable;

  /// No description provided for @noWarehousesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No warehouses available'**
  String get noWarehousesAvailable;

  /// No description provided for @noPriceTypesAvailable.
  ///
  /// In en, this message translates to:
  /// **'No price types available'**
  String get noPriceTypesAvailable;
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
