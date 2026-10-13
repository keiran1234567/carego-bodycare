import 'package:bodycare_home_service/screens/admin_dashboard_screen.dart';
import 'package:bodycare_home_service/screens/admin_management_screens.dart';
import 'package:bodycare_home_service/screens/booking_detail_screen.dart';
import 'package:bodycare_home_service/screens/booking_history_screen.dart';
import 'package:bodycare_home_service/screens/booking_screen.dart';
import 'package:bodycare_home_service/screens/chat_screen.dart';
import 'package:bodycare_home_service/screens/employee_dashboard_screen.dart';
import 'package:bodycare_home_service/screens/login_screen.dart';
import 'package:bodycare_home_service/screens/manage_employees_screen.dart';
import 'package:bodycare_home_service/screens/onboarding_screen.dart';
import 'package:bodycare_home_service/screens/partner_dashboard_screen.dart';
import 'package:bodycare_home_service/screens/partner_detail_screen.dart';
import 'package:bodycare_home_service/screens/partner_management_screens.dart';
import 'package:bodycare_home_service/screens/profile_screen.dart';
import 'package:bodycare_home_service/screens/profile_subpages.dart';
import 'package:bodycare_home_service/screens/rating_review_screen.dart';
import 'package:bodycare_home_service/screens/register_screen.dart';
import 'package:bodycare_home_service/screens/registration/role_registration_pages.dart';
import 'package:bodycare_home_service/screens/user/booking_confirm_page.dart';
import 'package:bodycare_home_service/screens/user/mitra_detail_page.dart';
import 'package:bodycare_home_service/screens/user/notifications_page.dart';
import 'package:bodycare_home_service/screens/user/payment_midtrans_page.dart';
import 'package:bodycare_home_service/screens/user/review_page.dart';
import 'package:bodycare_home_service/screens/user/schedule_page.dart';
import 'package:bodycare_home_service/screens/user/therapist_detail_page.dart';
import 'package:bodycare_home_service/screens/user/tracking_order_page.dart';
import 'package:bodycare_home_service/screens/user/user_extra_pages.dart';
import 'package:bodycare_home_service/screens/user_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('user detail pages fit a narrow Android viewport',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(home: MitraDetailPage()),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      const MaterialApp(home: SchedulePage()),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('therapist horizontal lists do not overflow after scrolling',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: MitraDetailPage()));
    if (find.text('Terapis / Pelayan').evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        find.text('Terapis / Pelayan'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const MaterialApp(home: ServiceDetailPage()));
    if (find.text('Terapis Tersedia').evaluate().isNotEmpty) {
      await tester.scrollUntilVisible(
        find.text('Terapis Tersedia'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  const extraPages = <String, Widget>{
    'service detail': ServiceDetailPage(),
    'favorites': FavoritePage(),
    'select address': SelectAddressPage(),
    'checkout voucher': CheckoutVoucherPage(),
    'payment status': PaymentStatusPage(),
    'cancel booking': CancelBookingPage(),
    'reschedule booking': RescheduleBookingPage(),
    'empty states': EmptyStatesPage(),
  };

  for (final entry in extraPages.entries) {
    testWidgets('${entry.key} fits a narrow Android viewport', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: entry.value));
      expect(tester.takeException(), isNull);
    });
  }

  const mainPages = <String, Widget>{
    'login': LoginScreen(),
    'register': RegisterScreen(),
    'home': UserDashboardScreen(),
    'booking': BookingScreen(),
    'history': BookingHistoryScreen(),
    'booking detail': BookingDetailScreen(),
    'chat': ChatScreen(),
    'profile': ProfileScreen(),
    'legacy rating review': RatingReviewScreen(),
    'therapist detail': TherapistDetailPage(),
    'schedule': SchedulePage(),
    'booking confirm': BookingConfirmPage(),
    'midtrans payment': PaymentMidtransPage(),
    'tracking': TrackingOrderPage(),
    'review': UserReviewPage(),
    'notifications': NotificationsPage(),
    'onboarding': OnboardingScreen(),
    'partner dashboard': PartnerDashboardScreen(),
    'partner orders': PartnerOrdersScreen(),
    'partner detail': PartnerDetailScreen(),
    'manage employees': ManageEmployeesScreen(),
    'employee dashboard': EmployeeDashboardScreen(),
    'admin dashboard': AdminDashboardScreen(),
    'admin users': AdminManageUsersScreen(),
    'admin partners': AdminManagePartnersScreen(),
    'admin employees': AdminManageEmployeesScreen(),
    'admin reports': AdminReportsScreen(),
    'manage services': ManageServicesScreen(),
    'partner finance': PartnerFinanceScreen(),
    'addresses': AddressScreen(),
    'payment methods': PaymentMethodsScreen(),
    'promo voucher': PromoVoucherScreen(),
    'help center': HelpCenterScreen(),
    'about bodycare': AboutBodyCareScreen(),
    'role registration': RoleRegistrationPage(),
    'entry role selection': EntryRoleSelectionPage(),
    'partner registration': PartnerRegistrationPage(),
    'employee registration': EmployeeRegistrationPage(),
    'select partner': SelectPartnerPage(),
    'partner invite code': PartnerInviteCodePage(),
    'registration status': RegistrationStatusPage(),
    'partner invite employee': PartnerInviteEmployeePage(),
  };

  for (final entry in mainPages.entries) {
    testWidgets('${entry.key} has no overflow on narrow Android',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(home: entry.value));
      expect(tester.takeException(), isNull);
    });

    testWidgets('${entry.key} has no overflow on extra compact Android',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 640),
              textScaler: TextScaler.noScaling,
            ),
            child: entry.value,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }
}
