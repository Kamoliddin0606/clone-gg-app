// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Gloria Marketing';

  @override
  String get customerProjectRequired => 'Select a project';

  @override
  String get customerScopeMismatchToast => 'Configuration fixed. Retrying...';

  @override
  String get customerCodeDuplicateToast => 'Customer already exists';

  @override
  String get customerCodeDuplicateToastProject => 'Customer already exists in this project';

  @override
  String get customerNotFoundToast => 'Customer not found';

  @override
  String get activeProjectLabel => 'Active project';

  @override
  String get changeProjectAction => 'Change';

  @override
  String get projectPickerTitle => 'Select project';

  @override
  String get projectListEmpty => 'No projects found';

  @override
  String get customerListRefreshing => 'Refreshing customer list...';

  @override
  String get login => 'Login';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get welcome => 'Welcome!';

  @override
  String get enterCredentials => 'Please enter your login credentials';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get orders => 'Orders';

  @override
  String get tradingPoints => 'Trading points';

  @override
  String get tradingPointsFilter => 'Trading Points';

  @override
  String get warehouses => 'Warehouses';

  @override
  String get contracts => 'Contracts';

  @override
  String get reports => 'Reports';

  @override
  String get settings => 'Settings';

  @override
  String get marketing => 'Marketing';

  @override
  String get promotions => 'Promotions';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get activeAgents => 'Active Agents';

  @override
  String get orderCount => 'Orders';

  @override
  String get revenue => 'Revenue';

  @override
  String get logout => 'Logout';

  @override
  String get confirmLogout => 'Are you sure you want to exit the application?';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data';

  @override
  String get retry => 'Retry';

  @override
  String get search => 'Search';

  @override
  String get filter => 'Filter';

  @override
  String get dateRange => 'Date Range';

  @override
  String get allDates => 'All dates';

  @override
  String get clients => 'Clients';

  @override
  String get status => 'Status';

  @override
  String get total => 'Total';

  @override
  String get quantity => 'Quantity';

  @override
  String get price => 'Price';

  @override
  String get sum => 'Sum';

  @override
  String get currency => 'UZS';

  @override
  String get orderDate => 'Order Date';

  @override
  String get clientName => 'Client Name';

  @override
  String get items => 'Items';

  @override
  String get details => 'Details';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get close => 'Close';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get home => 'Home';

  @override
  String get profile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get system => 'System';

  @override
  String get english => 'English';

  @override
  String get russian => 'Russian';

  @override
  String get uzbek => 'Uzbek';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get settingsSaved => 'Settings saved successfully';

  @override
  String get dataSync => 'Data Synchronization';

  @override
  String get syncNow => 'Sync Now';

  @override
  String lastSync(String time) {
    return 'Last sync: $time';
  }

  @override
  String get syncing => 'Syncing...';

  @override
  String get syncComplete => 'Synchronization completed';

  @override
  String syncError(String error) {
    return 'Sync error: $error';
  }

  @override
  String get noInternet => 'No internet connection';

  @override
  String get offlineMode => 'Offline mode - cached data is displayed';

  @override
  String get onlineMode => 'Online mode';

  @override
  String get serverError => 'Server error';

  @override
  String get invalidCredentials => 'Invalid username or password';

  @override
  String get sessionExpired => 'Session expired';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get fileNotFound => 'File not found';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get tryAgain => 'Please try again';

  @override
  String get contactSupport => 'Contact Support';

  @override
  String get version => 'Version';

  @override
  String get about => 'About';

  @override
  String get help => 'Help';

  @override
  String get feedback => 'Feedback';

  @override
  String get rateApp => 'Rate the app';

  @override
  String get shareApp => 'Share the app';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get warehouseManagement => 'Warehouse Management';

  @override
  String get packingDashboard => 'Packing Dashboard';

  @override
  String get collectionDashboard => 'Collection Dashboard';

  @override
  String get bossDashboard => 'Boss Dashboard';

  @override
  String get forwarderDashboard => 'Forwarder Dashboard';

  @override
  String get agentDashboard => 'Agent Dashboard';

  @override
  String get todayProductivity => 'Today\'s Productivity';

  @override
  String get ordersProcessed => 'orders processed';

  @override
  String get totalCollected => 'Total Collected';

  @override
  String get activeCollections => 'Active Collections';

  @override
  String get pendingCollections => 'Pending Collections';

  @override
  String get collected => 'Collected';

  @override
  String get pending => 'Pending';

  @override
  String get inTransit => 'In Transit';

  @override
  String get delivered => 'Delivered';

  @override
  String get ready => 'Ready';

  @override
  String get picking => 'Picking';

  @override
  String get packed => 'Packed';

  @override
  String get completed => 'Completed';

  @override
  String get toPack => 'To Pack';

  @override
  String get inProgress => 'In Progress';

  @override
  String get lowStock => 'Low Stock';

  @override
  String get outOfStock => 'Out of Stock';

  @override
  String get receiveGoods => 'Receive Goods';

  @override
  String get issueGoods => 'Issue Goods';

  @override
  String get findItem => 'Find Item';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get warehouseCapacity => 'Warehouse Capacity';

  @override
  String get used => 'used';

  @override
  String get incoming => 'Incoming';

  @override
  String get outgoing => 'Outgoing';

  @override
  String get supplier => 'Supplier';

  @override
  String get customer => 'Customer';

  @override
  String get eta => 'ETA';

  @override
  String get due => 'Due';

  @override
  String get productDetails => 'Product Details';

  @override
  String get sku => 'SKU';

  @override
  String get location => 'Location';

  @override
  String get pcs => 'pcs';

  @override
  String get kg => 'kg';

  @override
  String get contractDetails => 'Contract details';

  @override
  String get contractCode => 'Contract Code';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get dateOfContract => 'Date of Contract';

  @override
  String get termOfContract => 'Term of Contract';

  @override
  String get contractSum => 'Contract Sum';

  @override
  String get typeOfContract => 'Type of Contract';

  @override
  String get clientCode => 'Client Code';

  @override
  String get organization => 'Organization';

  @override
  String get responsiblePerson => 'Responsible Person';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get inn => 'INN';

  @override
  String get region => 'Region';

  @override
  String get district => 'District';

  @override
  String get signboard => 'Signboard';

  @override
  String get referencePoint => 'Reference Point';

  @override
  String get tradePointType => 'Trade Point Type';

  @override
  String get ownerName => 'Owner Name';

  @override
  String get responsiblePersonPhone => 'Responsible Person Phone';

  @override
  String get visit => 'Visit';

  @override
  String get visitClient => 'Visit Client';

  @override
  String get createOrder => 'Create Order';

  @override
  String get unplannedOrder => 'Unplanned Order';

  @override
  String get viewContracts => 'View Contracts';

  @override
  String get refusal => 'Refusal';

  @override
  String get route => 'Route';

  @override
  String get refusalReason => 'Refusal Reason';

  @override
  String get selectReason => 'Select refusal reason';

  @override
  String get other => 'Other';

  @override
  String get specifyReason => 'Please specify the reason';

  @override
  String get send => 'Send';

  @override
  String get visitReported => 'Visit reported';

  @override
  String get orderCreated => 'Order created';

  @override
  String get contractViewed => 'Contract viewed';

  @override
  String get refusalSent => 'Refusal sent';

  @override
  String get locationPermission => 'Location permission';

  @override
  String get locationPermissionRequired => 'Location permission is required for this feature';

  @override
  String get requestPermission => 'Request Permission';

  @override
  String get locationServicesDisabled => 'Location services are disabled';

  @override
  String get enableLocationServices => 'Please enable location services';

  @override
  String get reportsMenu => 'Reports Menu';

  @override
  String get selectReport => 'Select Report';

  @override
  String get generateReport => 'Generate Report';

  @override
  String get exportReport => 'Export Report';

  @override
  String get reportGenerated => 'Report generated successfully';

  @override
  String get reportGenerationError => 'Error generating report';

  @override
  String get akbSum => 'AKB Sum';

  @override
  String get akbClient => 'AKB Client';

  @override
  String get akbProduct => 'AKB Product';

  @override
  String get monthlyReport => 'Monthly Report';

  @override
  String get dailyReport => 'Daily Report';

  @override
  String get salesReport => 'Sales Report';

  @override
  String get inventoryReport => 'Inventory Report';

  @override
  String get financialReport => 'Financial Report';

  @override
  String get kpiReport => 'KPI Report';

  @override
  String get cash => 'Cash';

  @override
  String get nonCash => 'Non-cash';

  @override
  String get totalOrders => 'Total Orders';

  @override
  String get visitedPoints => 'Visited Points';

  @override
  String get totalRevenue => 'Total Revenue';

  @override
  String get averageOrder => 'Average Order';

  @override
  String get growthRate => 'Growth Rate';

  @override
  String get efficiency => 'Efficiency';

  @override
  String get performance => 'Performance';

  @override
  String get targets => 'Targets';

  @override
  String get achievements => 'Achievements';

  @override
  String get plan => 'Plan';

  @override
  String get fact => 'Fact';

  @override
  String get percentage => 'Percentage';

  @override
  String get amount => 'Amount';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get duration => 'Duration';

  @override
  String get distance => 'Distance';

  @override
  String get speed => 'Speed';

  @override
  String get temperature => 'Temperature';

  @override
  String get humidity => 'Humidity';

  @override
  String get pressure => 'Pressure';

  @override
  String get wind => 'Wind';

  @override
  String get weather => 'Weather';

  @override
  String get forecast => 'Forecast';

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get thisYear => 'This Year';

  @override
  String get lastWeek => 'Last Week';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get lastYear => 'Last Year';

  @override
  String get custom => 'Custom';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get beginning => 'Beginning';

  @override
  String get finish => 'Finish';

  @override
  String get open => 'Open';

  @override
  String get closed => 'Closed';

  @override
  String get available => 'Available';

  @override
  String get unavailable => 'Unavailable';

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get on => 'On';

  @override
  String get off => 'Off';

  @override
  String get booleanTrue => 'True';

  @override
  String get booleanFalse => 'False';

  @override
  String get interfaceSettings => 'Interface Settings';

  @override
  String get languageChanged => 'Language changed successfully';

  @override
  String get restartRequired => 'Please restart the app to apply language changes';

  @override
  String get currentLanguage => 'Current Language';

  @override
  String get availableLanguages => 'Available Languages';

  @override
  String get changeLanguage => 'Change Language';

  @override
  String get languageSelection => 'Language Selection';

  @override
  String get confirmLanguageChange => 'Are you sure you want to change the language?';

  @override
  String get languageChangeWarning => 'Changing the language will restart the app';

  @override
  String get success => 'Success';

  @override
  String get prices => 'Prices';

  @override
  String get businessRegions => 'Business Regions';

  @override
  String get permissions => 'Permissions';

  @override
  String get apply => 'Apply';

  @override
  String get appearance => 'Appearance';

  @override
  String get failure => 'Failure';

  @override
  String get warning => 'Warning';

  @override
  String get info => 'Info';

  @override
  String get debug => 'Debug';

  @override
  String get trace => 'Trace';

  @override
  String get fatal => 'Fatal';

  @override
  String get critical => 'Critical';

  @override
  String get emergency => 'Emergency';

  @override
  String get notice => 'Notice';

  @override
  String get alert => 'Alert';

  @override
  String get agentPermissions => 'Agent Permissions';

  @override
  String get userPermissionsAndVisitSteps => 'User permissions and visit steps';

  @override
  String get dataValidation => 'Data Validation';

  @override
  String get visitManagement => 'Visit Management';

  @override
  String get visitSteps => 'Visit Steps';

  @override
  String get userCodeNotFound => 'User code not found';

  @override
  String get errorLoadingPermissions => 'Error loading permissions';

  @override
  String get skipTINDuplicateCheck => 'Skip TIN duplicate check';

  @override
  String get allowCreationWithoutTIN => 'Allow creation without TIN';

  @override
  String get allowCreatingPointOfSale => 'Allow creating point of sale';

  @override
  String get strictSequence => 'Strict Sequence';

  @override
  String get plannedRoute => 'Planned Route';

  @override
  String get general => 'General';

  @override
  String get mandatoryExecution => 'Mandatory Execution';

  @override
  String get optional => 'Optional';

  @override
  String get permissionsDataNotAvailable => 'Permissions data not available';

  @override
  String get languageChangeError => 'Error changing language';

  @override
  String get languageAutoDetected => 'Language auto-detected from system';

  @override
  String get customers => 'Customers';

  @override
  String get debitCredit => 'Debit-Credit';

  @override
  String get products => 'Products';

  @override
  String get dbView => 'DB View';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get kpiDataUpdateError => 'KPI data update error';

  @override
  String get onlineModeReturn => 'Return to online mode';

  @override
  String get onlineModeReturnConfirm => 'Do you want to check internet and server connection and return to online mode?';

  @override
  String get switchToOfflineTitle => 'Switch to offline mode?';

  @override
  String get switchToOfflineBody => 'No internet connection or the server is not responding. Continue with locally cached data?';

  @override
  String get switchedToOnline => 'Switched to online mode';

  @override
  String get switchedToOffline => 'Switched to offline mode';

  @override
  String get serverUnreachable => 'Cannot reach the server';

  @override
  String get serverUrlNotFound => 'Server URL not found';

  @override
  String get serverUrl => 'Server URL';

  @override
  String get connectionError => 'Connection error';

  @override
  String get menu => 'Menu';

  @override
  String get offline => 'Offline';

  @override
  String get refresh => 'Refresh';

  @override
  String get okb => 'OKB';

  @override
  String get akbPlan => 'AKB plan';

  @override
  String get akbFact => 'AKB Fact';

  @override
  String get forecastPercentOfFact => 'Forecast % of Fact';

  @override
  String get totalPlan => 'Total Plan';

  @override
  String get totalFact => 'Total Fact';

  @override
  String get charts => 'Charts';

  @override
  String get akbProgress => 'AKB Progress';

  @override
  String get planVsFact => 'Plan vs Fact';

  @override
  String get planCompletion => 'Plan Completion';

  @override
  String get factVsRemaining => 'Fact vs Remaining';

  @override
  String get forecastTrend => 'Forecast Trend';

  @override
  String get fromFactToForecast => 'From Fact to Forecast';

  @override
  String get remaining => 'Remaining';

  @override
  String get onTrack => 'On track';

  @override
  String get atRisk => 'At risk';

  @override
  String get insights => 'Insights';

  @override
  String get autoGeneratedHighlights => 'Auto-generated highlights';

  @override
  String get completion => 'Completion';

  @override
  String get gapToPlan => 'Gap to Plan';

  @override
  String get akbGap => 'AKB Gap';

  @override
  String get forecastVsPlan => 'Forecast vs Plan';

  @override
  String get todayPerformance => 'Today Performance';

  @override
  String get planExecution => 'Plan Execution';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get databaseView => 'Database View';

  @override
  String get preferenceKey => 'Preference Key';

  @override
  String get value => 'Value';

  @override
  String get id => 'ID';

  @override
  String get code => 'Code';

  @override
  String get name => 'Name';

  @override
  String get role => 'Role';

  @override
  String get warehouseCode => 'Warehouse Code';

  @override
  String get codeProject => 'Code Project';

  @override
  String get baseUrl => 'Base URL';

  @override
  String get telegramId => 'Telegram ID';

  @override
  String get chatId => 'Chat ID';

  @override
  String get topicId => 'Topic ID';

  @override
  String get createdAt => 'Created At';

  @override
  String updatedAt(String date, String time) {
    return 'Updated: $date $time';
  }

  @override
  String get totalPercent => 'Total %';

  @override
  String get forecastPercent => 'Forecast %';

  @override
  String get akbPercent => 'AKB %';

  @override
  String get updateDate => 'Update Date';

  @override
  String get exit => 'Exit';

  @override
  String get confirmExit => 'Are you sure you want to exit?';

  @override
  String get contactPerson => 'Contact';

  @override
  String get lastVisitDate => 'Last Visit';

  @override
  String get hasOrders => 'Has Orders';

  @override
  String get hasContracts => 'Has Contracts';

  @override
  String get isVisited => 'Is Visited';

  @override
  String get hasContract => 'Has Contract';

  @override
  String get coordinates => 'Coordinates';

  @override
  String get creditLimit => 'Credit Limit';

  @override
  String get accumulatedCredit => 'Accumulated Credit';

  @override
  String get codeRegion => 'Code Region';

  @override
  String get maps => 'Maps';

  @override
  String get selectDefaultMap => 'Select Default Map';

  @override
  String get googleMaps => 'Google Maps';

  @override
  String get yandexMaps => 'Yandex Maps';

  @override
  String get openStreetMap => 'OpenStreetMap';

  @override
  String get mapProvider => 'Map Provider';

  @override
  String get apiKey => 'API Key';

  @override
  String get configured => 'Configured';

  @override
  String get notConfigured => 'Not Configured';

  @override
  String get mapSettings => 'Map Settings';

  @override
  String get defaultMapChanged => 'Default map changed successfully';

  @override
  String get currentMapProvider => 'Current Map Provider';

  @override
  String get availableMaps => 'Available Maps';

  @override
  String get mapConfiguration => 'Map Configuration';

  @override
  String get visitProgress => 'Visit Progress';

  @override
  String get visitStepNumber => 'Visit Step';

  @override
  String get skipped => 'Skipped';

  @override
  String get current => 'Current';

  @override
  String get mandatory => 'Mandatory';

  @override
  String get completedAt => 'Completed at';

  @override
  String get skippedAt => 'Skipped at';

  @override
  String get notes => 'Notes';

  @override
  String get reason => 'Reason';

  @override
  String get previousStepsRequired => 'Previous steps must be completed';

  @override
  String get completeStep => 'Complete Step';

  @override
  String get skipStep => 'Skip Step';

  @override
  String get confirmCompletion => 'Confirm completion';

  @override
  String get stepCompletedSuccessfully => 'Step completed successfully';

  @override
  String get stepSkippedSuccessfully => 'Step skipped successfully';

  @override
  String get visitCompletedSuccessfully => 'Visit completed successfully!';

  @override
  String get finishVisit => 'Finish Visit';

  @override
  String get allRequiredStepsMustBeCompleted => 'All required steps must be completed';

  @override
  String get visitInfo => 'Visit Information';

  @override
  String get client => 'Client';

  @override
  String get totalSteps => 'Total Steps';

  @override
  String get requiredSteps => 'Required Steps';

  @override
  String get unknownState => 'Unknown state';

  @override
  String get cancelCompletion => 'Cancel Completion';

  @override
  String get confirmSkip => 'Confirm Skip';

  @override
  String get enterNotesOptional => 'Enter notes (optional)';

  @override
  String get enterSkipReason => 'Enter skip reason';

  @override
  String get stepCannotBeSkipped => 'This step cannot be skipped';

  @override
  String get allRequiredStepsCompleted => 'All required steps completed';

  @override
  String get soapRequest => 'SOAP Request';

  @override
  String get soapRequestCopied => 'SOAP request copied';

  @override
  String get copy => 'Copy';

  @override
  String get orderNotFound => 'Order not found';

  @override
  String get readOnly => 'Read-only';

  @override
  String get pageUnderDevelopment => 'Page under development';

  @override
  String get stepCompletedReadOnly => 'This step is completed. Read-only mode.';

  @override
  String get stepTypeNotImplemented => 'This step type page is not implemented yet.';

  @override
  String get orderDetailsNavigationErrorPrefix => 'Error opening order details';

  @override
  String get errorOccurredPrefix => 'Error occurred';

  @override
  String get stepErrorPrefix => 'Step error';

  @override
  String get visitFinishErrorPrefix => 'Error finishing visit';

  @override
  String get stepsCount => 'steps';

  @override
  String get visitFinishing => 'Finishing visit...';

  @override
  String orderNumber(String number) {
    return 'Order № $number';
  }

  @override
  String get dataSaveError => 'Error saving data';

  @override
  String get saveErrorPrefix => 'Save error';

  @override
  String get dataLoadError => 'Error loading data';

  @override
  String get productsLoadError => 'Error loading products';

  @override
  String get settingsUpdateError => 'Error updating settings';

  @override
  String get clearOrder => 'Clear order';

  @override
  String get suggestedOrders => 'Suggested orders';

  @override
  String get productSelectionError => 'Error navigating to product selection';

  @override
  String get orderDataCleared => 'Order data cleared';

  @override
  String get dataClearError => 'Error clearing data';

  @override
  String get orderCreationError => 'Error creating order';

  @override
  String get deliveryDateChangedSuccess => 'Delivery date changed successfully';

  @override
  String get dateChangeError => 'Error changing date';

  @override
  String get clearOrderConfirmTitle => 'Clear order';

  @override
  String get clearOrderConfirmMessage => 'All selected products and related data will be deleted. Settings will be preserved. Do you want to continue?';

  @override
  String get clientDataLoadError => 'Error loading client data';

  @override
  String get locationNotAvailable => 'Location data not available. Visit cannot be completed.';

  @override
  String get visitCompletedFor => 'visit completed successfully for';

  @override
  String get contractsPageError => 'Error navigating to contracts page';

  @override
  String get loadingClientImages => 'Loading client images...';

  @override
  String get clientImagesLoaded => 'Client images loaded';

  @override
  String get imageLoadError => 'Error loading image';

  @override
  String get disableVisitTodayFilter => 'Disable today\'s visit filter';

  @override
  String get showVisitTodayOnly => 'Show only today\'s visit clients';

  @override
  String get newClient => 'New client';

  @override
  String get orderHistory => 'Order history';

  @override
  String get tradingPointsNotFound => 'Trading points not found';

  @override
  String get clientCount => 'Client count';

  @override
  String get manageClientImages => 'Manage client images';

  @override
  String ordersCount(int count) {
    return '$count orders';
  }

  @override
  String get orderNumberPrefix => 'Order №';

  @override
  String get viewOrder => 'View Order';

  @override
  String get clientOrdersFor => 'orders for client';

  @override
  String get locationServicesDisabledSortingNotWork => 'Location services are disabled. Distance sorting will not work.';

  @override
  String get userDataNotFound => 'User data not found';

  @override
  String get phoneNumberNotSpecified => 'Phone number not specified';

  @override
  String get phoneCallFailed => 'Phone call failed';

  @override
  String get connectedToInternet => 'Connected to internet';

  @override
  String get offlineModeActive => 'Offline mode';

  @override
  String get refusalReasonSent => 'Refusal reason sent for';

  @override
  String get viewPanel => 'View panel';

  @override
  String get sortByDistanceRequiresPermission => 'Location permission required for distance sorting';

  @override
  String get sortByDistance => 'Sort by distance';

  @override
  String get sortAlphabeticalAZ => 'Sort alphabetically (A-Z)';

  @override
  String get sortAlphabeticalZA => 'Sort alphabetically (Z-A)';

  @override
  String get serverSelected => 'server selected';

  @override
  String get noInternetNoSavedUser => 'No internet and no saved user data found';

  @override
  String get noInternetLoginMismatch => 'No internet and entered login does not match saved login';

  @override
  String get savedUserServerMismatch => 'Saved user data does not match current server. Please change server.';

  @override
  String get noInternetUserNotInDb => 'No internet and user data not found in database or does not match';

  @override
  String get offlineLoginError => 'Offline login error';

  @override
  String get noInternetAvailable => 'No internet available';

  @override
  String get offlineModeQuestion => 'Do you want to enter offline mode as';

  @override
  String get offlineModeDescription => 'In offline mode you can work with existing data, but cannot load new data.';

  @override
  String get offlineLogin => 'Offline login';

  @override
  String get dataUpdating => 'Updating data...';

  @override
  String get errorPrefix => 'Error';

  @override
  String get cacheDataUsed => 'Cache data is being used';

  @override
  String get loginSuccessful => 'Login Successful!';

  @override
  String get onlineLoginError => 'Online login processing error';

  @override
  String get unknownUserRole => 'Unknown user role';

  @override
  String get enterField => 'Please enter';

  @override
  String get imageServiceNotAvailable => 'Image service not available';

  @override
  String get searchHint => 'Search...';

  @override
  String get pullToRefresh => 'Pull to refresh';

  @override
  String get pullToRefreshOrSyncData => 'If pull to refresh doesn\'t work, use \'sync all data\' option in settings menu';

  @override
  String get checkingDistance => 'Checking distance...';

  @override
  String get distanceRestrictionError => 'You are too far from the client. Please move closer to complete the visit.';

  @override
  String get cancelVisit => 'Cancel Visit';

  @override
  String get cancelVisitConfirmation => 'Are you sure you want to cancel this visit? All progress will be lost.';

  @override
  String get syncStatusIdle => 'Waiting';

  @override
  String get syncStatusProducts => 'Syncing products';

  @override
  String get syncStatusBalances => 'Syncing balances';

  @override
  String get syncStatusOrders => 'Syncing orders';

  @override
  String get syncStatusCompleted => 'Sync completed';

  @override
  String get syncStatusError => 'Sync error';

  @override
  String get syncInProgress => 'Synchronization in Progress';

  @override
  String get syncErrorUserNotFound => 'User code not found';

  @override
  String get syncAlreadyInProgress => 'Sync already in progress';

  @override
  String get syncCompleted => 'Data updated successfully';

  @override
  String get clientBalance => 'Client balance';

  @override
  String get clientBalanceDetails => 'Balance Details';

  @override
  String clientIsDebtor(String amount) {
    return 'Client is debtor. Total debt: $amount sum';
  }

  @override
  String clientHasOverpayment(String amount) {
    return 'Client has overpaid. Overpayment: $amount sum';
  }

  @override
  String get balanceIsZero => 'Balance is zero';

  @override
  String get totalDebt => 'Total debt';

  @override
  String get totalPayment => 'Total Payment';

  @override
  String get totalOrder => 'Total Order';

  @override
  String unpaidOrders(int count) {
    return '$count unpaid';
  }

  @override
  String overdueOrders(int count) {
    return '$count overdue';
  }

  @override
  String get balanceStatus => 'Balance status';

  @override
  String get contractsTab => 'Contracts';

  @override
  String get ordersTab => 'Orders';

  @override
  String get overviewTab => 'Overview';

  @override
  String get paymentAndDebtRatio => 'Payment and Debt Ratio';

  @override
  String get orderAndPaymentRatio => 'Order and Payment Ratio';

  @override
  String get paid => 'Paid';

  @override
  String get partiallyPaid => 'Partially Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String overdueDays(int days) {
    return 'Overdue $days days';
  }

  @override
  String refreshAfterSeconds(int seconds) {
    return 'Can refresh after $seconds seconds';
  }

  @override
  String balanceUpdated(String date) {
    return 'Updated';
  }

  @override
  String balanceServerDataUpdatedAt(String date) {
    return 'Balance status as of: $date';
  }

  @override
  String get balanceDataMayBeOutdated => 'Balance data may be outdated';

  @override
  String get noBalanceData => 'Balance data not found';

  @override
  String get balanceLoadError => 'Error loading balance';

  @override
  String get balanceServiceNotAvailable => 'Balance service not available';

  @override
  String get clientInnNotFound => 'Client INN not found';

  @override
  String get statistics => 'Statistics';

  @override
  String contractsCount(int count) {
    return '$count contracts';
  }

  @override
  String get contract => 'Contract';

  @override
  String get order => 'Order';

  @override
  String get overpayment => 'Overpayment';

  @override
  String get debt => 'Debt';

  @override
  String get debtAndOverpaymentRatio => 'Debt and Overpayment Ratio';

  @override
  String get debtor => 'Debtor';

  @override
  String get excess => 'Excess';

  @override
  String get orderAmountLabel => 'Order';

  @override
  String get paidAmountLabel => 'Paid';

  @override
  String get debtLabel => 'Debt';

  @override
  String get excessLabel => 'Excess';

  @override
  String get ordersStatus => 'Orders Status';

  @override
  String get clearBalanceCache => 'Clear Balance Cache';

  @override
  String get clearBalanceCacheConfirm => 'All client balance data will be deleted. It will be reloaded next time balance is viewed.';

  @override
  String get balanceCacheCleared => 'Balance cache cleared';

  @override
  String get fakturaNetworkError => 'Network error while connecting to Faktura.uz';

  @override
  String get tradePointTypesEmpty => 'Trade point types list is empty. Please add trade points first.';

  @override
  String get tradePointTypesLoadError => 'Error loading trade point types.';

  @override
  String get timeoutError => 'Request timed out. Please try again.';

  @override
  String get dataNotFound => 'Data not found.';

  @override
  String get invalidDataError => 'Invalid data received.';

  @override
  String get unknownBalanceError => 'An unknown error occurred.';

  @override
  String get retryButton => 'Retry';

  @override
  String balanceFor(String name) {
    return 'Balance: $name';
  }

  @override
  String get overviewTabShort => 'Overview';

  @override
  String get contractsTabShort => 'Contracts';

  @override
  String get ordersTabShort => 'Orders';

  @override
  String get totalOrdered => 'Total Orders';

  @override
  String get totalPaid => 'Total Paid';

  @override
  String get contractsCountLabel => 'Contracts Count';

  @override
  String get ordersCountLabel => 'Orders Count';

  @override
  String get unpaidOrdersLabel => 'Unpaid Orders';

  @override
  String get partiallyPaidLabel => 'Partially Paid';

  @override
  String get overdueLabel => 'Overdue';

  @override
  String contractWithCode(String code) {
    return 'Contract: $code';
  }

  @override
  String get totalSummary => 'Total';

  @override
  String get paidSummary => 'Paid';

  @override
  String get partialSummary => 'Partial';

  @override
  String get unpaidSummary => 'Unpaid';

  @override
  String get excessSummary => 'Excess';

  @override
  String ordersWithCount(int count) {
    return 'Orders ($count)';
  }

  @override
  String overpaymentWithCount(int count) {
    return 'Overpayments ($count)';
  }

  @override
  String orderWithNumber(String number) {
    return 'Order: $number';
  }

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get noContractsFound => 'No contracts found';

  @override
  String get noOrdersFound => 'No orders found';

  @override
  String get paidLabel => 'Paid';

  @override
  String get debtLabelChart => 'Debt';

  @override
  String get paymentLabel => 'Payment';

  @override
  String get partialLabel => 'Partial';

  @override
  String get unpaidLabel => 'Unpaid';

  @override
  String countItems(int count) {
    return '$count items';
  }

  @override
  String get contractDialog => 'Contract';

  @override
  String codeLabel(String code) {
    return 'Code: $code';
  }

  @override
  String projectLabel(String project) {
    return 'Project: $project';
  }

  @override
  String idLabel(String id) {
    return 'ID: $id';
  }

  @override
  String get closeButton => 'Close';

  @override
  String paymentAmount(String amount) {
    return 'Payment: $amount';
  }

  @override
  String debtAmount(String amount) {
    return 'Debt: $amount';
  }

  @override
  String get securityCheck => 'Security Check';

  @override
  String get securityCheckLoading => 'Loading...';

  @override
  String get securityCheckVerifying => 'Security verification...';

  @override
  String get securityCheckAllowed => 'Access granted';

  @override
  String get securityCheckBlocked => 'Access denied';

  @override
  String get securityCheckError => 'An error occurred';

  @override
  String get securityCheckLogin => 'Signing in...';

  @override
  String get accessDenied => 'Access Denied';

  @override
  String get accessDeniedMessage => 'Your access to this application has been blocked.';

  @override
  String get accessBlockedReasonAccountBound => 'This account is linked to another device';

  @override
  String get accessBlockedReasonDeviceBound => 'This device has another account';

  @override
  String get accessBlockedReasonHighRisk => 'Device does not meet security requirements';

  @override
  String get accessBlockedReasonPolicyViolation => 'Security policy violated';

  @override
  String get accessBlockedReasonUnknown => 'Unknown reason';

  @override
  String get retryCheck => 'Retry';

  @override
  String get contactSupportTeam => 'Contact Support';

  @override
  String get logoutConfirmTitle => 'Logout';

  @override
  String get logoutConfirmMessage => 'Are you sure you want to log out?';

  @override
  String get newContract => 'New contract';

  @override
  String get createContract => 'Create contract';

  @override
  String get createContractTitle => 'New Contract';

  @override
  String get createContractSubtitle => 'Fill in all fields';

  @override
  String get contractCreatedSuccess => 'Contract created successfully';

  @override
  String get contractCreatedError => 'Error creating contract';

  @override
  String get contractListRefreshed => 'Contract list refreshed';

  @override
  String get selectClient => 'Select client';

  @override
  String get selectContractType => 'Select contract type';

  @override
  String get contractTypesNotFound => 'Contract types not found';

  @override
  String get reloadContractTypes => 'Reload';

  @override
  String get autoFilled => 'Auto-filled';

  @override
  String get referenceNumber => 'Reference number';

  @override
  String get referenceTermDate => 'Term date';

  @override
  String get certificateNumber => 'Certificate number';

  @override
  String get certificateTermDate => 'Certificate term date';

  @override
  String get certificateUnlimited => 'Certificate unlimited';

  @override
  String get passportNumber => 'Passport number';

  @override
  String get passportTermDate => 'Passport term date';

  @override
  String get districtName => 'District name';

  @override
  String get districtCode => 'District code';

  @override
  String get documentInfo => 'Document information';

  @override
  String get regionInfo => 'Region information';

  @override
  String get creatingContract => 'Creating...';

  @override
  String get networkError => 'Network error';

  @override
  String get serverTimeout => 'Server connection timed out';

  @override
  String get noInternetConnection => 'No internet connection. Please connect to the internet';

  @override
  String get createClientTitle => 'New Client';

  @override
  String get createClientBasicInfo => 'Basic Information';

  @override
  String get createClientContactInfo => 'Contact Information';

  @override
  String get createClientAddressInfo => 'Address';

  @override
  String get createClientBankInfo => 'Bank Details (optional)';

  @override
  String get createClientClientName => 'Client Name';

  @override
  String get createClientClientNameHint => 'Store or company name';

  @override
  String get createClientSignboard => 'Signboard';

  @override
  String get createClientSignboardHint => 'External display name';

  @override
  String get createClientInn => 'TIN (Tax ID)';

  @override
  String get createClientInnHint => '9 or 14 digits';

  @override
  String get createClientTradePointType => 'Trade Point Type';

  @override
  String get createClientSelectTradePointType => 'Select trade point type';

  @override
  String get createClientRegion => 'Region';

  @override
  String get createClientSelectRegion => 'Select region';

  @override
  String get createClientContactPerson => 'Contact Person';

  @override
  String get createClientContactPersonHint => 'Responsible person name';

  @override
  String get createClientPhone => 'Phone Number';

  @override
  String get createClientPhoneHint => '+998 XX XXX XX XX';

  @override
  String get createClientResponsiblePhone => 'Responsible Person Phone';

  @override
  String get createClientResponsiblePhoneHint => 'Additional phone (optional)';

  @override
  String get createClientAddress => 'Address';

  @override
  String get createClientAddressHint => 'Full address';

  @override
  String get createClientDeliveryAddress => 'Delivery Address';

  @override
  String get createClientDeliveryAddressHint => 'If different (optional)';

  @override
  String get createClientLandmark => 'Landmark';

  @override
  String get createClientLandmarkHint => 'Nearby recognizable place';

  @override
  String get createClientDirector => 'Director';

  @override
  String get createClientDirectorHint => 'Full name';

  @override
  String get createClientMfo => 'MFO';

  @override
  String get createClientMfoHint => '5-digit bank code';

  @override
  String get createClientBankAccount => 'Bank Account';

  @override
  String get createClientBankAccountHint => '20 digits';

  @override
  String get createClientLocation => 'Location';

  @override
  String get createClientLocationDetecting => 'Detecting...';

  @override
  String get createClientLocationNotFound => 'Location not found';

  @override
  String get createClientRefreshLocation => 'Refresh';

  @override
  String get createClientSubmit => 'Create Client';

  @override
  String get createClientCreating => 'Creating...';

  @override
  String get createClientSuccess => 'Client Created!';

  @override
  String get createClientSyncing => 'Syncing data...';

  @override
  String get createClientCode => 'Code';

  @override
  String get createClientTerritoryWarningTitle => 'Important Notice!';

  @override
  String get createClientTerritoryWarningMessage => 'Client creation must be performed within their trading territory. Otherwise, problems may occur when creating an order and its delivery.';

  @override
  String get createClientAutoFilledHint => 'Auto-filled. Modify if necessary.';

  @override
  String get createClientAddressDetected => 'Address detected and auto-filled';

  @override
  String get createClientSelectRegionError => 'Please select a region';

  @override
  String get createClientSelectTypeError => 'Please select a trade point type';

  @override
  String get createClientLocationError => 'Location data not found';

  @override
  String get createClientUserCodeError => 'User code not found';

  @override
  String get createClientUnknownError => 'Unknown error';

  @override
  String get labelTradingPointType => 'Trading Point Type';

  @override
  String get labelBusinessRegion => 'Business Region';

  @override
  String get labelStatus => 'Status';

  @override
  String get labelDateRange => 'Date Range';

  @override
  String get labelClients => 'Clients';

  @override
  String get refusalReasonTitle => 'Refusal Reason';

  @override
  String selectRefusalReasonFor(String name) {
    return 'Select refusal reason for $name:';
  }

  @override
  String businessRegionLabel(String region) {
    return 'Business Region: $region';
  }

  @override
  String contactLabel(String contact) {
    return 'Contact: $contact';
  }

  @override
  String innLabel(String inn) {
    return 'INN';
  }

  @override
  String ownerLabel(String owner) {
    return 'Owner: $owner';
  }

  @override
  String responsiblePersonLabel(String responsible) {
    return 'Responsible: $responsible';
  }

  @override
  String responsiblePersonPhoneLabel(String phone) {
    return 'Responsible Phone: $phone';
  }

  @override
  String typeLabel(String type) {
    return 'Type: $type';
  }

  @override
  String regionDistrictLabel(String region, String district) {
    return '$region, $district';
  }

  @override
  String signboardLabel(String signboard) {
    return 'Signboard: $signboard';
  }

  @override
  String landmarkLabel(String landmark) {
    return 'Landmark: $landmark';
  }

  @override
  String get waitingForLocation => 'Waiting for location data...';

  @override
  String get visitCompletedTitle => 'Visit Completed';

  @override
  String stepsCompletedCount(int count) {
    return '$count steps completed';
  }

  @override
  String get returnToHome => 'Return to Home';

  @override
  String completedAtLabel(String date) {
    return 'Completed: $date';
  }

  @override
  String orderCaption(String id) {
    return 'Order $id';
  }

  @override
  String maxQuantityMessage(int stock) {
    return 'Max quantity: $stock pcs';
  }

  @override
  String get productPriceZeroError => 'Cannot add product with price 0 or less';

  @override
  String get quantityUpdateError => 'Error updating quantity';

  @override
  String get confirmationError => 'Error confirming selection';

  @override
  String get confirm => 'Confirm';

  @override
  String get productSelectionTitle => 'Product Selection';

  @override
  String productsSelectedCount(int count) {
    return '$count products selected';
  }

  @override
  String get noProductsAvailable => 'No products available';

  @override
  String get clear => 'Clear';

  @override
  String totalProductsCount(int count) {
    return 'Total products: $count';
  }

  @override
  String totalAmount(String amount) {
    return 'Total amount: $amount';
  }

  @override
  String errorOccurred(String error) {
    return 'Error occurred';
  }

  @override
  String get cameraPermissionDenied => 'Camera permission denied';

  @override
  String cameraInitError(String error) {
    return 'Error initializing camera: $error';
  }

  @override
  String cameraError(String error) {
    return 'Camera error: $error';
  }

  @override
  String get cameraInUseMessage => 'Camera is being used by another app. Attempting to reconnect...';

  @override
  String get imageSavedSuccessfully => 'Image saved successfully';

  @override
  String imageSaveError(String error) {
    return 'Error saving image: $error';
  }

  @override
  String get cameraNotReady => 'Camera not ready';

  @override
  String get cameraNotAvailable => 'Camera not available or not working';

  @override
  String imageCounter(int current, int total) {
    return '$current / $total';
  }

  @override
  String get imageCapturedSuccessfully => 'Image captured successfully';

  @override
  String imageCaptureError(String error) {
    return 'Error capturing image: $error';
  }

  @override
  String get xmlRequestLabel => 'XML Request';

  @override
  String get xmlCopied => 'XML copied';

  @override
  String get enterNumberHint => 'Enter number';

  @override
  String get balanceStatusTitle => 'Balance Status';

  @override
  String productNotFoundMessage(String code) {
    return 'Product information not found: $code';
  }

  @override
  String get clientCreatedSuccessfully => 'New client created successfully!';

  @override
  String get callClientTitle => 'Call Client';

  @override
  String callClientConfirmation(String phone) {
    return 'Do you want to call the client?\n$phone';
  }

  @override
  String get dialerNotAvailable => 'Dialer not available';

  @override
  String get updateCoordinatesNotImplemented => 'Update coordinates - functionality to be implemented';

  @override
  String get osmNotLoadedFallback => 'OpenStreetMap not loaded. Using Google Maps.';

  @override
  String get confirmLocationTitle => 'Confirm Location';

  @override
  String get orderDetailsNotFound => 'Order details not found.';

  @override
  String get unknown => 'Unknown';

  @override
  String get locationPermissionDenied => 'Location permission denied';

  @override
  String permissionCheckError(String error) {
    return 'Error checking permission: $error';
  }

  @override
  String locationDetectionError(String error) {
    return 'Error detecting location: $error';
  }

  @override
  String get userLocationNotFound => 'User location not found';

  @override
  String routeInfo(String distance, String time) {
    return 'Route: $distance km, estimated $time';
  }

  @override
  String routeCreationError(String error) {
    return 'Error creating route: $error';
  }

  @override
  String cameraMoveError(String error) {
    return 'Error moving camera: $error';
  }

  @override
  String permissionsCheckError(String error) {
    return 'Error checking permissions: $error';
  }

  @override
  String get locationUpdating => 'Updating location...';

  @override
  String get clientLocationUpdated => 'Client location updated successfully';

  @override
  String locationUpdateError(String error) {
    return 'Error updating location: $error';
  }

  @override
  String get calculatingRoute => 'Calculating route...';

  @override
  String regionsLoadError(String error) {
    return 'Error loading regions: $error';
  }

  @override
  String locationGetError(String error) {
    return 'Error getting location: $error';
  }

  @override
  String get apiKeySavedSuccessfully => 'API key saved successfully';

  @override
  String get minimumInterval60Minutes => 'Minimum interval is 60 minutes';

  @override
  String pageLoadError(String error) {
    return 'Error loading page: $error';
  }

  @override
  String get imageSetAsPrimary => 'Image set as primary';

  @override
  String serverImagesLoadError(String error) {
    return 'Error loading server images: $error';
  }

  @override
  String gallerySelectionError(String error) {
    return 'Error selecting from gallery: $error';
  }

  @override
  String cameraCaptureError(String error) {
    return 'Error capturing from camera: $error';
  }

  @override
  String orderDraftSaved(String fileName) {
    return 'Order Draft saved: $fileName';
  }

  @override
  String get tablesLabel => 'Tables';

  @override
  String tableColumns(String tableName) {
    return '$tableName columns';
  }

  @override
  String get orderDetailsTitle => 'Order details';

  @override
  String get camera => 'Camera';

  @override
  String get gallery => 'Gallery';

  @override
  String clientImagesTitle(String clientName) {
    return '$clientName - Images';
  }

  @override
  String tradingPointImagesTitle(String pointName) {
    return '$pointName - Images';
  }

  @override
  String uploadToServer(int count) {
    return 'Upload to Server ($count images)';
  }

  @override
  String get kpiDashboardTitle => 'KPI Dashboard';

  @override
  String get reportSentTitle => 'Report Sent';

  @override
  String get editFeatureComingSoon => 'Edit feature coming soon';

  @override
  String get sendPdf => 'Send PDF';

  @override
  String get printFeatureComingSoon => 'Print feature coming soon';

  @override
  String get print => 'Print';

  @override
  String stepCompleted(String stepName) {
    return '$stepName completed';
  }

  @override
  String stepSkip(String stepName) {
    return '$stepName skip';
  }

  @override
  String get syncWithDependencies => 'Sync with dependencies';

  @override
  String get editLocationTitle => 'Edit location';

  @override
  String get recommended => 'Recommended';

  @override
  String get syncTableOnly => 'Sync table only';

  @override
  String get syncWarning => 'May fail if dependencies not synced';

  @override
  String get tableOnly => 'Table only';

  @override
  String get withDependencies => 'With dependencies';

  @override
  String get syncEntireGroup => 'Sync Entire Group';

  @override
  String get statusNew => 'New';

  @override
  String get retail => 'Retail';

  @override
  String get continueAction => 'Continue';

  @override
  String get previousStepsMustBeCompleted => 'Previous steps must be completed';

  @override
  String get reload => 'Reload';

  @override
  String get imageDeleted => 'Image deleted';

  @override
  String imageDeleteError(String error) {
    return 'Error deleting image: $error';
  }

  @override
  String get deleteImageTitle => 'Delete Image';

  @override
  String get deleteImageConfirmation => 'Are you sure you want to delete this image?';

  @override
  String get photoAfterTitle => 'Photo AFTER (Facing correction)';

  @override
  String get photoBeforeTitle => 'Photo BEFORE (Facing correction)';

  @override
  String get photosNotLoadedYet => 'Photos not loaded yet';

  @override
  String get timeUnknown => 'Time unknown';

  @override
  String get unitOfMeasure => 'Unit of Measure';

  @override
  String get category => 'Category';

  @override
  String get brand => 'Brand';

  @override
  String get series => 'Series';

  @override
  String get barcode => 'Barcode';

  @override
  String get vendorCode => 'Vendor Code';

  @override
  String get warehouseInformation => 'Warehouse Information';

  @override
  String get reserved => 'Reserved';

  @override
  String get physicalProperties => 'Physical Properties';

  @override
  String get weight => 'Weight';

  @override
  String get volume => 'Volume';

  @override
  String get productsNotFound => 'Products not found';

  @override
  String get bonusesNotFound => 'Bonuses not found';

  @override
  String get classInformationNotFound => 'Class information not found';

  @override
  String get searchResultsNotFound => 'Search results not found';

  @override
  String get promotionConditions => 'Promotion Conditions';

  @override
  String minimalProductCount(int count) {
    return 'Minimal product count: $count';
  }

  @override
  String bonusCount(int count) {
    return 'Bonus count: $count';
  }

  @override
  String get readOnlyMode => 'Read Only';

  @override
  String get shelfAuditTitle => 'Shelf Audit (Remains)';

  @override
  String get pageInDevelopment => 'Page is currently under development';

  @override
  String apiKeyLabel(String status) {
    return 'API Key: $status';
  }

  @override
  String get apiKeyConfigured => 'Configured';

  @override
  String get apiKeyNotRequired => 'Key not required';

  @override
  String get apiKeyNotConfigured => 'Not configured';

  @override
  String get editInformation => 'Edit Information';

  @override
  String get editClientCoordinates => 'Edit Client Coordinates';

  @override
  String get clientPhotosTitle => 'Client Photos';

  @override
  String clientPhotosDescription(String name) {
    return 'Here are photos related to the client $name';
  }

  @override
  String get notSent => 'Not sent';

  @override
  String sendToServer(int count) {
    return 'Send to server ($count photos)';
  }

  @override
  String get mainImage => 'Main image';

  @override
  String get image => 'Image';

  @override
  String get noImagesAvailable => 'No images available';

  @override
  String get clickPlusToAddImage => 'Click the + button to add an image';

  @override
  String get setAsMainImage => 'Set as main image';

  @override
  String get clientNameLabel => 'Client name';

  @override
  String get orderNumberLabel => 'Order number';

  @override
  String get orderDateLabel => 'Order date';

  @override
  String get orderTotalLabel => 'Order total';

  @override
  String get mainStatusLabel => 'Main status';

  @override
  String get statusCodeLabel => 'Status code';

  @override
  String get totalProductsLabel => 'Total products';

  @override
  String get productNameLabel => 'Product name';

  @override
  String get articleLabel => 'Article';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get priceLabel => 'Price';

  @override
  String get amountLabel => 'Amount';

  @override
  String get priceTypeLabel => 'Price type';

  @override
  String get noProductsInOrder => 'No products in order';

  @override
  String get productListEmpty => 'Product list is empty';

  @override
  String get productsNotSelected => 'Products not selected';

  @override
  String get clickPlusToAddProduct => 'Click the + button to add a product';

  @override
  String get reportPeriod => 'Report period';

  @override
  String get monthlyOKB => 'Monthly OKB';

  @override
  String get selectPeriod => 'Select Period';

  @override
  String get creatingLocation => 'Detecting...';

  @override
  String get locationNotFound => 'Location not found';

  @override
  String get createClient => 'Create Client';

  @override
  String get swipeToRefresh => 'Try swiping down to refresh!';

  @override
  String get ifSwipeNotWorking => 'If swiping down doesn\'t work, perform the \"refresh all data\" action located in the settings menu';

  @override
  String imageCountLabel(int count) {
    return '$count photos';
  }

  @override
  String photosNotLoadedDescription(String clientName) {
    return 'Here are photos related to the client $clientName';
  }

  @override
  String get totalLabel => 'Total:';

  @override
  String get articleLabelShort => 'Art:';

  @override
  String get availableLabel => 'Available:';

  @override
  String get pieces => 'pieces';

  @override
  String get shippingDate => 'Shipping Date';

  @override
  String get changeShippingDate => 'Change Shipping Date';

  @override
  String get totalValueLabel => 'Total Value';

  @override
  String get productsLabel => 'Products';

  @override
  String get addProduct => 'Add Product';

  @override
  String get creating => 'Creating...';

  @override
  String get refreshLabel => 'Refresh';

  @override
  String get refreshing => 'Refreshing...';

  @override
  String get changePeriod => 'Change Period';

  @override
  String get server => 'Server';

  @override
  String get addImage => 'Add Image';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get deleteImage => 'Delete Image';

  @override
  String get deleteImageConfirm => 'Are you sure you want to delete this image?';

  @override
  String get noReportsAvailable => 'No reports available';

  @override
  String get tables => 'Tables';

  @override
  String get sendPdfLabel => 'Send PDF';

  @override
  String get warehouse => 'Warehouse';

  @override
  String get takePhotoTooltip => 'Take photo';

  @override
  String get changeShippingDateTooltip => 'Change shipping date';

  @override
  String get sendReportViaTelegram => 'Send report via Telegram bot';

  @override
  String get fullscreen => 'Fullscreen';

  @override
  String get updateCoordinates => 'Update coordinates';

  @override
  String get list => 'List';

  @override
  String get grid => 'Grid';

  @override
  String get every1Hour => 'Every 1 hour';

  @override
  String get every4Hours => 'Every 4 hours';

  @override
  String get every6Hours => 'Every 6 hours';

  @override
  String get every12Hours => 'Every 12 hours';

  @override
  String get daily24h => 'Daily (24h)';

  @override
  String get weekly1Week => 'Weekly (1 week)';

  @override
  String get customIntervalMinutes => 'Custom Interval (Minutes)';

  @override
  String get organizationLabel => 'Organization';

  @override
  String get codeLabel2 => 'Code';

  @override
  String get regionsLoading => 'Loading regions...';

  @override
  String get cyclingRegular => 'Regular bicycle';

  @override
  String get cyclingRoad => 'Road bicycle';

  @override
  String get cyclingMountain => 'Mountain bicycle';

  @override
  String get cyclingSafe => 'Safe bicycle';

  @override
  String get productsPage => 'Products Page';

  @override
  String quantityHint(int stock) {
    return '0 to $stock';
  }

  @override
  String get minimum60Minutes => 'Minimum 60 minutes';

  @override
  String get enterQuantity => 'Enter quantity';

  @override
  String maxAvailable(int stock) {
    return 'Maximum available: $stock pieces';
  }

  @override
  String imageNumber(int number) {
    return 'Image $number';
  }

  @override
  String get selectPriceType => 'Select Price Type';

  @override
  String get selectPriceTypeHint => 'Click the filter button above to select a price type from the filter panel';

  @override
  String productsCount(int count) {
    return 'Products count: $count';
  }

  @override
  String get categories => 'Categories';

  @override
  String get selectBrandFirst => 'Select brand first';

  @override
  String get reportsSection => 'Reports section';

  @override
  String get tasks => 'Tasks';

  @override
  String locationError(String error) {
    return 'Error getting location: $error';
  }

  @override
  String get addressDetected => 'Address detected and auto-filled';

  @override
  String get pleaseSelectRegion => 'Please select a region';

  @override
  String get pleaseSelectTradePointType => 'Please select a trade point type';

  @override
  String get locationDataNotFound => 'Location data not found';

  @override
  String get all => 'All';

  @override
  String get closeEditMode => 'Close edit mode';

  @override
  String get activeClients => 'Active clients';

  @override
  String get activeClientsTooltip => 'Clients with active orders today';

  @override
  String get cashless => 'Cashless';

  @override
  String get ordersTotal => 'Total orders';

  @override
  String get visitedTradingPoints => 'Visited trading points';

  @override
  String get visitedTradingPointsTooltip => 'Number of visited trading points';

  @override
  String get territoryOKB => 'Territory OKB';

  @override
  String get territoryOKBTooltip => 'Territory client base coverage';

  @override
  String get todayMainIndicators => 'Today — main indicators';

  @override
  String get last7Days => 'Last 7 days';

  @override
  String get last30Days => 'Last 30 days';

  @override
  String get monthlyPlanFactForecast => 'Monthly Plan / Fact / Forecast';

  @override
  String get monthlyOkbAkb => 'Monthly OKB/AKB';

  @override
  String get contractsNotFound => 'No contracts found';

  @override
  String get contractsListRefreshed => 'Contracts list refreshed';

  @override
  String get contractAmount => 'Contract amount';

  @override
  String get contractDocument => 'Contract document';

  @override
  String clientOrders(String name) {
    return '$name\'s orders';
  }

  @override
  String get filterApplyError => 'Error applying filter';

  @override
  String get main => 'Main';

  @override
  String get contents => 'Contents';

  @override
  String get mainReports => 'Main reports';

  @override
  String get mainReportsDescription => 'KPI indicators and main statistics';

  @override
  String get visitsReport => 'Visits report';

  @override
  String get visitsReportDescription => 'Information about visits to clients';

  @override
  String get completedVisits => 'Completed visits';

  @override
  String get plannedVisits => 'Planned visits';

  @override
  String get visitEfficiency => 'Visit efficiency';

  @override
  String get lastVisits => 'Last visits';

  @override
  String get dataLoading => 'Loading data...';

  @override
  String get successful => 'Successful';

  @override
  String get orderPlaced => 'Order placed';

  @override
  String get rejected => 'Rejected';

  @override
  String get reportDataRefreshed => 'Report data refreshed successfully';

  @override
  String get apiKeySaved => 'API key saved successfully';

  @override
  String saveError(String error) {
    return 'Save error: $error';
  }

  @override
  String userDataLoadError(String error) {
    return 'Error loading user data: $error';
  }

  @override
  String warehouseDataLoadError(String error) {
    return 'Error loading warehouse data: $error';
  }

  @override
  String get justSaved => 'Just saved';

  @override
  String savedMinutesAgo(int minutes) {
    return 'Saved $minutes minutes ago';
  }

  @override
  String savedHoursAgo(int hours) {
    return 'Saved $hours hours ago';
  }

  @override
  String get notSaved => 'Not saved';

  @override
  String get selectDateRange => 'Select date range';

  @override
  String get selectPeriodTitle => 'Select period';

  @override
  String get selectedPeriod => 'Selected period';

  @override
  String get selectTable => 'Select table';

  @override
  String get selectRegionValidator => 'Select region';

  @override
  String get selectTradePointTypeValidator => 'Select trade point type';

  @override
  String get currentMonth => 'Current month';

  @override
  String get selectReportDatesHint => 'Set start and end dates for the report';

  @override
  String get offlineCannotRefresh => 'Cannot refresh data in offline mode';

  @override
  String distanceRequirementMessage(String name) {
    return 'You need to meet the distance requirement to visit $name.';
  }

  @override
  String requiredDistance(int distance) {
    return 'Required distance: ${distance}m';
  }

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusInProcess => 'In process';

  @override
  String get orderStatusReturn => 'Return';

  @override
  String get orderStatusExpired => 'Expired';

  @override
  String get contractStatusActive => 'Active';

  @override
  String get contractStatusExpired => 'Expired';

  @override
  String get contractStatusCancelled => 'Cancelled';

  @override
  String get contractStatusPending => 'Not approved';

  @override
  String get contractStatusSuspended => 'Suspended';

  @override
  String get contractTabAll => 'All';

  @override
  String get appPreparing => 'Preparing app...';

  @override
  String get permissionsChecking => 'Checking permissions...';

  @override
  String get permissionsCheckTitle => 'Permissions Check';

  @override
  String get permissionsCheckDescription => 'The following permissions are required for the app to work properly:';

  @override
  String get permissionFileStorage => 'File Storage';

  @override
  String get permissionFileStorageDesc => 'To save data';

  @override
  String get permissionLocation => 'Location';

  @override
  String get permissionLocationDesc => 'For maps and distance calculation';

  @override
  String get permissionCamera => 'Camera';

  @override
  String get permissionCameraDesc => 'To take photos';

  @override
  String get permissionMicrophone => 'Microphone';

  @override
  String get permissionMicrophoneDesc => 'To record audio';

  @override
  String get permissionNotifications => 'Notifications';

  @override
  String get permissionNotificationsDesc => 'To show messages';

  @override
  String get permissionAudio => 'Music and Audio';

  @override
  String get permissionAudioDesc => 'To work with audio files';

  @override
  String get permissionPhotosVideos => 'Photos and Videos';

  @override
  String get permissionPhotosVideosDesc => 'To work with media files';

  @override
  String get permissionsLimitedWarning => 'Without permissions, the app will work in limited mode.';

  @override
  String get startButton => 'Start';

  @override
  String get permissionStorageTitle => 'File Storage Permission';

  @override
  String get permissionStorageDescAndroid13 => 'Select folder to save app data';

  @override
  String get permissionStorageDescOther => 'To save and load app data';

  @override
  String get permissionStoragePurposeAndroid13 => 'Select a folder to save photos, documents and data';

  @override
  String get permissionStoragePurposeOther => 'To save photos, documents and data';

  @override
  String get permissionLocationTitle => 'Location Permission';

  @override
  String get permissionLocationDescription => 'To sort trading points by distance';

  @override
  String get permissionLocationPurpose => 'To show location on map and calculate distance';

  @override
  String get permissionLocationAlwaysTitle => 'Background Location Permission';

  @override
  String get permissionLocationAlwaysDescription => 'To detect location when app is in background';

  @override
  String get permissionLocationAlwaysPurpose => 'Background service and notifications';

  @override
  String get permissionCameraTitle => 'Camera Permission';

  @override
  String get permissionCameraDescription => 'To take photos and scan barcodes';

  @override
  String get permissionCameraPurpose => 'To photograph products and trading points';

  @override
  String get permissionMicrophoneTitle => 'Microphone Permission';

  @override
  String get permissionMicrophoneDescription => 'For voice recording and audio messages';

  @override
  String get permissionMicrophonePurpose => 'Voice notes and audio recordings';

  @override
  String get permissionNotificationTitle => 'Notification Permission';

  @override
  String get permissionNotificationDescription => 'To show important messages';

  @override
  String get permissionNotificationPurpose => 'Reminders, news and notifications';

  @override
  String get permissionAudioTitle => 'Music and Audio Permission';

  @override
  String get permissionAudioDescription => 'To work with audio files';

  @override
  String get permissionAudioPurpose => 'Music, audio messages and voice files';

  @override
  String get permissionPhotosVideosTitle => 'Photos and Videos Permission';

  @override
  String get permissionPhotosVideosDescription => 'To work with media files';

  @override
  String get permissionPhotosVideosPurpose => 'Photos, videos and media files';

  @override
  String permissionRequired(String permission) {
    return '$permission required';
  }

  @override
  String permissionRequiredSettings(String description) {
    return '$description. Please grant permission in app settings.';
  }

  @override
  String get laterButton => 'Later';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String permissionPurpose(String purpose) {
    return 'Purpose: $purpose';
  }

  @override
  String get allowPermissionQuestion => 'Would you like to grant permission?';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get checking => 'Checking...';

  @override
  String get initializingSyncEngine => 'Initializing sync engine...';

  @override
  String get dataSynchronization => 'Data Synchronization';

  @override
  String tablesSynced(int synced, int total) {
    return '$synced of $total tables synced';
  }

  @override
  String get syncAllData => 'Sync All Data';

  @override
  String get syncAllTablesInOrder => 'This will sync all tables in dependency order';

  @override
  String get dataGroups => 'Data Groups';

  @override
  String get backgroundAutoSync => 'Background Auto-Sync';

  @override
  String get backgroundSyncDescription => 'Keep your data fresh even when the app is closed. Requires internet connection.';

  @override
  String get syncInterval => 'Sync Interval';

  @override
  String get customIntervalNote => '* Custom interval takes priority if set to 60 or more';

  @override
  String get clientBalanceCache => 'Client Balance Cache';

  @override
  String clientBalancesCached(int count) {
    return '$count client balances cached';
  }

  @override
  String get balanceCacheDescription => 'Client balance data is stored in local cache. You can clear the cache if the data is outdated.';

  @override
  String get clearing => 'Clearing...';

  @override
  String get clearCache => 'Clear Cache';

  @override
  String get backgroundSyncEnabled => 'Background sync enabled';

  @override
  String get backgroundSyncDisabled => 'Background sync disabled';

  @override
  String get minimumIntervalIs60 => 'Minimum interval is 60 minutes';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '$days days ago';
  }

  @override
  String weeksAgo(int weeks) {
    return '$weeks weeks ago';
  }

  @override
  String get unknownProduct => 'Unknown product';

  @override
  String get errorOccurredTitle => 'An error occurred';

  @override
  String get akbClientReport => 'AKB clients report';

  @override
  String get akbClients => 'AKB clients';

  @override
  String get akbPercentage => 'AKB percentage';

  @override
  String get akbClientsList => 'AKB clients list';

  @override
  String daysAgoShort(int days) {
    return '$days days ago';
  }

  @override
  String get locationPermissionNeeded => 'Location permission required';

  @override
  String get locationPermissionRequestMessage => 'Your location is needed to sort trading points by distance and display on the map. Do you allow?';

  @override
  String get later => 'Later';

  @override
  String get locationSettingsMessage => 'Location permission is required for sorting by distance and map functions. Please grant location permission from app settings.';

  @override
  String get enableLocationServicesMessage => 'Location services must be enabled for sorting by distance and map functions. Please enable location services.';

  @override
  String get locationSettings => 'Location settings';

  @override
  String get dataRefreshError => 'Error refreshing data';

  @override
  String dateFromTo(String start, String end) {
    return '$start to $end';
  }

  @override
  String get akbByRegions => 'AKB by regions';

  @override
  String get akbByProductCategories => 'AKB by product categories';

  @override
  String get tradingPointAbbr => 't.p.';

  @override
  String get footerNoteText => 'Data imported from Telegram report. You can change the text to switch to a new source — UI will be updated.';

  @override
  String get syncStepCheckingUser => 'Checking user...';

  @override
  String get syncStepClearingData => 'Clearing old data...';

  @override
  String get syncStepSyncingKpi => 'Loading KPI data...';

  @override
  String get syncStepSyncingClients => 'Loading clients list...';

  @override
  String get syncStepSyncingProducts => 'Loading products...';

  @override
  String get syncStepSyncingPriceTypes => 'Loading price types...';

  @override
  String get syncStepSyncingBusinessRegions => 'Loading business regions...';

  @override
  String get syncStepSyncingUserWarehouses => 'Loading user warehouses...';

  @override
  String get syncStepSyncingProductPrices => 'Loading product prices...';

  @override
  String get syncStepSyncingProductBalances => 'Loading product balances...';

  @override
  String get syncStepSyncingClientContracts => 'Loading client contracts...';

  @override
  String get syncStepUpdatingClientContractStatus => 'Updating client contract statuses...';

  @override
  String get syncStepSyncingContractTypes => 'Loading contract types...';

  @override
  String get syncStepSyncingDistrictContracting => 'Loading districts...';

  @override
  String get syncStepSyncingOrderStatuses => 'Loading order statuses...';

  @override
  String get syncStepSyncingOrders => 'Loading orders...';

  @override
  String get syncStepSyncingSalesReqPermissions => 'Loading agent permissions...';

  @override
  String get syncStepSyncingPlannedRoutes => 'Loading planned routes...';

  @override
  String get syncStepSyncingUserOrganizations => 'Loading user organizations...';

  @override
  String get syncStepSyncingUserProjects => 'Loading user projects...';

  @override
  String get syncStepSyncingPromotions => 'Loading promotions...';

  @override
  String get syncStepSyncingMapTokens => 'Loading map tokens...';

  @override
  String get syncStepSyncingReports => 'Loading reports...';

  @override
  String get syncStepSyncingThumbnails => 'Loading images...';

  @override
  String get syncStepCompleted => 'Data updated!';

  @override
  String get syncStepError => 'An error occurred';

  @override
  String get syncSuccessTitle => 'Success!';

  @override
  String get syncUpdatingTitle => 'Updating data...';

  @override
  String get syncSkippedRecent => 'Skipped (recently synced)';

  @override
  String get syncBackgroundContinues => 'Sync continues in background';

  @override
  String get paymentRequiredError => 'Payment required. Please check your subscription.';

  @override
  String get authenticationError => 'Authentication error. Please login again.';

  @override
  String get accessForbiddenError => 'Access forbidden. You don\'t have permission.';

  @override
  String get serviceNotFoundError => 'Service not found. Please contact support.';

  @override
  String get serverUnavailableError => 'Server unavailable. Please try again later.';

  @override
  String get dataUpdateError => 'Error updating data. Using cached data.';

  @override
  String get syncStatusErrors => 'Errors';

  @override
  String get syncStatusSynced => 'Synced';

  @override
  String get syncStatusPartial => 'Partial';

  @override
  String get syncStatusNotSynced => 'Not synced';

  @override
  String tablesOfTotalSynced(int synced, int total) {
    return '$synced of $total tables synced';
  }

  @override
  String get tablesInThisGroup => 'Tables in this group';

  @override
  String get yesterdayText => 'Yesterday';

  @override
  String get neverSynced => 'Never synced';

  @override
  String get tableEmpty => 'Table is empty';

  @override
  String recordsCount(int count) {
    return '$count records';
  }

  @override
  String lastSyncLabel(String time) {
    return 'Last sync: $time';
  }

  @override
  String get syncTable => 'Sync table';

  @override
  String get dependencies => 'Dependencies';

  @override
  String get willCascadeTo => 'Will cascade to';

  @override
  String get tradingPointsLabel => 'Trading points';

  @override
  String get tradingPointsNotAvailable => 'Trading points not available';

  @override
  String get dateRangeLabel => 'Date range';

  @override
  String get allDatesLabel => 'All dates';

  @override
  String get clearLabel => 'Clear';

  @override
  String get statusLabel => 'Status';

  @override
  String get statusAll => 'All';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusPending => 'Pending';

  @override
  String clientContractsCount(String name, int count) {
    return '$name client\'s contracts ($count)';
  }

  @override
  String refreshError(String error) {
    return 'Refresh error';
  }

  @override
  String get dataTab => 'Details';

  @override
  String get documentTab => 'Document';

  @override
  String clientLabel(String name) {
    return 'Client: $name';
  }

  @override
  String startDateLabel(String date) {
    return 'Start: $date';
  }

  @override
  String endDateLabel(String date) {
    return 'End: $date';
  }

  @override
  String get unknownDate => 'Unknown';

  @override
  String get statusAndType => 'Status and type';

  @override
  String get typeLabel2 => 'Type';

  @override
  String get additionalInfo => 'Additional information';

  @override
  String get certificateLimited => 'Certificate limited';

  @override
  String get yesText => 'Yes';

  @override
  String get noText => 'No';

  @override
  String get referenceNumberLabel => 'Reference number';

  @override
  String get certificateNumberLabel => 'Certificate number';

  @override
  String get passportNumberLabel => 'Passport number';

  @override
  String get districtCodeLabel => 'District code';

  @override
  String get districtNameLabel => 'District name';

  @override
  String get projectCodeLabel => 'Project code';

  @override
  String get projectFieldLabel => 'Project';

  @override
  String get selectProject => 'Select project';

  @override
  String get projectRequired => 'Project selection is required';

  @override
  String get projectInfoTooltip => 'Contract number will be generated based on the selected project\'s numbering system';

  @override
  String get projectInfoSection => 'Project information';

  @override
  String get creditLabel => 'Credit';

  @override
  String get fullPaymentLabel => '100% payment';

  @override
  String get uzbekLanguage => 'Uzbek';

  @override
  String get russianLanguage => 'Russian';

  @override
  String get pdfPreparing => 'Preparing PDF...';

  @override
  String get tapToReveal => 'Tap';

  @override
  String get warehousesTitle => 'Warehouses';

  @override
  String get warehousesNotFound => 'Warehouses not found';

  @override
  String warehousesCount(int count) {
    return 'Warehouses count: $count';
  }

  @override
  String createdLabel(String date) {
    return 'Created: $date';
  }

  @override
  String updatedLabel(String date) {
    return 'Updated: $date';
  }

  @override
  String get visitCompletedToday => 'Visit completed today';

  @override
  String get visitExpectedToday => 'Visit expected today';

  @override
  String get visitNotPlannedToday => 'Visit not planned today';

  @override
  String visitOrderLabel(int number) {
    return 'Visit order: $number';
  }

  @override
  String get selectClientTitle => 'Select client';

  @override
  String clientsAvailable(int count) {
    return '$count clients available';
  }

  @override
  String get searchByNameCodeInn => 'Name, code, INN, phone, type...';

  @override
  String get searchInCyrillicOrLatin => 'Search in Cyrillic or Latin';

  @override
  String foundCount(int count) {
    return '$count found';
  }

  @override
  String get clientNotFound => 'Client not found';

  @override
  String get tryDifferentSearch => 'Try a different search term';

  @override
  String get confirmButton => 'Confirm';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get newContractTitle => 'New contract';

  @override
  String get fillAllFields => 'Fill in all fields';

  @override
  String get contractTypesLoadError => 'Error loading contract types';

  @override
  String get pleaseSelectClient => 'Please select a client';

  @override
  String get pleaseSelectContractType => 'Please select a contract type';

  @override
  String get contractCreatedSuccessfully => 'Contract created successfully';

  @override
  String get contractCreationError => 'Error creating contract';

  @override
  String get documentInfoSection => 'Document information';

  @override
  String get regionInfoSection => 'Region information';

  @override
  String get referenceNumberField => 'Reference number';

  @override
  String get termLabel => 'Term';

  @override
  String get certificateNumberField => 'Certificate number';

  @override
  String get certificateUnlimitedField => 'Certificate unlimited';

  @override
  String get passportNumberField => 'Passport number';

  @override
  String get clientCodeLabel => 'Client code';

  @override
  String get organizationCodeLabel => 'Organization code';

  @override
  String get courierLabel => 'Courier';

  @override
  String get vehicleLabel => 'Vehicle';

  @override
  String get licensePlateLabel => 'License plate';

  @override
  String get supervisorCommentLabel => 'Supervisor comment';

  @override
  String get logistCommentLabel => 'Logist comment';

  @override
  String get agentCommentLabel => 'Agent comment';

  @override
  String get networkErrorMessage => 'Network error. Check your internet connection.';

  @override
  String get serverTimeoutMessage => 'Server connection timed out.';

  @override
  String get orderDetailsLoadError => 'Error loading order details.';

  @override
  String dataLoadFailed(String error) {
    return 'Data loading failed: $error';
  }

  @override
  String get brands => 'Brands';

  @override
  String get fileStoragePermission => 'File storage permission';

  @override
  String get fileStorageDescriptionAndroid13 => 'Select folder to save app data';

  @override
  String get fileStorageDescription => 'To save and load app data';

  @override
  String get fileStoragePurposeAndroid13 => 'Select folder to save images, documents and data';

  @override
  String get fileStoragePurpose => 'Save images, documents and data';

  @override
  String get locationPermissionTitle => 'Location permission';

  @override
  String get locationPermissionDescription => 'To sort trading points by distance';

  @override
  String get locationPermissionPurpose => 'Show location on map and calculate distance';

  @override
  String get alwaysLocationPermissionTitle => 'Always location permission';

  @override
  String get alwaysLocationPermissionDescription => 'To detect location when app is in background';

  @override
  String get alwaysLocationPermissionPurpose => 'Background service and notifications';

  @override
  String get cameraPermissionTitle => 'Camera permission';

  @override
  String get cameraPermissionDescription => 'To take photos and scan barcodes';

  @override
  String get cameraPermissionPurpose => 'Take photos of products and trading points';

  @override
  String get microphonePermissionTitle => 'Microphone permission';

  @override
  String get microphonePermissionDescription => 'For voice recording and audio messages';

  @override
  String get microphonePermissionPurpose => 'Voice notes and audio records';

  @override
  String get notificationPermissionTitle => 'Notification permission';

  @override
  String get notificationPermissionDescription => 'To show important messages';

  @override
  String get notificationPermissionPurpose => 'Reminders, news and notifications';

  @override
  String get audioPermissionTitle => 'Music and audio permission';

  @override
  String get audioPermissionDescription => 'To work with audio files';

  @override
  String get audioPermissionPurpose => 'Music, audio messages and voice files';

  @override
  String get photosAndVideosPermissionTitle => 'Photos and videos permission';

  @override
  String get photosAndVideosPermissionDescription => 'To work with media files';

  @override
  String get photosAndVideosPermissionPurpose => 'Work with photos, videos and media files';

  @override
  String permissionRequiredMessage(String description) {
    return '$description. Please grant permission in app settings.';
  }

  @override
  String get goToSettingsButton => 'Go to settings';

  @override
  String get grantPermissionButton => 'Grant permission';

  @override
  String get checkingPermission => 'Checking...';

  @override
  String get permissionCheckTitle => 'Permission check';

  @override
  String get permissionCheckMessage => 'The app needs the following permissions to work properly:';

  @override
  String get permissionSaveData => 'Save data';

  @override
  String get permissionMapDistance => 'Map and distance calculation';

  @override
  String get permissionTakePhotos => 'Take photos';

  @override
  String get permissionRecordVoice => 'Record voice';

  @override
  String get permissionShowMessages => 'Show messages';

  @override
  String get permissionLimitedMode => 'Without permissions the app will work in limited mode.';

  @override
  String purposeLabel(String purpose) {
    return 'Purpose: $purpose';
  }

  @override
  String get grantPermissionQuestion => 'Do you want to grant permission?';

  @override
  String get serviceInitError => 'Error initializing services';

  @override
  String get clientInnNotAvailable => 'Client INN not available';

  @override
  String get clientBalanceZero => 'Client balance is zero.';

  @override
  String get balanceDataNotFound => 'Balance data not found';

  @override
  String updatedAtTime(String time) {
    return 'Updated: $time';
  }

  @override
  String get clientDebtorStatus => 'Client is debtor';

  @override
  String get overpaymentStatus => 'Overpayment';

  @override
  String get balanceZeroStatus => 'Balance is zero';

  @override
  String get savingStatus => 'Saving...';

  @override
  String get unsavedChangesStatus => 'Unsaved changes';

  @override
  String get offlineStatus => 'Offline';

  @override
  String pendingSyncCount(int count) {
    return '$count pending sync';
  }

  @override
  String get allSyncedStatus => 'All synced';

  @override
  String get autoSaving => 'Auto-saving...';

  @override
  String get savingStepData => 'Saving step data...';

  @override
  String get mandatoryLabel => 'Mandatory';

  @override
  String get optionalLabel => 'Optional';

  @override
  String get currentLabel => 'Current';

  @override
  String get completedLabel => 'Completed';

  @override
  String get skippedLabel => 'Skipped';

  @override
  String notesLabel(String notes) {
    return 'Notes: $notes';
  }

  @override
  String reasonLabel(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get reasonHint => 'Reason';

  @override
  String get syncStarting => 'Starting sync...';

  @override
  String get weekdayMon => 'Mo';

  @override
  String get weekdayTue => 'Tu';

  @override
  String get weekdayWed => 'We';

  @override
  String get weekdayThu => 'Th';

  @override
  String get weekdayFri => 'Fr';

  @override
  String get weekdaySat => 'Sa';

  @override
  String get weekdaySun => 'Su';

  @override
  String get copyLabel => 'Copy';

  @override
  String get reloadLabel => 'Reload';

  @override
  String get refreshContractTypesAndRegions => 'Refresh contract types and regions';

  @override
  String get orderStatusNew => 'New';

  @override
  String get orderStatusConfirmed => 'Confirmed';

  @override
  String get orderStatusDelivering => 'In delivery';

  @override
  String get orderStatusReturnRequested => 'Return requested';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get orderStatusDeliveredUnpaid => 'Delivered, unpaid';

  @override
  String get orderStatusDeliveredPartiallyPaid => 'Delivered, partially paid';

  @override
  String get orderStatusUnknown => 'Unknown';

  @override
  String get filterTooltip => 'Filter';

  @override
  String get fullscreenTooltip => 'Fullscreen';

  @override
  String get refusalReasonClientNotAvailable => 'Client not available';

  @override
  String get refusalReasonNoTime => 'No time';

  @override
  String get refusalReasonProductNotNeeded => 'Product not needed';

  @override
  String get refusalReasonPriceNotSuitable => 'Price not suitable';

  @override
  String get refusalReasonWorksWithOtherSupplier => 'Works with other supplier';

  @override
  String get refusalReasonOther => 'Other reason';

  @override
  String get apiKeyStatusConfigured => 'configured';

  @override
  String get apiKeyStatusNotConfigured => 'Not configured';

  @override
  String get visited => 'Visited';

  @override
  String get plannedForToday => 'Planned for today';

  @override
  String get additionalInformation => 'Additional Information';

  @override
  String get locationInformation => 'Location Information';

  @override
  String get businessInformation => 'Business Information';

  @override
  String get apiKeyStatusNotRequired => 'key not required';

  @override
  String get apiKeyStatusError => 'error';

  @override
  String get fakturaFetchCompanyData => 'Load';

  @override
  String get fakturaRefreshCompanyData => 'Refresh';

  @override
  String get fakturaEnterInn => 'Please enter TIN number';

  @override
  String get fakturaInvalidInnFormat => 'Invalid TIN format. Must be 9 or 14 digits';

  @override
  String fakturaCompanyDataLoaded(String companyName) {
    return 'Company data successfully loaded: $companyName';
  }

  @override
  String fakturaRegionNotFound(String regionName) {
    return 'Region not found: $regionName. Please select manually';
  }

  @override
  String get fakturaAuthError => 'Authentication error';

  @override
  String get fakturaAuthErrorRetry => 'Authentication error. Please try again';

  @override
  String get fakturaCompanyNotFound => 'Company not found. Check TIN number';

  @override
  String get fakturaInvalidRequest => 'Invalid request. Check TIN format';

  @override
  String fakturaServerError(String statusCode) {
    return 'Server error: $statusCode';
  }

  @override
  String get fakturaInnEmpty => 'TIN cannot be empty';

  @override
  String get fakturaTokenRefreshError => 'Token refresh error';

  @override
  String get reportMenuTitle => 'Reports menu';

  @override
  String get reportAlreadySent => 'Report has already been sent to your Telegram group. Do you want to send it again?';

  @override
  String get reportSentSuccess => 'Report sent';

  @override
  String get resendReport => 'Resend';

  @override
  String get toggleHeaderShow => 'Show header';

  @override
  String get toggleHeaderHide => 'Hide header';

  @override
  String get periodNotSelected => 'Period not selected';

  @override
  String get dataSyncing => 'Syncing data...';

  @override
  String get reportsUpdated => 'Reports updated';

  @override
  String get applyButton => 'Apply';

  @override
  String get reportMainEvyap => 'Main reports(for EVYAP)';

  @override
  String get reportMainEvyapDesc => 'KPI indicators and main statistics';

  @override
  String get reportVisits => 'Visits report';

  @override
  String get reportVisitsDesc => 'Information about visits to clients';

  @override
  String get reportAkbClient => 'AKB Client';

  @override
  String get reportAkbClientDesc => 'Report on AKB clients';

  @override
  String get reportAkbSum => 'AKB Sum';

  @override
  String get reportAkbSumDesc => 'Financial report on AKB amounts';

  @override
  String get reportAkbProduct => 'AKB Product';

  @override
  String get reportAkbProductDesc => 'Report on AKB products';

  @override
  String get reportCategory => 'Category reports';

  @override
  String get reportCategoryDesc => 'Sales analysis by categories';

  @override
  String get reportMonthlyResults => 'Monthly results';

  @override
  String get reportMonthlyResultsDesc => 'Monthly sales results and trends';

  @override
  String get reportMonthlyKpi => 'Monthly KPI (salary)';

  @override
  String get reportMonthlyKpiDesc => 'Monthly KPI completion and salary report';

  @override
  String get akbAmount => 'AKB amount';

  @override
  String get akbProducts => 'AKB products';

  @override
  String get productTypes => 'Product types';

  @override
  String get categoriesCount => 'Categories count';

  @override
  String get topSelling => 'Top selling';

  @override
  String get monthlySales => 'Monthly sales';

  @override
  String get monthlyGrowth => 'Monthly growth';

  @override
  String get kpiCompletion => 'KPI completion';

  @override
  String get salaryAmount => 'Salary amount';

  @override
  String get scannerTitle => 'Document Scanner';

  @override
  String get scannerSubtitle => 'Scan certificate to auto-fill form';

  @override
  String get scannerTakePhoto => 'Take Photo';

  @override
  String get scannerChoosePhoto => 'Gallery';

  @override
  String get scannerProcessing => 'Analyzing document...';

  @override
  String get scannerPleaseWait => 'AI is extracting data from the image';

  @override
  String scannerDataExtracted(int count) {
    return '$count fields extracted successfully';
  }

  @override
  String get scannerCameraError => 'Failed to access camera. Please check permissions';

  @override
  String get scannerGalleryError => 'Failed to access gallery. Please check permissions';

  @override
  String get scannerImageEmpty => 'Selected image is empty or corrupted';

  @override
  String get scannerNetworkError => 'Network error. Please check your internet connection';

  @override
  String get scannerAuthError => 'AI service authentication failed. Please try again';

  @override
  String get scannerRateLimitError => 'Too many requests. Please wait a moment';

  @override
  String get scannerNoDataExtracted => 'Could not extract data from the document. Please try a clearer image';

  @override
  String get scannerParseError => 'Failed to process AI response. Please try again';

  @override
  String get scannerUnknownError => 'An unexpected error occurred. Please try again';

  @override
  String get scannerFormUpdated => 'Form updated with scanned data';

  @override
  String get scannerVerifyingWithFaktura => 'Verifying data with Faktura.uz...';

  @override
  String get scannerDataVerified => 'Data verified and updated from Faktura.uz';

  @override
  String scannerDataMismatch(int count) {
    return '$count fields updated from Faktura.uz';
  }

  @override
  String get productImageLoading => 'Loading image...';

  @override
  String get productImageError => 'Failed to load image';

  @override
  String get productNoImage => 'No image available';

  @override
  String productImageSyncProgress(int current, int total) {
    return 'Syncing images: $current/$total';
  }

  @override
  String get productImageSyncComplete => 'Image sync complete';

  @override
  String get productImageSyncFailed => 'Image sync failed';

  @override
  String get productImageTapToView => 'Tap to view full image';

  @override
  String productImageCount(int count) {
    return '$count images';
  }

  @override
  String get productBasicInfo => 'Basic Information';

  @override
  String get productPricingInfo => 'Pricing Information';

  @override
  String get productStockInfo => 'Stock Information';

  @override
  String get productAdditionalInfo => 'Additional Information';

  @override
  String get productCode => 'Product Code';

  @override
  String get productVendorCode => 'Article';

  @override
  String get productBarcode => 'Barcode';

  @override
  String get productCategory => 'Category';

  @override
  String get productSeries => 'Series';

  @override
  String get productPriceType => 'Price Type';

  @override
  String get productPrice => 'Price';

  @override
  String get productPriceValidFrom => 'Valid From';

  @override
  String get productPriceValidTo => 'Valid To';

  @override
  String get productWarehouse => 'Warehouse';

  @override
  String get productStock => 'Stock';

  @override
  String get productQuantity => 'Total Quantity';

  @override
  String get productReserved => 'Reserved';

  @override
  String get productAvailable => 'Available';

  @override
  String get productUnit => 'Unit';

  @override
  String get productWeight => 'Weight';

  @override
  String get productCapacity => 'Capacity';

  @override
  String get productBrand => 'Brand';

  @override
  String get productProject => 'Project Code';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get productInfoCopied => 'Product information copied';

  @override
  String get checkingCache => 'Checking cache...';

  @override
  String get loadingFromDatabase => 'Loading from database...';

  @override
  String get syncingFromServer => 'Syncing from server...';

  @override
  String get databaseEmpty => 'No orders found locally';

  @override
  String get databaseEmptyDescription => 'Would you like to sync orders from the server?';

  @override
  String get syncFromServer => 'Sync from Server';

  @override
  String get refreshingData => 'Refreshing data...';

  @override
  String get dataLoadedFromCache => 'Data loaded from cache';

  @override
  String get dataLoadedFromDatabase => 'Data loaded from database';

  @override
  String get dataSyncedFromServer => 'Orders synced successfully';

  @override
  String get syncFailed => 'Sync failed. Please try again.';

  @override
  String get noInternetForSync => 'No internet connection. Please check your network.';

  @override
  String get retrySync => 'Retry';

  @override
  String lastUpdated(String time) {
    return 'Last updated: $time';
  }

  @override
  String get connectionRestored => 'Connection restored';

  @override
  String get youAreOffline => 'You are offline';

  @override
  String get lineTotal => 'Line Total';

  @override
  String get totalMismatchWarning => 'Calculated total differs from server value';

  @override
  String get bonus => 'Bonus';

  @override
  String get unitPrice => 'Unit Price';

  @override
  String get orderTotalMismatch => 'Order total mismatch detected';

  @override
  String get accessControlTitle => 'Access Verification';

  @override
  String get accessControlChecking => 'Verifying access...';

  @override
  String get accessControlCheckingInternet => 'Checking internet connection...';

  @override
  String get accessControlVerifyingTime => 'Verifying time...';

  @override
  String get accessControlGranted => 'Access granted';

  @override
  String get accessControlDenied => 'Access denied';

  @override
  String get accessExpired => 'Access Expired';

  @override
  String get accessExpiredMessage => 'Your access period has expired. Please contact support to renew access.';

  @override
  String accessExpiredDate(String date) {
    return 'Expired on: $date';
  }

  @override
  String accessValidUntil(String date) {
    return 'Valid until: $date';
  }

  @override
  String accessDaysRemaining(int days) {
    return '$days days remaining';
  }

  @override
  String get accessTimeManipulation => 'Time Manipulation Detected';

  @override
  String get accessTimeManipulationMessage => 'Device time has been manipulated. Please ensure your device time is set correctly.';

  @override
  String get accessInternetRequired => 'Internet Required';

  @override
  String get accessInternetRequiredMessage => 'Internet connection is required for first-time setup. Please connect to the internet and try again.';

  @override
  String get accessOfflineMode => 'Offline Mode';

  @override
  String get accessOfflineModeMessage => 'You are using the app in offline mode. Some features may be limited.';

  @override
  String get accessVerificationError => 'Verification Error';

  @override
  String get accessVerificationErrorMessage => 'An error occurred while verifying access. Please try again.';

  @override
  String get accessContactSupport => 'Contact Support';

  @override
  String get accessRetry => 'Retry';

  @override
  String get accessExit => 'Exit';

  @override
  String get accessCheckingStatus => 'Checking access status...';

  @override
  String get accessWaitingForInternet => 'Waiting for internet connection...';

  @override
  String get accessVerifyingWithServer => 'Verifying with server...';

  @override
  String get accessLoadingApp => 'Loading application...';

  @override
  String get accessWarningExpiringSoon => 'Access Expiring Soon';

  @override
  String accessWarningExpiringSoonMessage(int days) {
    return 'Your access will expire in $days days. Please contact support to renew.';
  }

  @override
  String get accessContinue => 'Continue';

  @override
  String get accessRemindLater => 'Remind Later';

  @override
  String get accessNoInternetOfflineCheck => 'No internet connection. Using offline verification.';

  @override
  String get accessInternetRestored => 'Internet connection restored. Verifying...';

  @override
  String get accessCleaningData => 'Cleaning up data...';

  @override
  String get accessRevoking => 'Revoking access...';

  @override
  String get syncRequiredFirstTime => 'Sync required for first login';

  @override
  String get syncRecommended => 'Data sync recommended';

  @override
  String get goToSyncSettings => 'Open sync settings to update data';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get initialSyncRequired => 'Data Synchronization Required';

  @override
  String get initialSyncMessage => 'This is your first login. We need to download essential data to get started. This may take a few minutes.';

  @override
  String get dataSyncRequired => 'Data Synchronization Required';

  @override
  String get dataSyncMessage => 'Your local data needs to be updated. Would you like to synchronize now?';

  @override
  String get startSync => 'Start Sync';

  @override
  String get syncLater => 'Later';

  @override
  String get syncCompleteMessage => 'Data synchronization completed successfully!';

  @override
  String get syncWillContinueBackground => 'Sync will continue in the background';

  @override
  String get geminiApiKeyNotFound => 'Gemini API key not configured';

  @override
  String get geminiNetworkError => 'Network error occurred. Please check your connection';

  @override
  String get geminiAuthError => 'Authentication failed. Please check your API key in settings';

  @override
  String get geminiRateLimitError => 'Rate limit exceeded. Please try again in a few minutes';

  @override
  String get geminiServerError => 'Server error occurred. Please try again later';

  @override
  String get geminiTimeoutError => 'Request timeout. Please check your internet connection';

  @override
  String get geminiApiKeyConfigured => 'Gemini API key configured successfully';

  @override
  String get geminiApiKeyLabel => 'Gemini API Key';

  @override
  String get geminiApiKeyHint => 'Enter your Gemini API key (starts with AIza)';

  @override
  String get geminiApiKeyDescription => 'Used for document scanning and AI features';

  @override
  String get geminiApiKeyInvalid => 'Invalid API key format. Key should start with \'AIza\'';

  @override
  String get syncOptimizedMode => 'Optimized sync mode';

  @override
  String syncParallelProgress(int count) {
    return 'Syncing $count tables in parallel...';
  }

  @override
  String get syncDeltaMode => 'Incremental update';

  @override
  String syncSkippedUnchanged(int count) {
    return 'Skipped $count unchanged records';
  }

  @override
  String syncInserted(int count) {
    return '$count new records added';
  }

  @override
  String syncUpdated(int count) {
    return '$count records updated';
  }

  @override
  String syncDeleted(int count) {
    return '$count records removed';
  }

  @override
  String syncLevelProgress(int level, int total, String tables) {
    return 'Level $level/$total: $tables';
  }

  @override
  String syncCacheSaved(int count) {
    return 'Saved $count duplicate API calls';
  }

  @override
  String syncOptimizedComplete(String seconds) {
    return 'Optimized sync completed in ${seconds}s';
  }

  @override
  String get serverConnectionFailed => 'Server connection failed';

  @override
  String get tryingAlternativeServer => 'Trying alternative server...';

  @override
  String get connectedToAlternativeServer => 'Connected to alternative server';

  @override
  String get allServersUnavailable => 'All servers are unavailable';

  @override
  String get checkInternetConnection => 'Please check your internet connection';

  @override
  String get usingFallbackServer => 'Using backup server';

  @override
  String get primaryServerRestored => 'Primary server connection restored';

  @override
  String serverSwitchedTo(String url) {
    return 'Server switched to: $url';
  }

  @override
  String get retryingPrimaryServer => 'Retrying primary server...';

  @override
  String connectionAttempt(int current, int total) {
    return 'Connection attempt $current/$total';
  }

  @override
  String serverUrlInfo(String name, String type) {
    return 'Server: $name ($type)';
  }

  @override
  String get primaryServer => 'Primary';

  @override
  String get backupServer => 'Backup';

  @override
  String get visitDuration => 'Visit Duration';

  @override
  String get stepDuration => 'Step Duration';

  @override
  String get totalVisitTime => 'Total Visit Time';

  @override
  String get stepTime => 'Step Time';

  @override
  String get elapsedTime => 'Elapsed Time';

  @override
  String get timeLimitExpired => 'Access Period Expired';

  @override
  String get timeLimitExpiredMessage => 'Your access period has expired. Please contact support to renew your access.';

  @override
  String get timeLimitExpiredNote => 'All local data will be cleared for security.';

  @override
  String get offlineAccessBlocked => 'Internet Connection Required';

  @override
  String get offlineAccessBlockedMessage => 'First-time access requires an internet connection. Please connect and try again.';

  @override
  String get offlineAccessBlockedNote => 'After first connection, you can use the app offline.';

  @override
  String get offlineAccessNoLimit => 'Offline Access Unavailable';

  @override
  String get offlineAccessNoLimitMessage => 'You need to connect to the internet at least once before using offline mode.';

  @override
  String get retryConnection => 'Retry Connection';

  @override
  String get connectToInternet => 'Connect to Internet';

  @override
  String get verifyingAccess => 'Verifying access...';

  @override
  String get accessVerified => 'Access verified successfully';

  @override
  String get verificationFailed => 'Verification failed';

  @override
  String get timeLimitUpdated => 'Access period updated';

  @override
  String get promoOrder => 'Promo Order';

  @override
  String get marketingDataRefreshing => 'Marketing data is refreshing...';

  @override
  String get announcements => 'Announcements';

  @override
  String get news => 'News';

  @override
  String get announcementsPage => 'Announcements page';

  @override
  String get newsPage => 'News page';

  @override
  String get pricesPage => 'Prices page';

  @override
  String dataLoadingErrorWithMessage(String error) {
    return 'Error loading data: $error';
  }

  @override
  String promotionsRefreshError(String error) {
    return 'Error refreshing promotions: $error';
  }

  @override
  String refreshErrorWithMessage(String error) {
    return 'Refresh error: $error';
  }

  @override
  String get offlineModeShowingCachedData => 'Offline mode - showing cached data';

  @override
  String get promotionsNotFound => 'No promotions found';

  @override
  String promotionDescriptionFormat(String type, int productCount, int bonusCount) {
    return '$type promotion. $productCount products, $bonusCount bonuses.';
  }

  @override
  String get aboutPromotion => 'About promotion';

  @override
  String promotionOfType(String type) {
    return '$type type promotion';
  }

  @override
  String participatingProductsCount(int count) {
    return 'Products participating in promotion: $count SKU';
  }

  @override
  String bonusProductsCount(int count) {
    return 'Products available as bonus: $count SKU';
  }

  @override
  String get bonuses => 'Bonuses';

  @override
  String get productClass => 'Class';

  @override
  String get salesChannel => 'Sales Channel';

  @override
  String get salesChannelRequired => 'Sales Channel *';

  @override
  String get clientClass => 'Client Class';

  @override
  String get clientClassRequired => 'Client Class *';

  @override
  String get tradingPointTypeRequired => 'Trading Point Type *';

  @override
  String get regionRequired => 'Region *';

  @override
  String get pleaseSelectSalesChannel => 'Please select sales channel';

  @override
  String get pleaseSelectClientClass => 'Please select client class';

  @override
  String get salesChannelsLoading => 'Loading channels...';

  @override
  String get clientClassesLoading => 'Loading classes...';

  @override
  String get tradingPointTypesLoading => 'Loading trading point types...';

  @override
  String get pleaseSelectChannelFirst => 'Please select channel first';

  @override
  String get tradingPointTypesLoadError => 'Error loading trading point types';

  @override
  String get initialOrderSettings => 'Initial Order Settings';

  @override
  String get initialOrderSettingsDescription => 'Please configure the following settings before creating your first order. These settings will be used as defaults for this order.';

  @override
  String get selectOrganization => 'Select Organization';

  @override
  String get selectWarehouse => 'Select Warehouse';

  @override
  String get organizationRequired => 'Organization is required';

  @override
  String get warehouseRequired => 'Warehouse is required';

  @override
  String get priceTypeRequired => 'Price type is required';

  @override
  String get continueToOrder => 'Continue to Order';

  @override
  String get settingsNotComplete => 'Please complete all required settings';

  @override
  String get noOrganizationsAvailable => 'No organizations available';

  @override
  String get noWarehousesAvailable => 'No warehouses available';

  @override
  String get noPriceTypesAvailable => 'No price types available';

  @override
  String get userInactive => 'Your account is inactive. Contact your administrator.';

  @override
  String userOutsideActiveWindow(String start, String end) {
    return 'Access window: $start – $end';
  }

  @override
  String get licenseExpired => 'Your organization\'s license has expired.';

  @override
  String get licenseMissing => 'Your organization has no active license.';

  @override
  String licenseSeatExceeded(int rank, int seatCount) {
    return 'All license seats are taken (you are #$rank of $seatCount).';
  }

  @override
  String get clockTamperingDetected => 'Device clock changed. Please reconnect to verify access.';

  @override
  String get noInternetForFirstLogin => 'First-time login requires an internet connection.';

  @override
  String get mobileDeviceBoundToOtherUser => 'This device is bound to another user. Ask your administrator to release the binding.';

  @override
  String get mobileUserBoundToOtherDevice => 'Your account is already bound to another phone. Ask your administrator to release the old binding so you can sign in on this device.';

  @override
  String get deviceBindingInvalid => 'Your device session is no longer valid. Please sign in again.';

  @override
  String get sessionRevoked => 'Your session has been revoked. Please sign in again.';

  @override
  String get oneCUserNotFound => 'This account is not registered in the operations system. Contact your administrator.';

  @override
  String debugBackendUrl(String url) {
    return 'Backend: $url';
  }

  @override
  String get debugTestConnection => 'Test connection';

  @override
  String debugConnectionOk(int ms) {
    return 'OK · ${ms}ms';
  }

  @override
  String debugConnectionFailed(String reason) {
    return 'Failed: $reason';
  }

  @override
  String get imageNotAvailable => 'Image not available';

  @override
  String get imageProcessing => 'Image is being processed';

  @override
  String get imageLoadFailed => 'Could not load image';

  @override
  String get imageLoadRetry => 'Retry';

  @override
  String get projectImageEmpty => 'No images yet';

  @override
  String get knowledgeBaseTitle => 'Knowledge Base';

  @override
  String get knowledgeBaseSubtitle => 'Regulations, guides, and training';

  @override
  String get knowledgePinnedSection => 'Pinned';

  @override
  String get knowledgeCategoriesSection => 'Categories';

  @override
  String get knowledgeCategoryEmpty => 'No documents in this category';

  @override
  String get knowledgeDocumentLoading => 'Loading document…';

  @override
  String get knowledgeDocumentNotFound => 'Document not found';

  @override
  String get knowledgeNoDocumentsAssigned => 'No documents available yet';

  @override
  String get knowledgeSearchTitle => 'Search';

  @override
  String get knowledgeSearchPlaceholder => 'Search documents…';

  @override
  String get knowledgeSearchEmpty => 'Nothing matched your query';

  @override
  String get knowledgeRetry => 'Retry';

  @override
  String get knowledgeOfflineNotice => 'You\'re offline. Showing cached content.';

  @override
  String get knowledgeTocTitle => 'Table of contents';

  @override
  String get knowledgeOpenInBrowser => 'Open in browser';

  @override
  String get knowledgeFilterAll => 'All';

  @override
  String get knowledgePinnedBadge => 'Pinned';

  @override
  String get knowledgeMandatoryBadge => 'Mandatory';

  @override
  String get customerPhotos_title => 'Customer photos';

  @override
  String get customerPhotos_addAction => 'Add photo';

  @override
  String get customerPhotos_replaceAction => 'Replace';

  @override
  String get customerPhotos_deleteAction => 'Delete';

  @override
  String get customerPhotos_setPrimary => 'Set as primary';

  @override
  String get customerPhotos_reprocess => 'Reprocess';

  @override
  String customerPhotos_capBadge(int current, int max) {
    return '$current/$max uploaded';
  }

  @override
  String customerPhotos_capExceeded(int current, int max) {
    return 'Limit reached ($current/$max)';
  }

  @override
  String get customerPhotos_emptyState => 'No photos yet';

  @override
  String get customerPhotos_uploading => 'Uploading…';

  @override
  String get customerPhotos_processing => 'Processing…';

  @override
  String get customerPhotos_failed => 'Failed';

  @override
  String customerPhotos_failedBannerTitle(int count) {
    return '$count photos failed';
  }

  @override
  String get customerPhotos_reprocessNotSupported => 'Reprocessing not supported — delete and re-upload';

  @override
  String get customerPhotos_err_tooLarge => 'File is larger than 15 MB';

  @override
  String get customerPhotos_err_invalidFormat => 'Format not supported: JPEG, PNG, WebP, HEIC';

  @override
  String get customerPhotos_err_dimensionsTooSmall => 'Dimensions smaller than 200×200';

  @override
  String get customerPhotos_err_dimensionsTooLarge => 'Dimensions larger than 8000×8000';

  @override
  String get customerPhotos_err_notFound => 'Photo not found';

  @override
  String get customerPhotos_err_permissionDenied => 'No permission';

  @override
  String get customerPhotos_err_unknown => 'Something went wrong';

  @override
  String get customerPhotos_err_endpointNotImplemented => 'Customer photo service is not yet available on the server. Contact the development team.';

  @override
  String get customerPhotos_pickCamera => 'Camera';

  @override
  String get customerPhotos_pickGallery => 'Gallery';

  @override
  String get customerPhotos_editAlt => 'Description';

  @override
  String get customerPhotos_save => 'Save';

  @override
  String get customerPhotos_confirmDeleteTitle => 'Delete this photo?';

  @override
  String get customerPhotos_confirmDeleteBody => 'This action cannot be undone.';

  @override
  String get customerPhotos_primaryBadge => 'Primary';

  @override
  String get customerEdit_title => 'Edit customer';

  @override
  String get customerCreate_title => 'New customer';

  @override
  String get customerEdit_field_name => 'Name';

  @override
  String get customerEdit_field_inn => 'INN';

  @override
  String get customerEdit_field_phone => 'Phone';

  @override
  String get customerEdit_field_address => 'Address';

  @override
  String get customerEdit_save => 'Save';

  @override
  String get customerEdit_cancel => 'Cancel';

  @override
  String get customerEdit_nameRequired => 'Name is required';

  @override
  String get customerCoordinates_title => 'Edit location';

  @override
  String get customerCoordinates_useGps => 'Use current location';

  @override
  String get customerCoordinates_save => 'Save';

  @override
  String get customerCoordinates_field_latitude => 'Latitude';

  @override
  String get customerCoordinates_field_longitude => 'Longitude';

  @override
  String get customerCoordinates_invalid => 'Invalid coordinates (lat: -90..90, lng: -180..180)';

  @override
  String get customerCoordinates_gpsUnavailable => 'Could not read GPS position';

  @override
  String get customerEditTooltip => 'Edit customer profile';

  @override
  String get customerCoordinatesEditTooltip => 'Edit location';

  @override
  String get customerPhotosEditTooltip => 'Customer photos';

  @override
  String get customerCreateTooltip => 'Add new customer';

  @override
  String get customer_err_crossOrg => 'This customer belongs to another organization';

  @override
  String get customer_err_permissionDenied => 'No permission';

  @override
  String get customer_err_notFound => 'Customer not found';

  @override
  String get customer_err_idempotencyConflict => 'Retry failed. Please try again.';

  @override
  String get customer_err_invalidCoordinates => 'Invalid coordinates (lat: -90..90, lng: -180..180)';

  @override
  String get customer_err_network => 'Network error. Please check your connection.';

  @override
  String get customer_err_unknown => 'Something went wrong';

  @override
  String get backendPermissions_sectionTitle => 'Backend permissions';

  @override
  String get backendPermissions_sectionSubtitle => 'Codenames received from the server in the JWT `gates.permissions` field';

  @override
  String get backendPermissions_categoryCustomers => 'Customer profile';

  @override
  String get backendPermissions_categoryPhotos => 'Customer photos';

  @override
  String get backendPermissions_optimisticBadge => 'Optimistic (server has not yet shipped the field)';

  @override
  String backendPermissions_grantedBadge(int granted, int total) {
    return '$granted/$total granted';
  }

  @override
  String get backendPermissions_granted => 'Granted';

  @override
  String get backendPermissions_denied => 'Denied';

  @override
  String get backendPermissions_label_customerAdd => 'Add new customer';

  @override
  String get backendPermissions_label_customerChange => 'Edit customer profile';

  @override
  String get backendPermissions_label_customerChangeCoordinates => 'Edit customer location';

  @override
  String get backendPermissions_label_customerAddPhoto => 'Upload customer photo';

  @override
  String get backendPermissions_label_customerChangePhoto => 'Edit photo metadata';

  @override
  String get backendPermissions_label_customerDeletePhoto => 'Delete customer photo';

  @override
  String get backendPermissions_label_customerReplacePhoto => 'Replace customer photo';

  @override
  String get backendPermissionsSync_title => 'Backend permissions';

  @override
  String get backendPermissionsSync_subtitle => 'Synced from `gates.permissions` on every login / token refresh';

  @override
  String get backendPermissionsSync_neverSynced => 'Not yet synced — log in to refresh';

  @override
  String get backendPermissionsSync_status_ok => 'Synced successfully';

  @override
  String get backendPermissionsSync_status_failed => 'Sync failed';

  @override
  String backendPermissionsSync_lastSync(String when) {
    return 'Last sync: $when';
  }

  @override
  String backendPermissionsSync_countLine(int granted, int total) {
    return '$granted of $total permission(s) granted';
  }

  @override
  String backendPermissionsSync_errorLine(String code) {
    return 'Last error: $code';
  }

  @override
  String get customerPhotoPreview_emptyTitle => 'No photos yet';

  @override
  String get customerPhotoPreview_emptyHintAdd => 'Tap to add the first photo';

  @override
  String get customerPhotoPreview_emptyHintReadOnly => 'No photos uploaded for this customer';

  @override
  String get customerPhotoPreview_editTooltip => 'Manage photos';

  @override
  String get customerPhotoPreview_addTooltip => 'Add photo';

  @override
  String get customerEditBanner_title => 'Edit customer info';

  @override
  String get customerEditBanner_body => 'Name, INN, phone and address are updated here. Coordinates change via the map button, photos via the gallery. Classifier fields (region / channel / type / class) come from 1C and stay read-only on mobile.';

  @override
  String get coordinatesSave_err_permission_perCustomer => 'You are not assigned as the agent for this customer, so you can not move its pin. Contact the supervisor to be added as staff for this customer.';

  @override
  String get coordinatesSave_err_crossOrg => 'This customer belongs to another organization.';

  @override
  String get coordinatesSave_err_notFound => 'Customer not found on the server.';

  @override
  String get coordinatesSave_err_invalidCoords => 'Invalid coordinates (lat: -90..90, lng: -180..180).';

  @override
  String get coordinatesSave_err_network => 'Network error. Check your connection and try again.';

  @override
  String get coordinatesSave_err_serverError => 'Server error (500). Contact the dev team — backend is raising a ValidationError.';

  @override
  String coordinatesSave_err_generic(String detail) {
    return 'Could not save location: $detail';
  }

  @override
  String customerCreate_err_oneCBusiness(String message) {
    return '1C rejected this customer: $message';
  }

  @override
  String get customerCreate_err_oneCTransport => 'Could not reach 1C. Try again.';

  @override
  String get customerCreate_err_oneCNoEndpoint => '1C integration is not configured. Contact admin.';

  @override
  String get notif_title => 'Notification';

  @override
  String get notif_listTitle => 'Notifications';

  @override
  String get notif_settings => 'Settings';

  @override
  String get notif_markAllReadTooltip => 'Mark all as read';

  @override
  String get notif_markAllReadButton => 'Mark all read';

  @override
  String get notif_emptyTitle => 'No notifications';

  @override
  String get notif_untitled => '(Untitled)';

  @override
  String get notif_detailNotFound => 'This notification was not found or has expired.';

  @override
  String get notif_tabletPlaceholder => 'Pick a notification on the left to see details.';

  @override
  String get notif_bellSemantics => 'Notifications';

  @override
  String notif_bellSemanticsWithUnread(int count) {
    return 'Notifications ($count unread)';
  }

  @override
  String get notif_markAllReadDialogTitle => 'Mark all as read';

  @override
  String get notif_markAllReadDialogBody => 'Mark every unread notification as read?';

  @override
  String get notif_markAllReadConfirm => 'Yes, mark all';

  @override
  String get notif_rowMarkUnread => 'Mark as unread';

  @override
  String get notif_rowSnooze1h => 'Snooze 1 hour';

  @override
  String get notif_rowSnooze4h => 'Snooze 4 hours';

  @override
  String get notif_rowSnoozeTomorrow => 'Until tomorrow morning';

  @override
  String get notif_type_debtAlert => 'Debt alerts';

  @override
  String get notif_type_orderNew => 'New orders';

  @override
  String get notif_type_stockLotExpiring => 'Lot expiring';

  @override
  String get notif_type_systemAnnouncement => 'System announcements';

  @override
  String get notif_typeShort_debtAlert => 'Debt';

  @override
  String get notif_typeShort_orderNew => 'Order';

  @override
  String get notif_typeShort_stockLotExpiring => 'Lot';

  @override
  String get notif_typeShort_systemAnnouncement => 'Announcement';

  @override
  String get notif_typeDesc_debtAlert => 'Notifications about customer debt';

  @override
  String get notif_typeDesc_orderNew => 'Alerts for new orders';

  @override
  String get notif_typeDesc_stockLotExpiring => 'Warehouse lot expiry warnings';

  @override
  String get notif_typeDesc_systemAnnouncement => 'System and management updates';

  @override
  String get notif_priority_urgent => 'Urgent';

  @override
  String get notif_priority_high => 'High';

  @override
  String get notif_priority_normal => 'Normal';

  @override
  String get notif_priority_low => 'Low';

  @override
  String get notif_action_openCustomer => 'Open customer';

  @override
  String get notif_action_openOrder => 'Open order';

  @override
  String get notif_action_openGeneric => 'Open';

  @override
  String get notif_prefsTitle => 'Notification preferences';

  @override
  String get notif_prefsSection_types => 'Notification types';

  @override
  String get notif_prefsSection_dnd => 'Do not disturb (DND)';

  @override
  String get notif_prefsSection_sound => 'Sound and vibration';

  @override
  String get notif_dnd_toggleTitle => 'Do not disturb';

  @override
  String get notif_dnd_hint => 'The banner stays hidden during the chosen window';

  @override
  String get notif_dnd_startLabel => 'Start';

  @override
  String get notif_dnd_endLabel => 'End';

  @override
  String get notif_sound_silent => 'Silent';

  @override
  String get notif_sound_vibrate => 'Vibrate';

  @override
  String get notif_sound_sound => 'Sound';

  @override
  String get projectDebtLimits_sectionTitle => 'Projects and debt limits';

  @override
  String get projectDebtLimits_sectionSubtitle => 'Projects assigned to you and their configured debt limits';

  @override
  String get projectDebtLimits_offlineNotice => 'Device is offline — values shown are from the local cache';

  @override
  String get projectDebtLimits_errorNotice => 'Could not refresh limits from the server';

  @override
  String get projectDebtLimits_emptyState => 'No projects assigned to you yet';

  @override
  String get projectDebtLimits_lastUpdatedLabel => 'Last updated';

  @override
  String get projectDebtLimits_neverUpdated => 'Never updated';

  @override
  String get projectDebtLimits_refreshTooltip => 'Refresh limits';

  @override
  String get projectDebtLimits_noLimit => 'No limit configured';

  @override
  String get projectDebtLimits_limitUnavailable => 'Limit unavailable';

  @override
  String projectDebtLimits_loadingError(String message) {
    return 'Failed to load: $message';
  }

  @override
  String get projectDebtLimits_refreshing => 'Refreshing…';

  @override
  String get projectDebtLimits_refreshSuccess => 'Limits refreshed';

  @override
  String projectDebtLimits_countBadge(int count) {
    return '$count projects';
  }

  @override
  String get projectDebtLimits_userCodeMissing => 'User code not found';

  @override
  String get projectDebtLimits_limitLabel => 'Debt limit';

  @override
  String get projectsTab_title => 'Projects';

  @override
  String get projectsTab_sectionTitle => 'Active project and switching';

  @override
  String get projectsTab_pickerSubtitle => 'Pick another project from the list below to switch';

  @override
  String get projectsTab_activeLabel => 'Active project';

  @override
  String get projectsTab_scopeOrganization => 'Organization scope';

  @override
  String get projectsTab_scopeProject => 'Project scope';

  @override
  String projectsTab_switchedSnackbar(String name) {
    return 'Active project: $name';
  }

  @override
  String get projectsTab_empty => 'No projects assigned to you';

  @override
  String projectsTab_loadError(String message) {
    return 'Failed to load projects: $message';
  }

  @override
  String get timeAgoJustNow => 'just now';

  @override
  String timeAgoMinutes(int minutes) {
    return '$minutes min ago';
  }

  @override
  String timeAgoHours(int hours) {
    return '$hours h ago';
  }

  @override
  String timeAgoDays(int days) {
    return '$days d ago';
  }

  @override
  String get balanceStatusBalanceLabel => 'Balance';

  @override
  String get balanceStatusLimitLabel => 'Limit';

  @override
  String get balanceStatusLimitNone => 'No limit';

  @override
  String get balanceStatusLastUpdatedLabel => 'Last updated';

  @override
  String get balanceStatusRefreshButton => 'Refresh';

  @override
  String get balanceStatusHeadlineOverLimit => 'Debt above the limit';

  @override
  String get balanceStatusHeadlineUnderLimit => 'Debt within the limit';

  @override
  String get balanceStatusHeadlineOk => 'No debt';

  @override
  String get balanceStatusHeadlineUnknown => 'Status unknown';

  @override
  String get balanceStatusIndicatorSemantic => 'Customer balance status';

  @override
  String get debtBlockedTitle => 'Order blocked';

  @override
  String get debtBlockedNoCachedBalance => 'Customer balance is not available offline. Connect to the network and refresh.';

  @override
  String debtBlockedBodyOnline(String balance, String limit, String currency) {
    return 'Customer debt is $balance $currency, which exceeds the limit of $limit $currency.';
  }

  @override
  String debtBlockedBodyOffline(String balance, String limit, String age) {
    return 'Last known debt is $balance (limit $limit), updated $age.';
  }

  @override
  String get debtBlockedStaleWarning => 'Balance data may be out of date.';

  @override
  String get pendingBlockedOrdersTitle => 'Orders blocked by debt';

  @override
  String get orderBlockedByDebtBadge => 'Blocked by debt limit';

  @override
  String pendingBlockedOrdersCreatedAt(String date) {
    return 'Created $date';
  }

  @override
  String get retrySyncButton => 'Retry';
}
