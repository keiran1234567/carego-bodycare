import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_store.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/info_card.dart';
import '../widgets/responsive_page.dart';

class AdminManageUsersScreen extends StatelessWidget {
  const AdminManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _AdminListPage(
      title: 'Kelola User',
      subtitle: 'Data pelanggan terdaftar dari backend',
      addLabel: 'Tambah User',
      onAdd: () => _openAdminEditor(context, _AdminEntity.user),
      items: () => AppStore.instance.users
          .where((user) => user.role == AppRole.user)
          .map((user) => _AdminItem(
                user.name,
                user.email,
                Icons.person_outline_rounded,
                detail: '${user.phone} - ${user.status}',
                onEdit: () =>
                    _openAdminEditor(context, _AdminEntity.user, user),
                onDelete: () => AppStore.instance.deleteAdminUser(user.id),
              )),
      onRefresh: () => AppStore.instance.refreshUsers(),
    );
  }
}

class AdminManagePartnersScreen extends StatefulWidget {
  const AdminManagePartnersScreen({super.key});

  @override
  State<AdminManagePartnersScreen> createState() =>
      _AdminManagePartnersScreenState();
}

class _AdminManagePartnersScreenState extends State<AdminManagePartnersScreen>
    with SingleTickerProviderStateMixin {
  final search = TextEditingController();
  var selectedStatus = 'pending';
  String? selectedPartnerId;

  @override
  void initState() {
    super.initState();
    AppStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final allPartners = AppStore.instance.mitras;
    final partners = allPartners.where((partner) {
      return query.isEmpty ||
          partner.name.toLowerCase().contains(query) ||
          partner.ownerName.toLowerCase().contains(query) ||
          partner.email.toLowerCase().contains(query);
    }).toList();
    final filtered = partners
        .where((partner) => partner.verificationStatus == selectedStatus)
        .toList();
    final selectedPartner = _selectedPartner(filtered, allPartners);

    return Scaffold(
      backgroundColor: AppColors.skyBlue,
      appBar: AppBar(
        title: const Text('Kelola Mitra'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: AppStore.instance.refreshCatalog,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 960;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                wide ? 24 : 16,
                10,
                wide ? 24 : 16,
                18,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _AdminBreadcrumb(
                            title: 'Verifikasi pendaftaran mitra dari backend',
                            selectedLabel: _statusLabel(selectedStatus),
                          ),
                          const SizedBox(height: 18),
                          _PartnerStatsRow(
                            pending: _countStatus(allPartners, 'pending'),
                            approved: _countStatus(allPartners, 'approved'),
                            rejected: _countStatus(allPartners, 'rejected'),
                            wide: wide,
                          ),
                          const SizedBox(height: 18),
                          _PartnerVerificationPanel(
                            partners: filtered,
                            selectedPartnerId: selectedPartnerId,
                            selectedStatus: selectedStatus,
                            search: search,
                            wide: wide,
                            onSearchChanged: (_) => setState(() {}),
                            onStatusChanged: (status) => setState(() {
                              selectedStatus = status;
                              selectedPartnerId = null;
                            }),
                            onSelect: (partner) => setState(
                              () => selectedPartnerId = partner.id,
                            ),
                            onDetail: (partner) {
                              setState(() => selectedPartnerId = partner.id);
                              if (!wide) _showMitraDetail(context, partner);
                            },
                            onApprove: _approve,
                            onReject: (partner) =>
                                _showRejectDialog(context, partner),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (wide) ...[
                    const SizedBox(width: 18),
                    SizedBox(
                      width: 330,
                      child: _PartnerDetailPanel(
                        partner: selectedPartner,
                        onApprove: selectedPartner == null
                            ? null
                            : () => _approve(selectedPartner),
                        onReject: selectedPartner == null
                            ? null
                            : () => _showRejectDialog(context, selectedPartner),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Mitra? _selectedPartner(List<Mitra> filtered, List<Mitra> allPartners) {
    if (selectedPartnerId != null) {
      for (final partner in allPartners) {
        if (partner.id == selectedPartnerId) return partner;
      }
    }
    return filtered.isEmpty ? null : filtered.first;
  }

  int _countStatus(List<Mitra> partners, String status) =>
      partners.where((partner) => partner.verificationStatus == status).length;

  Future<void> _approve(Mitra partner) async {
    try {
      await AppStore.instance.approveMitra(partner.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${partner.name} berhasil disetujui.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }
}

String _statusLabel(String status) => switch (status) {
      'approved' => 'Mitra Aktif',
      'rejected' => 'Mitra Ditolak',
      _ => 'Menunggu Verifikasi',
    };

String _ownerName(Mitra partner) =>
    partner.ownerName.isEmpty ? '-' : partner.ownerName;

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  if (words.isEmpty) return 'M';
  return words.take(2).map((word) => word[0].toUpperCase()).join();
}

class _AdminBreadcrumb extends StatelessWidget {
  const _AdminBreadcrumb({
    required this.title,
    required this.selectedLabel,
  });

  final String title;
  final String selectedLabel;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kelola Mitra',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Dashboard / Mitra / $selectedLabel',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.admin_panel_settings_rounded),
            label: const Text('Admin CareGo'),
          ),
        ],
      );
}

class _PartnerStatsRow extends StatelessWidget {
  const _PartnerStatsRow({
    required this.pending,
    required this.approved,
    required this.rejected,
    required this.wide,
  });

  final int pending;
  final int approved;
  final int rejected;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (
        'Menunggu Verifikasi',
        pending,
        'Mitra baru',
        Icons.schedule_rounded,
        AppColors.purple,
        AppColors.softPurple,
      ),
      (
        'Mitra Aktif',
        approved,
        'Mitra aktif',
        Icons.check_rounded,
        const Color(0xFF09A66D),
        const Color(0xFFE8F8F1),
      ),
      (
        'Mitra Ditolak',
        rejected,
        'Mitra ditolak',
        Icons.close_rounded,
        const Color(0xFFEA3F3F),
        const Color(0xFFFFEEEE),
      ),
    ];
    final children = stats
        .map(
          (stat) => Expanded(
            child: _PartnerStatCard(
              title: stat.$1,
              value: stat.$2,
              subtitle: stat.$3,
              icon: stat.$4,
              color: stat.$5,
              bgColor: stat.$6,
            ),
          ),
        )
        .toList();
    if (wide) {
      return Row(
        children: [
          children[0],
          const SizedBox(width: 14),
          children[1],
          const SizedBox(width: 14),
          children[2],
        ],
      );
    }
    return Column(
      children: stats
          .map(
            (stat) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PartnerStatCard(
                title: stat.$1,
                value: stat.$2,
                subtitle: stat.$3,
                icon: stat.$4,
                color: stat.$5,
                bgColor: stat.$6,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _PartnerStatCard extends StatelessWidget {
  const _PartnerStatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  final String title;
  final int value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C10163A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: bgColor,
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(subtitle,
                      style: const TextStyle(color: AppColors.muted)),
                ],
              ),
            ),
          ],
        ),
      );
}

class _PartnerVerificationPanel extends StatelessWidget {
  const _PartnerVerificationPanel({
    required this.partners,
    required this.selectedPartnerId,
    required this.selectedStatus,
    required this.search,
    required this.wide,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onSelect,
    required this.onDetail,
    required this.onApprove,
    required this.onReject,
  });

  final List<Mitra> partners;
  final String? selectedPartnerId;
  final String selectedStatus;
  final TextEditingController search;
  final bool wide;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<Mitra> onSelect;
  final ValueChanged<Mitra> onDetail;
  final ValueChanged<Mitra> onApprove;
  final ValueChanged<Mitra> onReject;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C10163A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            if (wide)
              Row(
                children: [
                  Expanded(
                      child: _PartnerStatusTabs(
                    selected: selectedStatus,
                    onChanged: onStatusChanged,
                  )),
                  const SizedBox(width: 14),
                  SizedBox(
                    width: 300,
                    child: _PartnerSearchField(
                      controller: search,
                      onChanged: onSearchChanged,
                    ),
                  ),
                ],
              )
            else ...[
              _PartnerSearchField(
                controller: search,
                onChanged: onSearchChanged,
              ),
              const SizedBox(height: 12),
              _PartnerStatusTabs(
                selected: selectedStatus,
                onChanged: onStatusChanged,
              ),
            ],
            const SizedBox(height: 14),
            if (partners.isEmpty)
              const InfoCard(
                child: Text('Belum ada mitra pada daftar ini.'),
              )
            else if (wide)
              _PartnerDataTable(
                partners: partners,
                selectedPartnerId: selectedPartnerId,
                onSelect: onSelect,
                onDetail: onDetail,
                onApprove: onApprove,
                onReject: onReject,
              )
            else
              ...partners.map(
                (partner) => _PartnerListTile(
                  partner: partner,
                  selected: partner.id == selectedPartnerId,
                  onTap: () => onSelect(partner),
                  onDetail: () => onDetail(partner),
                  onApprove: () => onApprove(partner),
                  onReject: () => onReject(partner),
                ),
              ),
          ],
        ),
      );
}

