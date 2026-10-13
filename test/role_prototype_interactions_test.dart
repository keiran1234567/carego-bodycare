import 'package:bodycare_home_service/screens/admin_dashboard_screen.dart';
import 'package:bodycare_home_service/screens/admin_management_screens.dart';
import 'package:bodycare_home_service/screens/employee_dashboard_screen.dart';
import 'package:bodycare_home_service/screens/manage_employees_screen.dart';
import 'package:bodycare_home_service/screens/partner_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final entry in const <String, Widget>{
    'mitra': PartnerDashboardScreen(),
    'pelayan': EmployeeDashboardScreen(),
    'admin': AdminDashboardScreen(),
  }.entries) {
    testWidgets('${entry.key} screen handles an empty backend state',
        (tester) async {
      await tester.pumpWidget(MaterialApp(home: entry.value));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('form tambah pelayan aman dibuka, divalidasi, dan ditutup',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ManageEmployeesScreen()),
    );

    await tester.tap(find.text('Tambah Pelayan'));
    await tester.pumpAndSettle();
    expect(find.text('Tambah Akun Pelayan'), findsOneWidget);

    await tester.ensureVisible(find.text('Simpan Pelayan'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan Pelayan'));
    await tester.pump();
    expect(find.text('Nama dan email wajib diisi.'), findsOneWidget);

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  for (final entry in const <String, Widget>{
    'Tambah User': AdminManageUsersScreen(),
    'Tambah Mitra': AdminManagePartnersScreen(),
    'Tambah Pelayan': AdminManageEmployeesScreen(),
    'Tambah Layanan': AdminManageServicesScreen(),
    'Tambah Booking': AdminManageBookingsScreen(),
    'Tambah Pembayaran': AdminManagePaymentsScreen(),
  }.entries) {
    testWidgets('admin dapat membuka form ${entry.key}', (tester) async {
      await tester.pumpWidget(MaterialApp(home: entry.value));
      await tester.tap(find.text(entry.key).first);
      await tester.pumpAndSettle();

      expect(find.text(entry.key), findsWidgets);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
