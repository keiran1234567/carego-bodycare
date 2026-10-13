import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_store.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import '../widgets/bottom_navs.dart';
import '../widgets/info_card.dart';
import '../widgets/responsive_page.dart';

class ManageEmployeesScreen extends StatefulWidget {
  const ManageEmployeesScreen({super.key});

  @override
  State<ManageEmployeesScreen> createState() => _ManageEmployeesScreenState();
}

class _ManageEmployeesScreenState extends State<ManageEmployeesScreen> {
  static const List<String> _defaultSpecializations = [
    'Cukur Rambut',
    'Salon',
    'Nail Art',
    'Facial',
    'Make Up',
  ];

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

  List<Pelayan> get employees {
    final mitraId = AppStore.instance.currentMitra?.id;
    return AppStore.instance.pelayans
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
          appBar: AppBar(title: const Text('Kelola Pelayan')),
          bottomNavigationBar: const PartnerBottomNav(currentIndex: 2),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showCreateForm,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah Pelayan'),
          ),
          body: RefreshIndicator(
            onRefresh: AppStore.instance.refreshCatalog,
            child: ResponsivePage(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 90),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.blue, Color(0xFF5B6CFF)],
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
                          const Row(
                            children: [
                              Icon(Icons.groups_rounded,
                                  color: Colors.white, size: 24),
                              SizedBox(width: 10),
                              Text(
                                'Tim Pelayan Mitra',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Pelayan Aktif (${employees.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Data pelayan tersimpan dan diperbarui melalui backend.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (employees.isEmpty)
                      const InfoCard(
                          child: Text(
                              'Belum ada pelayan. Tekan Tambah Pelayan untuk membuat akun.')),
                    ...employees.map((employee) => InfoCard(
                          child: Row(children: [
                            CircleAvatar(
                              backgroundColor: employee.available
                                  ? AppColors.softBlue
                                  : AppColors.softPurple,
                              child: Text(
                                  employee.name.isEmpty
                                      ? '?'
                                      : employee.name[0],
                                  style: const TextStyle(
                                      color: AppColors.blue,
                                      fontWeight: FontWeight.w800)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(employee.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900)),
                                    Text(employee.specialty),
                                    Text(
                                        '${employee.email} • Rating ${employee.rating}',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.muted)),
                                  ]),
                            ),
                            Switch(
                              value: employee.available,
                              onChanged: (value) => _run(
                                () => AppStore.instance
                                    .updatePelayanAvailability(
                                        employee.id, value),
                                '${employee.name} ${value ? 'tersedia' : 'tidak tersedia'}',
                              ),
                            ),
                            IconButton(
                              onPressed: () => _confirmDelete(employee),
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

  Future<void> _showCreateForm() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _CreateEmployeeSheet(
        specializationOptions: _defaultSpecializations,
      ),
    );
    if (created == true && mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pelayan berhasil ditambahkan.')),
      );
    }
  }

  void _confirmDelete(Pelayan employee) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Pelayan?'),
        content: Text('Akun ${employee.name} akan dihapus dari backend.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _run(() => AppStore.instance.deletePelayan(employee.id),
                  'Pelayan berhasil dihapus.');
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _CreateEmployeeSheet extends StatefulWidget {
  const _CreateEmployeeSheet({required this.specializationOptions});

  final List<String> specializationOptions;

  @override
  State<_CreateEmployeeSheet> createState() => _CreateEmployeeSheetState();
}

class _CreateEmployeeSheetState extends State<_CreateEmployeeSheet> {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final experience = TextEditingController(text: '0');
  final selectedSpecializations = <String>{};
  var submitting = false;

  @override
  void dispose() {
    name.dispose();
    email.dispose();
    phone.dispose();
    password.dispose();
    experience.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (name.text.trim().isEmpty || email.text.trim().isEmpty) {
      _showError('Nama dan email wajib diisi.');
      return;
    }
    if (password.text.length < 8) {
      _showError('Password minimal 8 karakter.');
      return;
    }
    if (selectedSpecializations.isEmpty) {
      _showError('Pilih minimal satu spesialisasi pelayan.');
      return;
    }

    setState(() => submitting = true);
    try {
      await AppStore.instance.createPelayan(
        name: name.text.trim(),
        email: email.text.trim(),
        phone: phone.text.trim(),
        password: password.text,
        specialization: selectedSpecializations.join(', '),
        experienceYears: int.tryParse(experience.text) ?? 0,
        silent: true,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      _showError(error.message);
      setState(() => submitting = false);
    } catch (_) {
      if (!mounted) return;
      _showError('Pelayan gagal ditambahkan. Silakan coba lagi.');
      setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text(
              'Tambah Akun Pelayan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Isi data akun dan pilih satu atau beberapa spesialisasi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 14),
            _field(name, 'Nama Lengkap'),
            _field(email, 'Email', keyboard: TextInputType.emailAddress),
            _field(phone, 'Nomor Telepon', keyboard: TextInputType.phone),
            _field(password, 'Password minimal 8 karakter', obscure: true),
            _specializationPicker(),
            _field(
              experience,
              'Tahun Pengalaman',
              keyboard: TextInputType.number,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: submitting ? null : _submit,
                child: Text(submitting ? 'Menyimpan...' : 'Simpan Pelayan'),
              ),
            ),
          ]),
        ),
      );

  Widget _specializationPicker() => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.softPurple,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                color: AppColors.purple,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Spesialisasi Pelayan',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Bisa pilih lebih dari satu keahlian.',
                    style: TextStyle(fontSize: 12, color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.softBlue,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${selectedSpecializations.length} dipilih',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ...widget.specializationOptions.map((option) {
            final isSelected = selectedSpecializations.contains(option);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: submitting
                    ? null
                    : () => setState(() {
                          if (isSelected) {
                            selectedSpecializations.remove(option);
                          } else {
                            selectedSpecializations.add(option);
                          }
                        }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.softPurple
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.purple : AppColors.line,
                    ),
                  ),
                  child: Row(children: [
                    Icon(
                      isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: isSelected ? AppColors.purple : AppColors.muted,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ]),
                ),
              ),
            );
          }),
        ]),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    bool obscure = false,
    TextInputType? keyboard,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboard,
          enabled: !submitting,
          decoration: InputDecoration(labelText: label),
        ),
      );
}