class _PartnerSearchField extends StatelessWidget {
  const _PartnerSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          hintText: 'Cari mitra, nama usaha, email...',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      );
}

class _PartnerStatusTabs extends StatelessWidget {
  const _PartnerStatusTabs({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('pending', 'Menunggu Verifikasi'),
      ('approved', 'Mitra Aktif'),
      ('rejected', 'Mitra Ditolak'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected == item.$1,
                  label: Text(item.$2),
                  onSelected: (_) => onChanged(item.$1),
                  selectedColor: AppColors.softBlue,
                  labelStyle: TextStyle(
                    color: selected == item.$1 ? AppColors.blue : AppColors.ink,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PartnerDataTable extends StatelessWidget {
  const _PartnerDataTable({
    required this.partners,
    required this.selectedPartnerId,
    required this.onSelect,
    required this.onDetail,
    required this.onApprove,
    required this.onReject,
  });

  final List<Mitra> partners;
  final String? selectedPartnerId;
  final ValueChanged<Mitra> onSelect;
  final ValueChanged<Mitra> onDetail;
  final ValueChanged<Mitra> onApprove;
  final ValueChanged<Mitra> onReject;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.softBlue),
          dataRowMinHeight: 68,
          dataRowMaxHeight: 76,
          showCheckboxColumn: false,
          columns: const [
            DataColumn(label: Text('No')),
            DataColumn(label: Text('Nama Usaha')),
            DataColumn(label: Text('Pemilik')),
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('No. HP')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Aksi')),
          ],
          rows: [
            for (var i = 0; i < partners.length; i++)
              DataRow(
                selected: partners[i].id == selectedPartnerId,
                onSelectChanged: (_) => onSelect(partners[i]),
                cells: [
                  DataCell(Text('${i + 1}')),
                  DataCell(_PartnerNameCell(partner: partners[i])),
                  DataCell(Text(_ownerName(partners[i]))),
                  DataCell(Text(partners[i].email)),
                  DataCell(Text(
                      partners[i].phone.isEmpty ? '-' : partners[i].phone)),
                  DataCell(
                      _MitraStatusChip(status: partners[i].verificationStatus)),
                  DataCell(_PartnerActions(
                    partner: partners[i],
                    compact: false,
                    onDetail: () => onDetail(partners[i]),
                    onApprove: () => onApprove(partners[i]),
                    onReject: () => onReject(partners[i]),
                  )),
                ],
              ),
          ],
        ),
      );
}

class _PartnerListTile extends StatelessWidget {
  const _PartnerListTile({
    required this.partner,
    required this.selected,
    required this.onTap,
    required this.onDetail,
    required this.onApprove,
    required this.onReject,
  });

  final Mitra partner;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDetail;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected ? AppColors.softBlue : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.line,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: _PartnerNameCell(partner: partner)),
                  _MitraStatusChip(status: partner.verificationStatus),
                ],
              ),
              const SizedBox(height: 10),
              Text('${_ownerName(partner)} - ${partner.email}',
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 10),
              _PartnerActions(
                partner: partner,
                compact: true,
                onDetail: onDetail,
                onApprove: onApprove,
                onReject: onReject,
              ),
            ],
          ),
        ),
      );
}

