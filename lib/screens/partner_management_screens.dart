import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_store.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/info_card.dart';
import '../widgets/responsive_page.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  @override
  void initState() {
    super.initState();
    AppStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  List<Layanan> get services {
    final mitraId = AppStore.instance.currentMitra?.id;
    return AppStore.instance.layanans
        .where((item) => item.mitraId == mitraId)
        .toList();
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: buildRoleBlueTheme(Theme.of(context)),
        child: Scaffold(
          appBar: AppBar(title: const Text('Kelola Layanan')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _serviceForm(),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Layanan'),
          ),
          body: RefreshIndicator(
            onRefresh: AppStore.instance.refreshCatalog,
            child: ResponsivePage(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3156D3), Color(0xFF5B6CFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x243159D8),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kelola Layanan Mitra',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text(
                              'Layanan ${AppStore.instance.currentMitra?.name ?? 'Mitra'}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          const Text(
                              'Harga, durasi, dan layanan tersambung ke backend.',
                              style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (services.isEmpty)
                      const InfoCard(child: Text('Belum ada layanan aktif.')),
                    ...services.map((service) => InfoCard(
                          child: Row(children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: AppColors.softBlue,
                                  borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.medical_services_outlined,
                                  color: AppColors.blue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(service.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900)),
                                    Text(
                                        '${service.duration} • ${AppFormatters.currency(service.price)}',
                                        style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.muted)),
                                    TextButton(
                                      onPressed: () => _serviceForm(service),
                                      style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero),
                                      child: const Text('Edit layanan'),
                                    ),
                                  ]),
                            ),
                            Switch(
                              value: service.active,
                              onChanged: (value) => _run(
                                  () => AppStore.instance
                                      .updateLayanan(service.id, active: value),
                                  'Status layanan diperbarui.'),
                            ),
                            IconButton(
                              onPressed: () => _delete(service),
                              icon: const Icon(Icons.delete_outline_rounded,
                                  color: Colors.redAccent),
                            ),
                          ]),
                        )),
                  ]),
            ),
          ),
        ),
      );

  void _serviceForm([Layanan? service]) {
    final name = TextEditingController(text: service?.name);
    final category = TextEditingController(text: service?.category);
    final description = TextEditingController(text: service?.description);
    final price = TextEditingController(text: service?.price.toString());
    final duration =
        TextEditingController(text: service?.duration.replaceAll(' menit', ''));
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, MediaQuery.viewInsetsOf(sheetContext).bottom + 24),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(service == null ? 'Tambah Layanan' : 'Edit Layanan',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(height: 14),
            _field(name, 'Nama Layanan'),
            _field(category, 'Kategori'),
            _field(description, 'Deskripsi'),
            _field(price, 'Harga', keyboard: TextInputType.number),
            _field(duration, 'Durasi (menit)', keyboard: TextInputType.number),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final action = service == null
                      ? AppStore.instance.createLayanan(
                          name: name.text.trim(),
                          category: category.text.trim(),
                          description: description.text.trim(),
                          price: int.tryParse(price.text) ?? 0,
                          durationMinutes: int.tryParse(duration.text) ?? 0)
                      : AppStore.instance.updateLayanan(service.id,
                          name: name.text.trim(),
                          category: category.text.trim(),
                          description: description.text.trim(),
                          price: int.tryParse(price.text) ?? 0,
                          durationMinutes: int.tryParse(duration.text) ?? 0);
                  await _run(() => action, 'Layanan berhasil disimpan.');
                  if (!mounted || !sheetContext.mounted) return;
                  Navigator.pop(sheetContext);
                },
                child: const Text('Simpan Layanan'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label,
          {TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
            controller: controller,
            keyboardType: keyboard,
            decoration: InputDecoration(labelText: label)),
      );

  void _delete(Layanan service) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus layanan?'),
        content: Text(service.name),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _run(() => AppStore.instance.deleteLayanan(service.id),
                  'Layanan berhasil dihapus.');
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class PartnerFinanceScreen extends StatefulWidget {
  const PartnerFinanceScreen({super.key});

  @override
  State<PartnerFinanceScreen> createState() => _PartnerFinanceScreenState();
}

class _PartnerFinanceScreenState extends State<PartnerFinanceScreen> {
  @override
  void initState() {
    super.initState();
    AppStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final income = AppStore.instance.income;
    final total = double.tryParse('${income['total'] ?? 0}')?.round() ?? 0;
    final transactions = (income['transactions'] as List?) ?? [];
    return Theme(
      data: buildRoleBlueTheme(Theme.of(context)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Keuangan Mitra')),
        body: RefreshIndicator(
          onRefresh: AppStore.instance.refreshIncome,
          child: ResponsivePage(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF3156D3), Color(0xFF6941D9)]),
                    borderRadius: BorderRadius.circular(14)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total pendapatan dari backend',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Text(AppFormatters.currency(total),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 27,
                              fontWeight: FontWeight.w900)),
                    ]),
              ),
              const SizedBox(height: 22),
              const Text('Riwayat Transaksi',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              if (transactions.isEmpty)
                const InfoCard(child: Text('Belum ada pembayaran berhasil.')),
              ...transactions.map((raw) {
                final item = Map<String, dynamic>.from(raw as Map);
                final amount =
                    double.tryParse('${item['amount'] ?? 0}')?.round() ?? 0;
                return InfoCard(
                  child: Row(children: [
                    const CircleAvatar(
                        backgroundColor: AppColors.mint,
                        child: Icon(Icons.arrow_downward_rounded,
                            color: Color(0xFF188A5B))),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${item['service'] ?? 'Layanan'} • Booking #${item['booking_id']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            Text(
                                '${item['method'] ?? '-'} • ${item['paid_at'] ?? '-'}',
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.muted)),
                          ]),
                    ),
                    Text(AppFormatters.currency(amount),
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                  ]),
                );
              }),
            ]),
          ),
        ),
      ),
    );
  }
}
