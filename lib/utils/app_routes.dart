import 'package:flutter/material.dart';

import '../screens/admin_dashboard_screen.dart';
import '../screens/admin_management_screens.dart';
import '../screens/booking_history_screen.dart';
import '../screens/booking_detail_screen.dart';
import '../screens/booking_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/employee_dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/manage_employees_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/partner_dashboard_screen.dart';
import '../screens/partner_detail_screen.dart';
import '../screens/partner_management_screens.dart';
import '../screens/profile_screen.dart';
import '../screens/profile_subpages.dart';
import '../screens/registration/role_registration_pages.dart';
import '../screens/rating_review_screen.dart';
import '../screens/register_screen.dart';
import '../screens/splash_screen.dart';
import '../screens/user_dashboard_screen.dart';
import '../screens/user/mitra_detail_page.dart';
import '../screens/user/notifications_page.dart';
import '../screens/user/category_therapists_page.dart';
import '../screens/user/payment_midtrans_page.dart';
import '../screens/user/review_page.dart';
import '../screens/user/therapist_detail_page.dart';
import '../screens/user/tracking_order_page.dart';
import '../screens/user/user_extra_pages.dart';

class AppRoutes {
  const AppRoutes._();

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const roleSelection = '/role-selection';
  static const login = '/login';
  static const register = '/register';
  static const roleRegistration = '/registration/roles';
  static const partnerRegister = '/registration/partner';
  static const employeeRegister = '/registration/employee';
  static const selectPartner = '/registration/select-partner';
  static const partnerInviteCode = '/registration/invite-code';
  static const registrationStatus = '/registration/status';
  static const partnerInviteEmployee = '/partner/invite-employee';
  static const userDashboard = '/user-dashboard';
  static const partnerDetail = '/partner-detail';
  static const booking = '/booking';
  static const bookingHistory = '/booking-history';
  static const bookingDetail = '/booking-detail';
  static const chat = '/chat';
  static const ratingReview = '/rating-review';
  static const partnerDashboard = '/partner-dashboard';
  static const partnerOrders = '/partner-orders';
  static const manageServices = '/partner/manage-services';
  static const partnerFinance = '/partner/finance';
  static const manageEmployees = '/manage-employees';
  static const employeeDashboard = '/employee-dashboard';
  static const adminDashboard = '/admin-dashboard';
  static const adminUsers = '/admin/users';
  static const adminPartners = '/admin/partners';
  static const adminEmployees = '/admin/employees';
  static const adminServices = '/admin/services';
  static const adminBookings = '/admin/bookings';
  static const adminVouchers = '/admin/vouchers';
  static const adminPayments = '/admin/payments';
  static const adminReports = '/admin/reports';
  static const profile = '/profile';
  static const addresses = '/addresses';
  static const paymentMethods = '/payment-methods';
  static const promoVoucher = '/promo-voucher';
  static const helpCenter = '/help-center';
  static const aboutBodyCare = '/about-bodycare';
  static const userMitraDetail = '/user/mitra-detail';
  static const userTherapistDetail = '/user/therapist-detail';
  static const userCategoryTherapists = '/user/category-therapists';
  static const userSchedule = '/user/schedule';
  static const userBookingConfirm = '/user/booking-confirm';
  static const userPayment = '/user/payment-midtrans';
  static const userTracking = '/user/tracking';
  static const userReview = '/user/review';
  static const userNotifications = '/user/notifications';
  static const userServiceDetail = '/user/service-detail';
  static const userFavorites = '/user/favorites';
  static const userWallet = '/user/wallet';
  static const userSelectAddress = '/user/select-address';
  static const userCheckoutVoucher = '/user/checkout-voucher';
  static const userPaymentStatus = '/user/payment-status';
  static const userCancelBooking = '/user/cancel-booking';
  static const userRescheduleBooking = '/user/reschedule-booking';
  static const userEmptyStates = '/user/empty-states';

  static Map<String, WidgetBuilder> get routes => {
        splash: (_) => const SplashScreen(),
        onboarding: (_) => const OnboardingScreen(),
        roleSelection: (_) => const EntryRoleSelectionPage(),
        login: (_) => const LoginScreen(),
        register: (_) => const RegisterScreen(),
        roleRegistration: (_) => const RoleRegistrationPage(),
        partnerRegister: (_) => const PartnerRegistrationPage(),
        employeeRegister: (_) => const EmployeeRegistrationPage(),
        selectPartner: (_) => const SelectPartnerPage(),
        partnerInviteCode: (_) => const PartnerInviteCodePage(),
        registrationStatus: (_) => const RegistrationStatusPage(),
        partnerInviteEmployee: (_) => const PartnerInviteEmployeePage(),
        userDashboard: (_) => const UserDashboardScreen(),
        partnerDetail: (_) => const PartnerDetailScreen(),
        booking: (_) => const BookingScreen(),
        bookingHistory: (_) => const BookingHistoryScreen(),
        bookingDetail: (_) => const BookingDetailScreen(),
        chat: (_) => const ChatScreen(),
        ratingReview: (_) => const RatingReviewScreen(),
        partnerDashboard: (_) => const PartnerDashboardScreen(),
        partnerOrders: (_) => const PartnerOrdersScreen(),
        manageServices: (_) => const ManageServicesScreen(),
        partnerFinance: (_) => const PartnerFinanceScreen(),
        manageEmployees: (_) => const ManageEmployeesScreen(),
        employeeDashboard: (_) => const EmployeeDashboardScreen(),
        adminDashboard: (_) => const AdminDashboardScreen(),
        adminUsers: (_) => const AdminManageUsersScreen(),
        adminPartners: (_) => const AdminManagePartnersScreen(),
        adminEmployees: (_) => const AdminManageEmployeesScreen(),
        adminServices: (_) => const AdminManageServicesScreen(),
        adminBookings: (_) => const AdminManageBookingsScreen(),
        adminVouchers: (_) => const AdminManageVouchersScreen(),
        adminPayments: (_) => const AdminManagePaymentsScreen(),
        adminReports: (_) => const AdminReportsScreen(),
        profile: (_) => const ProfileScreen(),
        addresses: (_) => const AddressScreen(),
        paymentMethods: (_) => const PaymentMethodsScreen(),
        promoVoucher: (_) => const PromoVoucherScreen(),
        helpCenter: (_) => const HelpCenterScreen(),
        aboutBodyCare: (_) => const AboutBodyCareScreen(),
        userMitraDetail: (_) => const MitraDetailPage(),
        userTherapistDetail: (_) => const TherapistDetailPage(),
        userCategoryTherapists: (_) => const CategoryTherapistsPage(),
        userSchedule: (_) => const BookingScreen(),
        userBookingConfirm: (_) => const BookingScreen(),
        userPayment: (_) => const PaymentMidtransPage(),
        userTracking: (_) => const TrackingOrderPage(),
        userReview: (_) => const UserReviewPage(),
        userNotifications: (_) => const NotificationsPage(),
        userServiceDetail: (_) => const ServiceDetailPage(),
        userFavorites: (_) => const FavoritePage(),
        userWallet: (_) => const WalletPage(),
        userSelectAddress: (_) => const SelectAddressPage(),
        userCheckoutVoucher: (_) => const CheckoutVoucherPage(),
        userPaymentStatus: (_) => const TrackingOrderPage(),
        userCancelBooking: (_) => const CancelBookingPage(),
        userRescheduleBooking: (_) => const RescheduleBookingPage(),
        userEmptyStates: (_) => const EmptyStatesPage(),
      };
}