class _PartnerNameCell extends StatelessWidget {
  const _PartnerNameCell({required this.partner});

  final Mitra partner;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.softBlue,
            backgroundImage:
                partner.logoUrl.isEmpty ? null : NetworkImage(partner.logoUrl),
            child: partner.logoUrl.isEmpty
                ? Text(
                    _initials(partner.name),
                    style: const TextStyle(
                      color: AppColors.blue,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(partner.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                Text(
                  partner.description.isEmpty
                      ? 'Mitra CareGo'
                      : partner.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      );
}

class _PartnerActions extends StatelessWidget {
  const _PartnerActions({
    required this.partner,
    required this.compact,
    required this.onDetail,
    required this.onApprove,
    required this.onReject,
  });

  final Mitra partner;
  final bool compact;
  final VoidCallback onDetail;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final children = [
      OutlinedButton.icon(
        onPressed: onDetail,
        icon: const Icon(Icons.visibility_outlined, size: 16),
        label: const Text('Detail'),
      ),
      if (!partner.isApproved)
        FilledButton.icon(
          onPressed: onApprove,
          icon: const Icon(Icons.check_rounded, size: 16),
          label: const Text('Setujui'),
        ),
      if (!partner.isRejected)
        OutlinedButton.icon(
          onPressed: onReject,
          icon: const Icon(Icons.close_rounded, size: 16),
          label: const Text('Tolak'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE24A4A),
            side: const BorderSide(color: Color(0x55E24A4A)),
          ),
        ),
    ];
    if (compact) {
      return Wrap(spacing: 8, runSpacing: 8, children: children);
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(width: 6),
        children[i],
      ],
    ]);
  }
}

class _PartnerDetailPanel extends StatelessWidget {
  const _PartnerDetailPanel({
    required this.partner,
    required this.onApprove,
    required this.onReject,
  });

  final Mitra? partner;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0C10163A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: partner == null
            ? const Text('Pilih mitra untuk melihat detail.')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Detail Mitra',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                      ),
                      Icon(Icons.info_outline_rounded, color: AppColors.muted),
                    ],
                  ),
                  const Divider(height: 26),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.softBlue,
                        backgroundImage: partner!.logoUrl.isEmpty
                            ? null
                            : NetworkImage(partner!.logoUrl),
                        child: partner!.logoUrl.isEmpty
                            ? Text(
                                _initials(partner!.name),
                                style: const TextStyle(
                                  color: AppColors.blue,
                                  fontWeight: FontWeight.w900,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(partner!.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 4),
                            _MitraStatusChip(
                                status: partner!.verificationStatus),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DetailRow('Nama Pemilik', _ownerName(partner!)),
                  _DetailRow('Email', partner!.email),
                  _DetailRow('No. HP', partner!.phone),
                  _DetailRow('Alamat', partner!.address),
                  _DetailRow('Deskripsi Usaha', partner!.description),
                  if (partner!.rejectionReason.isNotEmpty)
                    _DetailRow('Alasan Ditolak', partner!.rejectionReason),
                  const Divider(height: 28),
                  const Text('Dokumen',
                      style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10),
                  _DocumentRow(label: 'Foto KTP', url: partner!.ktpUrl),
                  const SizedBox(height: 10),
                  _DocumentRow(label: 'Logo Usaha', url: partner!.logoUrl),
                  const SizedBox(height: 18),
                  const TextField(
                    minLines: 3,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tuliskan catatan admin (opsional)...',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (!partner!.isRejected)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onReject,
                            icon: const Icon(Icons.close_rounded),
                            label: const Text('Tolak'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE24A4A),
                              side: const BorderSide(
                                color: Color(0x55E24A4A),
                              ),
                            ),
                          ),
                        ),
                      if (!partner!.isRejected && !partner!.isApproved)
                        const SizedBox(width: 10),
                      if (!partner!.isApproved)
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onApprove,
                            icon: const Icon(Icons.verified_rounded),
                            label: const Text('Setujui'),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.muted, fontWeight: FontWeight.w700)),
            ),
            const Text(':  '),
            Expanded(
              child: Text(
                value.isEmpty ? '-' : value,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 58,
              height: 42,
              color: AppColors.softBlue,
              child: url.isEmpty
                  ? const Icon(Icons.image_outlined, color: AppColors.blue)
                  : Image.network(url, fit: BoxFit.cover),
            ),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: url.isEmpty ? null : () {},
            child: const Text('Lihat'),
          ),
        ],
      );
}

class _MitraStatusChip extends StatelessWidget {
  const _MitraStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'approved' => const Color(0xFF17A66A),
      'rejected' => const Color(0xFFE24A4A),
      _ => const Color(0xFFE09A16),
    };
    final label = switch (status) {
      'approved' => 'Aktif',
      'rejected' => 'Ditolak',
      _ => 'Pending',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

void _showMitraDetail(BuildContext context, Mitra partner) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(partner.name,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            _MitraStatusChip(status: partner.verificationStatus),
            const SizedBox(height: 16),
            _detailLine('Nama Pemilik', partner.ownerName),
            _detailLine('Email', partner.email),
            _detailLine('Nomor HP', partner.phone),
            _detailLine('Alamat', partner.address),
            _detailLine('Deskripsi Usaha', partner.description),
            if (partner.rejectionReason.isNotEmpty)
              _detailLine('Alasan Penolakan', partner.rejectionReason),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _documentPreview('Foto KTP', partner.ktpUrl)),
                const SizedBox(width: 12),
                Expanded(
                    child: _documentPreview('Logo Usaha', partner.logoUrl)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                if (!partner.isApproved)
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () async {
                        await AppStore.instance.approveMitra(partner.id);
                        if (sheetContext.mounted) Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Setujui'),
                    ),
                  ),
                if (!partner.isApproved && !partner.isRejected)
                  const SizedBox(width: 10),
                if (!partner.isRejected)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _showRejectDialog(context, partner);
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Tolak'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _documentPreview(String label, String url) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 130,
          color: AppColors.softPurple,
          child: url.isEmpty
              ? const Center(child: Text('Belum ada foto'))
              : Image.network(url, fit: BoxFit.cover, width: double.infinity),
        ),
      ),
    ],
  );
}

