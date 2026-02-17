class RouteNames {
  // Auth Routes

  // Auth Routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String verifyPhone = '/verify-phone';
  static const String kycVerification = '/kyc-verification';

  // Dashboard
  static const String dashboard = '/dashboard'; // Legacy - redirects based on role
  static const String clientDashboard = '/client/dashboard';
  static const String adminDashboard = '/admin-dashboard'; // Modified from /admin/dashboard

  // Dashboard-related routes
  static const String installments = '/installments'; // Moved from Subscriptions & Installments
  static const String documents = '/documents'; // Moved from Documents
  static const String constructionUpdates = '/construction-updates'; // Moved from Construction

  // Projects
  static const String projectsList = '/projects';
  static const String projectDetail = '/project-detail';
  static const String projectLocationMap = '/project-location-map';
  static const String createProject = '/create-project';
  static const String editProject = '/edit-project';

  // Join Flow
  static const String selectUnit = '/select-unit';
  static const String contractSummary = '/contract-summary';
  static const String payment = '/payment';
  static const String eSignature = '/e-signature';
  static const String signature = '/signature';
  static const String joinConfirmation = '/join-confirmation';

  // Wallet
  static const String wallet = '/wallet';
  static const String addFunds = '/add-funds';
  static const String withdrawFunds = '/withdraw-funds';
  static const String transactionHistory = '/transaction-history';

  // Subscriptions & Installments
  static const String subscriptions = '/subscriptions';
  static const String subscriptionDetail = '/subscription-detail';
  static const String installmentDetail = '/installment-detail';

  // Units
  static const String units = '/units';
  static const String unitDetail = '/unit-detail';

  // Construction
  static const String constructionTracking = '/construction-tracking';

  // Documents
  static const String documentViewer = '/document-viewer';
  static const String uploadDocument = '/upload-document';

  // Transactions
  static const String transactions = '/transactions';

  // Handover
  static const String handoverStatus = '/handover-status';
  static const String bookAppointment = '/book-appointment';
  static const String snagList = '/snag-list';
  static const String defectsApproval = '/defects-approval';
  static const String signHandover = '/sign-handover';
  static const String handoverConfirmation = '/handover-confirmation';

  // Notifications
  static const String notifications = '/notifications';
  static const String notificationDetail = '/notification-detail';

  // Profile
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String settings = '/settings';

  // Admin
  static const String manageClients = '/admin/clients';
  static const String clientDetails = '/admin/client-details';
  static const String manageProjects = '/admin/projects';
  static const String managePayments = '/admin/payments';
  static const String activityLogs = '/admin/activity-logs';
  static const String reports = '/admin/reports';
  static const String createClient = '/admin/create-client';
  static const String editClient = '/admin/edit-client';
  static const String createContract = '/admin/create-contract';
  static const String createHandover = '/admin/create-handover';
  static const String subscriptionsManagement = '/admin/subscriptions-management';

  // Chat
  static const String chatList = '/chat/list';
  static const String chatRoom = '/chat/room';
}
