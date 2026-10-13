import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_store.dart';
import '../models/app_models.dart';
import '../utils/app_routes.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';

const _purple = Color(0xFF6548EE);
const _ink = Color(0xFF141529);
const _muted = Color(0xFF666B85);
const _line = Color(0xFFE8E8F4);

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final voucherController = TextEditingController();
  var serviceIndex = 0;
  var partnerIndex = 0;
  String? employeeId;
  String? pendingServiceId;
  String? pendingEmployeeId;
  var selectedDate = DateTime.now().add(const Duration(days: 1));
  var selectedTime = '10:00';
  var submitting = false;
  var routeApplied = false;
  String? selectedAddress;

  @override
  void dispose() {
    voucherController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (routeApplied) return;
    routeApplied = true;
    final arguments = ModalRoute.of(context)?.settings.arguments;
    final serviceId =
        arguments is Map ? '${arguments['serviceId'] ?? ''}' : arguments;
    if (serviceId is String) {
      pendingServiceId = serviceId.trim().isEmpty ? null : serviceId;
    }
    if (arguments is Map && arguments['employeeId'] != null) {
      final incomingEmployeeId = '${arguments['employeeId']}';
      pendingEmployeeId =
          incomingEmployeeId.trim().isEmpty ? null : incomingEmployeeId;
    }
    _applyRouteSelection();
    if (AppStore.instance.isAuthenticated &&
        AppStore.instance.vouchers.isEmpty) {
      AppStore.instance.refreshInteractions(silent: true).then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Future<void> _submit() async {
    final store = AppStore.instance;
    final service = store.layanans[serviceIndex];
    final partner = store.mitras[partnerIndex];
    final bookingAddress = _normalizedAddress(selectedAddress, store);
    if (bookingAddress == null) {
      _message('Alamat wajib diisi sebelum lanjut ke pembayaran.');
      return;
    }
    final employees = store.pelayans
        .where((employee) => employee.mitraId == partner.id)
        .toList();
    if (employees.isEmpty) {
      _message('Mitra belum memiliki pelayan tersedia.');
      return;
    }
    final employee = employees.firstWhere(
      (item) => item.id == employeeId,
      orElse: () => employees.first,
    );
    final time = selectedTime.split(':');
    final schedule = DateTime(selectedDate.year, selectedDate.month,
        selectedDate.day, int.parse(time[0]), int.parse(time[1]));
    setState(() => submitting = true);
    try {
      final booking = await store.createBooking(
        mitraId: partner.id,
        pelayanId: employee.id,
        layananId: service.id,
        scheduledAt: schedule,
        address: bookingAddress,
        notes: 'Booking dibuat dari aplikasi CareGo.',
        voucherCode: voucherController.text.trim().toUpperCase(),
      );
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.userPayment,
          arguments: booking.id);
    } on ApiException catch (error) {
      _message(error.message);
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _applyRouteSelection() {
    final store = AppStore.instance;
    if (pendingServiceId != null && store.layanans.isNotEmpty) {
      final index = store.layanans
          .indexWhere((service) => service.id == pendingServiceId);
      if (index >= 0) {
        serviceIndex = index;
        pendingServiceId = null;
      }
    }
    if (pendingEmployeeId != null) {
      employeeId = pendingEmployeeId;
      pendingEmployeeId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    _applyRouteSelection();
    if (store.loading && (store.layanans.isEmpty || store.mitras.isEmpty)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (store.layanans.isEmpty || store.mitras.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: Center(
          child: FilledButton.icon(
            onPressed: () => store.refreshCatalog(),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Muat data layanan dari server'),
          ),
        ),
      );
    }

    if (serviceIndex >= store.layanans.length) serviceIndex = 0;
    final service = store.layanans[serviceIndex];
    final matchingPartner =
        store.mitras.indexWhere((partner) => partner.id == service.mitraId);
    if (matchingPartner >= 0 &&
        store.mitras[partnerIndex].id != service.mitraId) {
      partnerIndex = matchingPartner;
    }
    final partner = store.mitras[partnerIndex];
    final employees = store.pelayans
        .where((employee) => employee.mitraId == partner.id)
        .toList();
    final discount = _voucherDiscount(service.price, voucherController.text);
    const travelFee = 10000;
    final total = service.price + travelFee - discount;
    selectedAddress ??= _defaultAddress(store);
    final validAddress = _normalizedAddress(selectedAddress, store);
    if (employees.isNotEmpty &&
        !employees.any((employee) => employee.id == employeeId)) {
      employeeId = employees.first.id;
    }

    return Theme(
      data: buildRoleBlueTheme(
        Theme.of(context),
        primary: const Color(0xFF225CD8),
        secondary: const Color(0xFF4D77F6),
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F8FF),
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  const _Header(),
                  const SizedBox(height: 14),
                  _Steps(activeStep: _activeStep(context)),
                  const SizedBox(height: 16),
                  _ServiceSummary(service: service),
                  const SizedBox(height: 14),
                  _Panel(
                    title: 'Pilih Jadwal',
                    icon: Icons.calendar_month_rounded,
                    child: _Schedule(
                      date: selectedDate,
                      time: selectedTime,
                      busySchedules: employees
                          .where((item) => item.id == employeeId)
                          .expand((item) => item.busySchedules)
                          .toList(),
                      onDate: (value) => setState(() => selectedDate = value),
                      onTime: (value) => setState(() => selectedTime = value),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    title: 'Alamat Layanan',
                    icon: Icons.location_on_outlined,
                    child: _Address(
                      value:
                          selectedAddress!.trim().isEmpty ? '-' : selectedAddress!,
                      missing: validAddress == null,
                      onChange: () async {
                        final result = await Navigator.pushNamed(
                            context, AppRoutes.userSelectAddress);
                        if (result is Map && mounted) {
                          setState(() =>
                              selectedAddress = '${result['address'] ?? ''}');
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    title: 'Voucher & Promo',
                    icon: Icons.confirmation_number_outlined,
                    child: Column(
                      children: [
                        TextField(
                          controller: voucherController,
                          textCapitalization: TextCapitalization.characters,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Kode voucher',
                            hintText: 'Contoh: DISKON20',
                            suffixIcon: Icon(Icons.discount_outlined),
                          ),
                        ),
                        if (store.vouchers.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 34,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: store.vouchers.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 7),
                              itemBuilder: (_, index) {
                                final voucher = store.vouchers[index];
                                final selected = voucherController.text
                                        .trim()
                                        .toUpperCase() ==
                                    '${voucher['code']}'.toUpperCase();
                                return ActionChip(
                                  label: Text('${voucher['code']}'),
                                  avatar: selected
                                      ? const Icon(Icons.check_rounded,
                                          size: 16)
                                      : const Icon(Icons.local_offer_outlined,
                                          size: 16),
                                  backgroundColor:
                                      selected ? const Color(0xFFE7F8EF) : null,
                                  onPressed: () => setState(() {
                                    voucherController.text =
                                        '${voucher['code']}'.toUpperCase();
                                    voucherController.selection =
                                        TextSelection.collapsed(
                                      offset: voucherController.text.length,
                                    );
                                  }),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Panel(
                    title: 'Rincian Harga',
                    icon: Icons.receipt_long_outlined,
                    child: Row(
                      children: [
                        Expanded(child: Text(service.name)),
                        Text(AppFormatters.currency(service.price),
                            style:
                                const TextStyle(fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
                    child: Row(children: [
                      Expanded(child: Text('Biaya perjalanan (0-5 KM)')),
                      Text('Rp10.000',
                          style: TextStyle(fontWeight: FontWeight.w900)),
                    ]),
                  ),
                  if (discount > 0)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: Row(children: [
                        const Expanded(
                            child: Text('Potongan voucher',
                                style: TextStyle(color: Color(0xFF1B9C68)))),
                        Text('- ${AppFormatters.currency(discount)}',
                            style: const TextStyle(
                                color: Color(0xFF1B9C68),
                                fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  const SizedBox(height: 14),
                  _BottomCheckout(
                    total: total,
                    loading: submitting,
                    enabled: employees.isNotEmpty && validAddress != null,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _activeStep(BuildContext context) {
    return switch (ModalRoute.of(context)?.settings.name) {
      AppRoutes.userSchedule => 1,
      AppRoutes.userBookingConfirm => 2,
      _ => 0,
    };
  }

  int _voucherDiscount(int subtotal, String code) {
    if (code.trim().isEmpty) return 0;
    final matches = AppStore.instance.vouchers.where(
        (item) => '${item['code']}'.toUpperCase() == code.trim().toUpperCase());
    if (matches.isEmpty) return 0;
    final voucher = matches.first;
    final minimum = double.tryParse('${voucher['min_transaction'] ?? 0}') ?? 0;
    if (subtotal < minimum) return 0;
    final value = double.tryParse('${voucher['discount_value'] ?? 0}') ?? 0;
    var discount =
        voucher['discount_type'] == 'PERCENT' ? subtotal * value / 100 : value;
    final maximum = double.tryParse('${voucher['max_discount'] ?? ''}');
    if (maximum != null) discount = discount.clamp(0, maximum);
    return discount.clamp(0, subtotal - 1000).round();
  }

  String _defaultAddress(AppStore store) {
    final primary = store.addresses.where((item) => item['is_primary'] == true);
    if (primary.isNotEmpty) return '${primary.first['address'] ?? ''}';
    if (store.addresses.isNotEmpty) {
      return '${store.addresses.first['address'] ?? ''}';
    }
    if (store.currentUser?.address.isNotEmpty == true) {
      return store.currentUser!.address;
    }
    return 'Alamat belum diatur pada akun.';
  }

  String? _normalizedAddress(String? value, AppStore store) {
    final trimmed = (value ?? '').trim();
    if (trimmed.isEmpty) return null;
    if (trimmed == 'Alamat belum diatur pada akun.') return null;
    return trimmed;
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          IconButton(
              onPressed: () => Navigator.maybePop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
          const Expanded(
            child: Text('Booking',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(children: [
                Icon(Icons.verified_user_outlined, color: _purple, size: 20),
                SizedBox(width: 4),
                Text('100% Aman',
                    style:
                        TextStyle(color: _purple, fontWeight: FontWeight.w800)),
              ]),
              Text('Privasi Terjaga',
                  style: TextStyle(fontSize: 10, color: _muted)),
            ],
          ),
        ],
      );
}

class _Steps extends StatelessWidget {
  const _Steps({required this.activeStep});
  final int activeStep;

  @override
  Widget build(BuildContext context) {
    const labels = ['Layanan', 'Jadwal', 'Konfirmasi'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index == activeStep;
        final done = index < activeStep;
        return Expanded(
          child: Column(
            children: [
              Row(children: [
                if (index > 0)
                  Expanded(
                      child: Divider(color: active || done ? _purple : _line)),
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active || done ? _purple : Colors.white,
                    border: Border.all(
                        color: active || done ? _purple : _line, width: 2),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: active || done ? Colors.white : _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (index < labels.length - 1)
                  const Expanded(child: Divider(color: _line)),
              ]),
              const SizedBox(height: 6),
              Text(labels[index],
                  style: TextStyle(
                      fontSize: 10,
                      color: active ? _purple : _muted,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w500)),
            ],
          ),
        );
      }),
    );
  }
}

class _ServiceSummary extends StatelessWidget {
  const _ServiceSummary({required this.service});

  final Layanan service;

  @override
  Widget build(BuildContext context) => _Surface(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(_serviceImage(service),
                  width: 112, height: 112, fit: BoxFit.cover),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                        color: const Color(0xFFF0ECFF),
                        borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 4),
                      child: Text(service.category.toUpperCase(),
                          style: const TextStyle(
                              color: _purple,
                              fontSize: 10,
                              fontWeight: FontWeight.w800)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(service.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(service.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: _muted, height: 1.4)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.schedule_outlined,
                        size: 14, color: _muted),
                    const SizedBox(width: 4),
                    Text(service.duration,
                        style: const TextStyle(fontSize: 10, color: _muted)),
                  ]),
                  const SizedBox(height: 8),
                  Text(AppFormatters.currency(service.price),
                      style: const TextStyle(
                          color: _purple,
                          fontSize: 16,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => _Surface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                    color: const Color(0xFFF0ECFF),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: _purple, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w900))),
              const Text('Lihat semua',
                  style: TextStyle(
                      fontSize: 10,
                      color: _purple,
                      fontWeight: FontWeight.w700)),
              const Icon(Icons.chevron_right_rounded, color: _purple, size: 18),
            ]),
            const SizedBox(height: 12),
            child,
          ],
        ),
      );
}

// ignore: unused_element
class _PartnerCard extends StatelessWidget {
  const _PartnerCard(
      {required this.partner, required this.selected, required this.onTap});

  final Mitra partner;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _ChoiceCard(
        selected: selected,
        onTap: onTap,
        width: 142,
        child: Column(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: const Color(0xFF171526),
              child: Text(_initials(partner.name),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(height: 8),
            Text(partner.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
                '⭐ ${partner.rating.toStringAsFixed(1)}  •  ${partner.distance}',
                style: const TextStyle(fontSize: 9, color: _muted)),
          ],
        ),
      );
}

// ignore: unused_element
class _EmployeeCard extends StatelessWidget {
  const _EmployeeCard(
      {required this.employee, required this.selected, required this.onTap});

  final Pelayan employee;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _ChoiceCard(
        selected: selected,
        onTap: onTap,
        width: 142,
        child: Column(
          children: [
            _Avatar(employee: employee),
            const SizedBox(height: 8),
            Text(employee.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
                '⭐ ${employee.rating.toStringAsFixed(1)}  •  ${employee.specialty}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9, color: _muted)),
          ],
        ),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.employee});

  final Pelayan employee;

  @override
  Widget build(BuildContext context) {
    if (employee.photoUrl.isNotEmpty) {
      return CircleAvatar(
          radius: 35, backgroundImage: NetworkImage(employee.photoUrl));
    }
    return CircleAvatar(
      radius: 35,
      backgroundColor: const Color(0xFFE7E4FA),
      child: Text(_initials(employee.name),
          style: const TextStyle(
              color: _purple, fontSize: 18, fontWeight: FontWeight.w900)),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard(
      {required this.selected,
      required this.onTap,
      required this.width,
      required this.child});

  final bool selected;
  final VoidCallback onTap;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? _purple : _line, width: 1.4),
          ),
          child: Stack(children: [
            Center(child: child),
            if (selected)
              const Positioned(
                right: 0,
                top: 0,
                child: CircleAvatar(
                  radius: 11,
                  backgroundColor: _purple,
                  child:
                      Icon(Icons.check_rounded, size: 14, color: Colors.white),
                ),
              ),
          ]),
        ),
      );
}

class _Schedule extends StatelessWidget {
  const _Schedule(
      {required this.date,
      required this.time,
      required this.busySchedules,
      required this.onDate,
      required this.onTime});

  final DateTime date;
  final String time;
  final List<DateTime> busySchedules;
  final ValueChanged<DateTime> onDate;
  final ValueChanged<String> onTime;

  @override
  Widget build(BuildContext context) {
    const times = [
      '09:00',
      '10:00',
      '11:00',
      '13:00',
      '14:00',
      '15:00',
      '16:00',
      '17:00'
    ];
    final dates = List.generate(
        5, (index) => DateTime.now().add(Duration(days: index + 1)));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 84,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final item = dates[index];
              final active = _sameDay(item, date);
              return InkWell(
                onTap: () => onDate(item),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 62,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFF1EDFF) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: active ? _purple : _line),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_weekday(item.weekday),
                          style: TextStyle(
                              fontSize: 10, color: active ? _purple : _muted)),
                      Text('${item.day}',
                          style: TextStyle(
                              fontSize: 19,
                              color: active ? _purple : _ink,
                              fontWeight: FontWeight.w900)),
                      Text(_month(item.month),
                          style: const TextStyle(fontSize: 9, color: _muted)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: times.map((item) {
            final active = item == time;
            final parts = item.split(':');
            final slot = DateTime(date.year, date.month, date.day,
                int.parse(parts[0]), int.parse(parts[1]));
            final busy = busySchedules.any((value) =>
                value.year == slot.year &&
                value.month == slot.month &&
                value.day == slot.day &&
                value.hour == slot.hour &&
                value.minute == slot.minute);
            return InkWell(
              onTap: busy ? null : () => onTime(item),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 70,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: busy
                      ? const Color(0xFFE5E5EA)
                      : active
                          ? _purple
                          : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: active ? _purple : _line),
                ),
                child: Text(item,
                    style: TextStyle(
                        color: busy
                            ? _muted
                            : active
                                ? Colors.white
                                : _ink,
                        fontSize: 11)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Address extends StatelessWidget {
  const _Address({
    required this.value,
    required this.onChange,
    this.missing = false,
  });

  final String value;
  final VoidCallback onChange;
  final bool missing;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
            color: const Color(0xFFFAFAFF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _line)),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(fontSize: 10, height: 1.5)),
                if (missing) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Alamat wajib diisi.',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onChange,
            iconAlignment: IconAlignment.end,
            icon: const Icon(Icons.edit_outlined, size: 15),
            label: const Text('Ubah Alamat'),
            style: TextButton.styleFrom(
                foregroundColor: _purple,
                textStyle: const TextStyle(fontSize: 10)),
          ),
        ]),
      );
}

class _BottomCheckout extends StatelessWidget {
  const _BottomCheckout(
      {required this.total,
      required this.loading,
      required this.enabled,
      required this.onPressed});

  final int total;
  final bool loading;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => _Surface(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Pembayaran',
                      style: TextStyle(fontSize: 10, color: _muted)),
                  Text(AppFormatters.currency(total),
                      style: const TextStyle(
                          color: _purple,
                          fontSize: 20,
                          fontWeight: FontWeight.w900)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: loading || !enabled ? null : onPressed,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                      loading ? 'Membuat Booking...' : 'Lanjut ke Konfirmasi'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _Surface extends StatelessWidget {
  const _Surface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF0F0F8)),
          boxShadow: const [
            BoxShadow(
                color: Color(0x0D5C50E6), blurRadius: 18, offset: Offset(0, 5)),
          ],
        ),
        child: child,
      );
}

String _serviceImage(Layanan service) {
  final value = '${service.name} ${service.category}'.toLowerCase();
  if (value.contains('nail') || value.contains('manicure')) {
    return 'assets/images/service_nail_care.png';
  }
  if (value.contains('facial') || value.contains('wajah')) {
    return 'assets/images/service_facial_glow.png';
  }
  if (value.contains('cukur') || value.contains('haircut')) {
    return 'assets/images/service_premium_haircut.png';
  }
  return 'assets/images/service_hair_treatment.png';
}

String _initials(String value) => value
    .trim()
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _weekday(int value) =>
    const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'][value - 1];

String _month(int value) => const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ][value - 1];