Widget _detailLine(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 3),
        Text(value.isEmpty ? '-' : value,
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

Future<void> _showRejectDialog(BuildContext context, Mitra partner) async {
  final reason = TextEditingController();
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Tolak pendaftaran mitra'),
      content: TextField(
        controller: reason,
        minLines: 3,
        maxLines: 5,
        decoration: const InputDecoration(
          labelText: 'Alasan penolakan',
          hintText: 'Contoh: Foto KTP kurang jelas.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () async {
            final text = reason.text.trim();
            if (text.isEmpty) return;
            await AppStore.instance.rejectMitra(partner.id, text);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          },
          child: const Text('Tolak'),
        ),
      ],
    ),
  );
  reason.dispose();
}

class AdminManageEmployeesScreen extends StatelessWidget {
  const AdminManageEmployeesScreen({super.key});

  @override
  Widget build(BuildContext context) => _AdminListPage(
        title: 'Kelola Pelayan',
        subtitle: 'Pelayan yang terhubung dengan Mitra',
        addLabel: 'Tambah Pelayan',
        onAdd: () => _openAdminEditor(context, _AdminEntity.employee),
        items: () => AppStore.instance.pelayans.map((employee) => _AdminItem(
              employee.name,
              employee.specialty,
              Icons.badge_outlined,
              detail: employee.available ? 'Tersedia' : 'Tidak tersedia',
              onEdit: () =>
                  _openAdminEditor(context, _AdminEntity.employee, employee),
              onDelete: () => AppStore.instance.deletePelayan(employee.id),
            )),
        onRefresh: () => AppStore.instance.refreshCatalog(),
      );
}

class AdminManageServicesScreen extends StatelessWidget {
  const AdminManageServicesScreen({super.key});

  @override
  Widget build(BuildContext context) => _AdminListPage(
        title: 'Kelola Layanan',
        subtitle: 'Layanan aktif dari seluruh Mitra',
        addLabel: 'Tambah Layanan',
        onAdd: () => _openAdminEditor(context, _AdminEntity.service),
        items: () => AppStore.instance.layanans.map((service) => _AdminItem(
              service.name,
              '${service.category} - ${AppFormatters.currency(service.price)}',
              service.icon,
              detail: service.active ? 'Aktif' : 'Nonaktif',
              onEdit: () =>
                  _openAdminEditor(context, _AdminEntity.service, service),
              onDelete: () => AppStore.instance.deleteLayanan(service.id),
            )),
        onRefresh: () => AppStore.instance.refreshCatalog(),
      );
}

class AdminManageBookingsScreen extends StatelessWidget {
  const AdminManageBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) => _AdminListPage(
        title: 'Kelola Booking',
        subtitle: 'Pantau status booking seluruh role',
        addLabel: 'Tambah Booking',
        onAdd: () => _openAdminEditor(context, _AdminEntity.booking),
        items: () => AppStore.instance.bookings.map((booking) => _AdminItem(
              booking.userName.isEmpty
                  ? 'Booking #${booking.id}'
                  : booking.userName,
              '${booking.status} - ${AppFormatters.currency(booking.total)}',
              Icons.event_available_outlined,
              detail: booking.schedule,
              onEdit: () =>
                  _openAdminEditor(context, _AdminEntity.booking, booking),
              onDelete: () => AppStore.instance.deleteAdminBooking(booking.id),
            )),
        onRefresh: () => AppStore.instance.refreshBookings(),
      );
}

class AdminManagePaymentsScreen extends StatelessWidget {
  const AdminManagePaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) => _AdminListPage(
        title: 'Kelola Pembayaran',
        subtitle: 'Pembayaran yang tercatat dari booking',
        addLabel: 'Tambah Pembayaran',
        onAdd: () => _openAdminEditor(context, _AdminEntity.payment),
        items: () => AppStore.instance.payments.map((payment) => _AdminItem(
              'Pembayaran #${payment.id}',
              '${payment.status} - ${AppFormatters.currency(payment.amount)}',
              Icons.payments_outlined,
              detail: payment.method,
              onEdit: () =>
                  _openAdminEditor(context, _AdminEntity.payment, payment),
              onDelete: () => AppStore.instance.deleteAdminPayment(payment.id),
            )),
        onRefresh: () => AppStore.instance.refreshAdminPayments(),
      );
}

enum _AdminEntity { user, partner, employee, service, booking, payment }

Future<void> _openAdminEditor(
  BuildContext context,
  _AdminEntity entity, [
  Object? value,
]) async {
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AdminEditorSheet(entity: entity, value: value),
  );
}

class _AdminEditorSheet extends StatefulWidget {
  const _AdminEditorSheet({required this.entity, this.value});

  final _AdminEntity entity;
  final Object? value;

  @override
  State<_AdminEditorSheet> createState() => _AdminEditorSheetState();
}

class _AdminEditorSheetState extends State<_AdminEditorSheet> {
  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final address = TextEditingController();
  final description = TextEditingController();
  final specialization = TextEditingController();
  final experience = TextEditingController(text: '0');
  final price = TextEditingController();
  final duration = TextEditingController(text: '60');
  final schedule = TextEditingController();
  final distance = TextEditingController(text: '0');
  final notes = TextEditingController();
  final method = TextEditingController(text: 'MANUAL');
  final amount = TextEditingController();

  String status = 'ACTIVE';
  String category = 'Cukur Rambut';
  String? mitraId;
  String? userId;
  String? employeeId;
  String? serviceId;
  String? bookingId;
  bool active = true;
  bool submitting = false;

  bool get editing => widget.value != null;

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    schedule.text =
        '${tomorrow.year.toString().padLeft(4, '0')}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')} 09:00';
    switch (widget.value) {
      case final User user:
        name.text = user.name;
        email.text = user.email;
        phone.text = user.phone;
        status = user.status;
      case final Mitra partner:
        name.text = partner.name;
        email.text = partner.email;
        phone.text = partner.phone;
        address.text = partner.address;
        description.text = partner.description;
        active = partner.isApproved;
      case final Pelayan employee:
        name.text = employee.name;
        email.text = employee.email;
        phone.text = employee.phone;
        specialization.text = employee.specialty;
        experience.text = '${employee.experienceYears}';
        mitraId = employee.mitraId;
        active = employee.available;
      case final Layanan service:
        name.text = service.name;
        category = service.category;
        description.text = service.description;
        price.text = '${service.price}';
        duration.text = service.duration.replaceAll(RegExp(r'[^0-9]'), '');
        mitraId = service.mitraId;
        active = service.active;
      case final Booking booking:
        status = booking.status;
      case final Pembayaran payment:
        bookingId = payment.bookingId;
        method.text = payment.method;
        status = payment.status;
        amount.text = '${payment.amount}';
      default:
        status = widget.entity == _AdminEntity.payment ? 'PENDING' : 'ACTIVE';
    }
  }

  @override
  void dispose() {
    for (final controller in [
      name,
      email,
      phone,
      password,
      address,
      description,
      specialization,
      experience,
      price,
      duration,
      schedule,
      distance,
      notes,
      method,
      amount,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _error(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _required(Iterable<TextEditingController> controllers) {
    if (controllers.any((controller) => controller.text.trim().isEmpty)) {
      _error('Lengkapi semua data wajib.');
      return false;
    }
    if (!editing &&
        password.text.length < 8 &&
        widget.entity != _AdminEntity.service &&
        widget.entity != _AdminEntity.booking &&
        widget.entity != _AdminEntity.payment) {
      _error('Password minimal 8 karakter.');
      return false;
    }
    return true;
  }

  Future<void> _submit() async {
    setState(() => submitting = true);
    try {
      switch (widget.entity) {
        case _AdminEntity.user:
          if (!_required([name, email])) return;
          final user = widget.value as User?;
          if (user == null) {
            await AppStore.instance.createAdminUser(
              name: name.text.trim(),
              email: email.text.trim(),
              phone: phone.text.trim(),
              password: password.text,
              status: status,
            );
          } else {
            await AppStore.instance.updateAdminUser(
              user.id,
              name: name.text.trim(),
              email: email.text.trim(),
              phone: phone.text.trim(),
              password: password.text,
              status: status,
            );
          }
        case _AdminEntity.partner:
          if (!_required([name, email, address])) return;
          final partner = widget.value as Mitra?;
          if (partner == null) {
            await AppStore.instance.createAdminMitra(
              name: name.text.trim(),
              email: email.text.trim(),
              phone: phone.text.trim(),
              password: password.text,
              address: address.text.trim(),
              description: description.text.trim(),
              verified: active,
            );
          } else {
            await AppStore.instance.updateAdminMitra(
              partner.id,
              name: name.text.trim(),
              email: email.text.trim(),
              phone: phone.text.trim(),
              password: password.text,
              address: address.text.trim(),
              description: description.text.trim(),
              verified: active,
            );
          }
        case _AdminEntity.employee:
          if (!_required([name, email, specialization]) || mitraId == null) {
            if (mitraId == null) _error('Pilih Mitra tempat bekerja.');
            return;
          }
          final employee = widget.value as Pelayan?;
          if (employee == null) {
            await AppStore.instance.createPelayan(
              name: name.text.trim(),
              email: email.text.trim(),
              phone: phone.text.trim(),
              password: password.text,
              specialization: specialization.text.trim(),
              experienceYears: int.tryParse(experience.text) ?? 0,
              mitraId: mitraId,
            );
          } else {
            await AppStore.instance.updateAdminPelayan(
              employee.id,
              mitraId: mitraId!,
              name: name.text.trim(),
              email: email.text.trim(),
              phone: phone.text.trim(),
              password: password.text,
              specialization: specialization.text.trim(),
              experienceYears: int.tryParse(experience.text) ?? 0,
              available: active,
            );
          }
        case _AdminEntity.service:
          if (!_required([name, price, duration]) || mitraId == null) {
            if (mitraId == null) _error('Pilih Mitra pemilik layanan.');
            return;
          }
          final service = widget.value as Layanan?;
          if (service == null) {
            await AppStore.instance.createLayanan(
              name: name.text.trim(),
              category: category,
              description: description.text.trim(),
              price: int.tryParse(price.text) ?? 0,
              durationMinutes: int.tryParse(duration.text) ?? 0,
              mitraId: mitraId,
            );
          } else {
            await AppStore.instance.updateLayanan(
              service.id,
              mitraId: mitraId,
              name: name.text.trim(),
              category: category,
              description: description.text.trim(),
              price: int.tryParse(price.text) ?? 0,
              durationMinutes: int.tryParse(duration.text) ?? 0,
              active: active,
            );
          }
        case _AdminEntity.booking:
          final booking = widget.value as Booking?;
          if (booking == null) {
            if (userId == null ||
                mitraId == null ||
                employeeId == null ||
                serviceId == null ||
                address.text.trim().isEmpty) {
              _error(
                  'Lengkapi pelanggan, mitra, pelayan, layanan, dan alamat.');
              return;
            }
            final parsed =
                DateTime.tryParse(schedule.text.trim().replaceFirst(' ', 'T'));
            if (parsed == null || !parsed.isAfter(DateTime.now())) {
              _error('Jadwal harus valid dan berada di masa mendatang.');
              return;
            }
            await AppStore.instance.createAdminBooking(
              userId: userId!,
              mitraId: mitraId!,
              pelayanId: employeeId!,
              layananId: serviceId!,
              scheduledAt: parsed,
              address: address.text.trim(),
              distanceKm: double.tryParse(distance.text) ?? 0,
              notes: notes.text.trim(),
            );
          } else {
            if (status == booking.status) {
              _error('Pilih status baru untuk booking.');
              return;
            }
            await AppStore.instance.updateBookingStatus(booking.id, status);
          }
        case _AdminEntity.payment:
          if (bookingId == null || method.text.trim().isEmpty) {
            _error('Pilih booking dan isi metode pembayaran.');
            return;
          }
          final payment = widget.value as Pembayaran?;
          if (payment == null) {
            await AppStore.instance.createAdminPayment(
              bookingId: bookingId!,
              method: method.text.trim(),
              status: status,
              amount: int.tryParse(amount.text),
            );
          } else {
            await AppStore.instance.updateAdminPayment(
              payment.id,
              bookingId: bookingId!,
              method: method.text.trim(),
              status: status,
              amount: int.tryParse(amount.text),
            );
          }
      }
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (error) {
      if (mounted) _error(error.message);
    } catch (_) {
      if (mounted) _error('Data gagal disimpan. Periksa kembali input Anda.');
    } finally {
      if (mounted) setState(() => submitting = false);
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${editing ? 'Edit' : 'Tambah'} ${_entityLabel(widget.entity)}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 14),
              ..._fields(),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: submitting ? null : _submit,
                  child: Text(submitting ? 'Menyimpan...' : 'Simpan'),
                ),
              ),
            ],
          ),
        ),
      );

  List<Widget> _fields() {
    switch (widget.entity) {
      case _AdminEntity.user:
        return [
          _text(name, 'Nama'),
          _text(email, 'Email', keyboard: TextInputType.emailAddress),
          _text(phone, 'Nomor Telepon', keyboard: TextInputType.phone),
          _text(password, editing ? 'Password baru (opsional)' : 'Password'),
          _dropdown(
            'Status',
            status,
            const ['ACTIVE', 'PENDING', 'SUSPENDED'],
            (value) => setState(() => status = value),
          ),
        ];
      case _AdminEntity.partner:
        return [
          _text(name, 'Nama Mitra'),
          _text(email, 'Email', keyboard: TextInputType.emailAddress),
          _text(phone, 'Nomor Telepon', keyboard: TextInputType.phone),
          _text(password, editing ? 'Password baru (opsional)' : 'Password'),
          _text(address, 'Alamat', lines: 2),
          _text(description, 'Deskripsi', lines: 2),
          _toggle('Mitra terverifikasi', active),
        ];
      case _AdminEntity.employee:
        return [
          _mitraDropdown(),
          _text(name, 'Nama Pelayan'),
          _text(email, 'Email', keyboard: TextInputType.emailAddress),
          _text(phone, 'Nomor Telepon', keyboard: TextInputType.phone),
          _text(password, editing ? 'Password baru (opsional)' : 'Password'),
          _text(specialization, 'Spesialisasi (pisahkan dengan koma)'),
          _text(experience, 'Tahun Pengalaman', keyboard: TextInputType.number),
          if (editing) _toggle('Pelayan tersedia', active),
        ];
      case _AdminEntity.service:
        return [
          _mitraDropdown(),
          _text(name, 'Nama Layanan'),
          _dropdown(
            'Kategori',
            category,
            const ['Cukur Rambut', 'Salon', 'Nail Art', 'Facial', 'Make Up'],
            (value) => setState(() => category = value),
          ),
          _text(description, 'Deskripsi', lines: 2),
          _text(price, 'Harga', keyboard: TextInputType.number),
          _text(duration, 'Durasi (menit)', keyboard: TextInputType.number),
          if (editing) _toggle('Layanan aktif', active),
        ];
      case _AdminEntity.booking:
        if (editing) {
          final booking = widget.value as Booking;
          final options = _bookingStatusOptions(booking.status);
          return [
            _dropdown(
              'Status Booking',
              status,
              options,
              (value) => setState(() => status = value),
            ),
          ];
        }
        return [
          _userDropdown(),
          _mitraDropdown(onChanged: (_) {
            employeeId = null;
            serviceId = null;
          }),
          _employeeDropdown(),
          _serviceDropdown(),
          _text(schedule, 'Jadwal (YYYY-MM-DD HH:mm)'),
          _text(address, 'Alamat Layanan', lines: 2),
          _text(distance, 'Jarak (KM)', keyboard: TextInputType.number),
          _text(notes, 'Catatan', lines: 2),
        ];
      case _AdminEntity.payment:
        return [
          _bookingDropdown(),
          _text(method, 'Metode Pembayaran'),
          _dropdown(
            'Status Pembayaran',
            status,
            const ['PENDING', 'PAID', 'FAILED', 'EXPIRED', 'REFUNDED'],
            (value) => setState(() => status = value),
          ),
          _text(amount, 'Total Bayar', keyboard: TextInputType.number),
        ];
    }
  }

  Widget _text(
    TextEditingController controller,
    String label, {
    TextInputType? keyboard,
    int lines = 1,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          keyboardType: keyboard,
          maxLines: lines,
          obscureText: controller == password,
          enabled: !submitting,
          decoration: InputDecoration(labelText: label),
        ),
      );

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          initialValue: options.contains(value) ? value : options.first,
          decoration: InputDecoration(labelText: label),
          items: options
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: submitting
              ? null
              : (selected) {
                  if (selected != null) onChanged(selected);
                },
        ),
      );

  Widget _toggle(String label, bool value) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        value: value,
        onChanged:
            submitting ? null : (selected) => setState(() => active = selected),
      );

  Widget _mitraDropdown({ValueChanged<String>? onChanged}) =>
      _idDropdown<Mitra>(
        label: 'Mitra',
        value: mitraId,
        items: AppStore.instance.mitras,
        id: (item) => item.id,
        title: (item) => item.name,
        onChanged: (selected) {
          setState(() => mitraId = selected);
          onChanged?.call(selected);
        },
      );

  Widget _userDropdown() => _idDropdown<User>(
        label: 'Pelanggan',
        value: userId,
        items: AppStore.instance.users
            .where((item) => item.role == AppRole.user)
            .toList(),
        id: (item) => item.id,
        title: (item) => '${item.name} (${item.email})',
        onChanged: (selected) => setState(() => userId = selected),
      );

  Widget _employeeDropdown() => _idDropdown<Pelayan>(
        label: 'Pelayan',
        value: employeeId,
        items: AppStore.instance.pelayans
            .where((item) => mitraId == null || item.mitraId == mitraId)
            .toList(),
        id: (item) => item.id,
        title: (item) => item.name,
        onChanged: (selected) => setState(() => employeeId = selected),
      );

  Widget _serviceDropdown() => _idDropdown<Layanan>(
        label: 'Layanan',
        value: serviceId,
        items: AppStore.instance.layanans
            .where((item) => mitraId == null || item.mitraId == mitraId)
            .toList(),
        id: (item) => item.id,
        title: (item) => item.name,
        onChanged: (selected) => setState(() => serviceId = selected),
      );

  Widget _bookingDropdown() => _idDropdown<Booking>(
        label: 'Booking',
        value: bookingId,
        items: AppStore.instance.bookings,
        id: (item) => item.id,
        title: (item) => '#${item.id} - ${item.userName}',
        onChanged: (selected) {
          setState(() {
            bookingId = selected;
            final booking = AppStore.instance.bookings
                .firstWhere((item) => item.id == selected);
            if (amount.text.isEmpty) amount.text = '${booking.total}';
          });
        },
      );

  Widget _idDropdown<T>({
    required String label,
    required String? value,
    required List<T> items,
    required String Function(T item) id,
    required String Function(T item) title,
    required ValueChanged<String> onChanged,
  }) {
    final ids = items.map(id).toSet();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        key: ValueKey('$label-${value ?? ''}-${items.map(id).join(',')}'),
        initialValue: ids.contains(value) ? value : null,
        decoration: InputDecoration(labelText: label),
        items: items
            .map((item) => DropdownMenuItem(
                  value: id(item),
                  child: Text(title(item), overflow: TextOverflow.ellipsis),
                ))
            .toList(),
        onChanged: submitting
            ? null
            : (selected) {
                if (selected != null) onChanged(selected);
              },
      ),
    );
  }
}

String _entityLabel(_AdminEntity entity) => switch (entity) {
      _AdminEntity.user => 'User',
      _AdminEntity.partner => 'Mitra',
      _AdminEntity.employee => 'Pelayan',
      _AdminEntity.service => 'Layanan',
      _AdminEntity.booking => 'Booking',
      _AdminEntity.payment => 'Pembayaran',
    };

List<String> _bookingStatusOptions(String current) {
  const next = {
    'Menunggu Pembayaran': [
      'Menunggu Pembayaran',
      'Menunggu Mitra',
      'Dibatalkan'
    ],
    'Menunggu Mitra': [
      'Menunggu Mitra',
      'Diterima Mitra',
      'Ditolak Mitra',
      'Dibatalkan'
    ],
    'Diterima Mitra': ['Diterima Mitra', 'Dikirim ke Pelayan', 'Dibatalkan'],
    'Dikirim ke Pelayan': [
      'Dikirim ke Pelayan',
      'Diterima Pelayan',
      'Ditolak Pelayan',
      'Dibatalkan'
    ],
    'Diterima Pelayan': ['Diterima Pelayan', 'Menuju Lokasi', 'Dibatalkan'],
    'Menuju Lokasi': ['Menuju Lokasi', 'Sedang Dikerjakan'],
    'Sedang Dikerjakan': ['Sedang Dikerjakan', 'Selesai'],
    'Selesai': ['Selesai'],
    'Dibatalkan': ['Dibatalkan'],
    'Ditolak Mitra': ['Ditolak Mitra'],
    'Ditolak Pelayan': ['Ditolak Pelayan'],
  };
  return next[current] ?? [current];
}

class AdminManageVouchersScreen extends StatelessWidget {
  const AdminManageVouchersScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Kelola Voucher'),
          actions: [
            IconButton(
              onPressed: () => _showVoucherSheet(context),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: AppStore.instance,
          builder: (context, _) => ResponsivePage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Voucher & Promo',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Buat, nonaktifkan, dan pantau kuota voucher.',
                    style: TextStyle(color: AppColors.muted)),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _showVoucherSheet(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Tambah Voucher'),
                  ),
                ),
                const SizedBox(height: 14),
                ...AppStore.instance.vouchers.map((voucher) => InfoCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            backgroundColor: AppColors.softPurple,
                            foregroundColor: AppColors.purple,
                            child: Icon(Icons.confirmation_number_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${voucher['code']}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900)),
                                Text('${voucher['name'] ?? '-'}',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.muted)),
                                const SizedBox(height: 4),
                                Text(
                                  'Kuota ${voucher['used_count'] ?? 0}/${voucher['quota'] ?? 'tak terbatas'}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(_voucherDiscountLabel(voucher),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.purple)),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    _showVoucherSheet(context,
                                        voucher: voucher);
                                    return;
                                  }
                                  await AppStore.instance
                                      .deleteVoucher('${voucher['id']}');
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                      value: 'edit', child: Text('Edit')),
                                  PopupMenuItem(
                                      value: 'delete', child: Text('Hapus')),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ),
      );

  static String _voucherDiscountLabel(Map<String, dynamic> voucher) {
    final value = double.tryParse('${voucher['discount_value'] ?? 0}') ?? 0;
    if (voucher['discount_type'] == 'PERCENT') return '${value.round()}%';
    return AppFormatters.currency(value.round());
  }

  static void _showVoucherSheet(
    BuildContext context, {
    Map<String, dynamic>? voucher,
  }) {
    final code = TextEditingController(text: '${voucher?['code'] ?? ''}');
    final name = TextEditingController(text: '${voucher?['name'] ?? ''}');
    final value =
        TextEditingController(text: '${voucher?['discount_value'] ?? ''}');
    final minimum =
        TextEditingController(text: '${voucher?['min_transaction'] ?? 0}');
    final maximum =
        TextEditingController(text: '${voucher?['max_discount'] ?? ''}');
    final quota = TextEditingController(text: '${voucher?['quota'] ?? ''}');
    var type = '${voucher?['discount_type'] ?? 'PERCENT'}';
    var active = voucher?['is_active'] as bool? ?? true;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(voucher == null ? 'Tambah Voucher' : 'Edit Voucher',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                TextField(
                    controller: code,
                    decoration: const InputDecoration(labelText: 'Kode')),
                const SizedBox(height: 10),
                TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Nama')),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tipe Diskon'),
                  items: const [
                    DropdownMenuItem(value: 'PERCENT', child: Text('Persen')),
                    DropdownMenuItem(value: 'FIXED', child: Text('Nominal')),
                  ],
                  onChanged: (value) =>
                      setSheetState(() => type = value ?? type),
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: value,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Nilai diskon')),
                const SizedBox(height: 10),
                TextField(
                    controller: minimum,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Minimum transaksi')),
                const SizedBox(height: 10),
                TextField(
                    controller: maximum,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Maksimal diskon')),
                const SizedBox(height: 10),
                TextField(
                    controller: quota,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Kuota')),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  value: active,
                  onChanged: (value) => setSheetState(() => active = value),
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final payload = (
                        code: code.text.trim().toUpperCase(),
                        name: name.text.trim(),
                        discountType: type,
                        discountValue: int.tryParse(value.text) ?? 0,
                        minTransaction: int.tryParse(minimum.text) ?? 0,
                        maxDiscount: int.tryParse(maximum.text),
                        quota: int.tryParse(quota.text),
                        active: active,
                      );
                      if (voucher == null) {
                        await AppStore.instance.createVoucher(
                          code: payload.code,
                          name: payload.name,
                          discountType: payload.discountType,
                          discountValue: payload.discountValue,
                          minTransaction: payload.minTransaction,
                          maxDiscount: payload.maxDiscount,
                          quota: payload.quota,
                          active: payload.active,
                        );
                      } else {
                        await AppStore.instance.updateVoucher(
                          '${voucher['id']}',
                          code: payload.code,
                          name: payload.name,
                          discountType: payload.discountType,
                          discountValue: payload.discountValue,
                          minTransaction: payload.minTransaction,
                          maxDiscount: payload.maxDiscount,
                          quota: payload.quota,
                          active: payload.active,
                        );
                      }
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: const Text('Simpan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dashboard = AppStore.instance.dashboard;
    final reports = [
      (
        'Total Pengguna',
        '${dashboard['users'] ?? 0}',
        Icons.people_outline_rounded
      ),
      (
        'Total Booking',
        '${dashboard['bookings'] ?? 0}',
        Icons.event_note_outlined
      ),
      (
        'Revenue Platform',
        AppFormatters.currency(
            double.tryParse('${dashboard['revenue'] ?? 0}')?.round() ?? 0),
        Icons.payments_outlined
      ),
      ('Mitra Aktif', '${dashboard['mitras'] ?? 0}', Icons.storefront_outlined),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: ResponsivePage(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ringkasan Platform',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          ...reports.map((item) => InfoCard(
                child: Row(children: [
                  CircleAvatar(
                      backgroundColor: AppColors.softPurple,
                      child: Icon(item.$3, color: AppColors.purple)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.$1)),
                  Text(item.$2,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w900)),
                ]),
              )),
        ]),
      ),
    );
  }
}

class _AdminItem {
  const _AdminItem(
    this.title,
    this.subtitle,
    this.icon, {
    this.detail = '',
    required this.onEdit,
    required this.onDelete,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final String detail;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
}

class _AdminListPage extends StatefulWidget {
  const _AdminListPage({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.onRefresh,
    required this.addLabel,
    required this.onAdd,
  });

  final String title;
  final String subtitle;
  final Iterable<_AdminItem> Function() items;
  final Future<void> Function() onRefresh;
  final String addLabel;
  final VoidCallback onAdd;

  @override
  State<_AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<_AdminListPage> {
  final search = TextEditingController();

  @override
  void initState() {
    super.initState();
    AppStore.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    AppStore.instance.removeListener(_refresh);
    search.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success)),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  Future<void> _confirmDelete(_AdminItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus data?'),
        content: Text('${item.title} akan dihapus dari backend.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _run(item.onDelete, 'Data berhasil dihapus.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final filtered = widget.items().where((item) {
      return query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query) ||
          item.detail.toLowerCase().contains(query);
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ResponsivePage(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.subtitle, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onAdd,
              icon: const Icon(Icons.add_rounded),
              label: Text(widget.addLabel),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Cari data...',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: 16),
          if (filtered.isEmpty)
            const InfoCard(child: Text('Belum ada data dari backend.'))
          else
            ...filtered.map((item) => InfoCard(
                  child: Row(children: [
                    CircleAvatar(
                        backgroundColor: AppColors.softPurple,
                        child: Icon(item.icon, color: AppColors.purple)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(item.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w900)),
                          Text(item.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.muted)),
                          if (item.detail.isNotEmpty)
                            Text(item.detail,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10)),
                        ])),
                    PopupMenuButton<String>(
                      onSelected: (action) {
                        if (action == 'edit') {
                          item.onEdit();
                        } else {
                          _confirmDelete(item);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Hapus')),
                      ],
                    ),
                  ]),
                )),
        ]),
      ),
    );
  }
}
