import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/app_models.dart';
import '../../utils/formatters.dart';
import 'therapist_confirmation_sheet.dart';

const _detailPurple = Color(0xFF6548EE);
const _detailInk = Color(0xFF17172A);
const _detailMuted = Color(0xFF73758A);
const _detailLine = Color(0xFFE8E6F2);

class TherapistDetailPage extends StatelessWidget {
  const TherapistDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args = Map<String, dynamic>.from(
        ModalRoute.of(context)?.settings.arguments as Map? ?? {});
    final store = AppStore.instance;
    final employeeMatches =
        store.pelayans.where((item) => item.id == '${args['employeeId']}');
    if (employeeMatches.isEmpty) {
      return const Scaffold(
          body: Center(child: Text('Data pelayan tidak ditemukan.')));
    }
    final employee = employeeMatches.first;
    final serviceMatches =
        store.layanans.where((item) => item.id == '${args['serviceId']}');
    final services = store.layanans
        .where((item) => item.mitraId == employee.mitraId)
        .toList();
    final service = serviceMatches.isNotEmpty
        ? serviceMatches.first
        : (services.isEmpty ? null : services.first);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFF),
      appBar: AppBar(
        title: const Text('Detail Pelayan',
            style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.share_outlined))
        ],
      ),
      bottomNavigationBar: service == null
          ? null
          : _BottomSelection(
              service: service,
              onChoose: () => showTherapistConfirmationSheet(
                context,
                employee: employee,
                service: service,
              ),
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
            children: [
              _Hero(employee: employee),
              const SizedBox(height: 14),
              _Intro(employee: employee, service: service),
              const SizedBox(height: 14),
              _Section(
                title: 'Keahlian & Spesialisasi',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Skill(employee.specialty),
                    ...services.map((item) => _Skill(item.category)),
                  ],
                ),
              ),
              _Section(
                title: 'Tentang Saya',
                child: Text(
                  employee.bio.isEmpty
                      ? 'Pelayan profesional CareGo yang siap memberikan layanan terbaik di lokasi Anda.'
                      : employee.bio,
                  style: const TextStyle(color: _detailMuted, height: 1.55),
                ),
              ),
              _Section(
                title: 'Portofolio Hasil Kerja',
                child: employee.portfolioItems.isEmpty
                    ? const Text('Belum ada portofolio.',
                        style: TextStyle(color: _detailMuted))
                    : SizedBox(
                        height: 145,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: employee.portfolioItems.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, index) {
                            final portfolio = employee.portfolioItems[index];
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(13),
                              child: Image.network(
                                portfolio.imageUrl,
                                width: 180,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 180,
                                  color: const Color(0xFFECE8FF),
                                  child: const Icon(Icons.photo_outlined,
                                      color: _detailPurple),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              _Section(
                title: 'Rating & Ulasan',
                child: _RatingSummary(employee: employee),
              ),
              _Section(
                title: 'Ulasan Pelanggan',
                child: employee.reviewItems.isEmpty
                    ? const Text('Belum ada ulasan pelanggan.',
                        style: TextStyle(color: _detailMuted))
                    : Column(
                        children: employee.reviewItems
                            .map((review) => _ReviewCard(review: review))
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.employee});
  final Pelayan employee;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(children: [
          employee.photoUrl.isEmpty
              ? Container(
                  height: 330,
                  width: double.infinity,
                  color: const Color(0xFFECE8FF),
                  child: const Icon(Icons.person_rounded,
                      size: 150, color: _detailPurple))
              : Image.network(employee.photoUrl,
                  height: 330,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      height: 330,
                      color: const Color(0xFFECE8FF),
                      child: const Icon(Icons.person_rounded,
                          size: 150, color: _detailPurple))),
          Positioned(
            left: 12,
            top: 12,
            child: Chip(
              label: Text(
                  employee.available ? 'Tersedia Hari Ini' : 'Tidak Tersedia'),
              backgroundColor: employee.available
                  ? const Color(0xFF24B76A)
                  : const Color(0xFF8D8D99),
              labelStyle: const TextStyle(color: Colors.white, fontSize: 11),
              side: BorderSide.none,
            ),
          ),
        ]),
      );
}

class _Intro extends StatelessWidget {
  const _Intro({required this.employee, required this.service});
  final Pelayan employee;
  final Layanan? service;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text(employee.name,
                    style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: _detailInk)),
              ),
              const Icon(Icons.verified_rounded, color: _detailPurple),
            ]),
            Text(employee.specialty,
                style: const TextStyle(color: _detailMuted)),
            const SizedBox(height: 10),
            Text(
              '⭐ ${employee.rating.toStringAsFixed(1)}  (${employee.reviewItems.length} Ulasan)   |   ${employee.experienceYears} Tahun Pengalaman',
              style: const TextStyle(color: _detailMuted, fontSize: 12),
            ),
            if (service != null) ...[
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: Chip(
                        label: Text(service!.name),
                        side: BorderSide.none,
                        backgroundColor: const Color(0xFFF0ECFF))),
                Text(AppFormatters.currency(service!.price),
                    style: const TextStyle(
                        color: _detailPurple,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
              ]),
            ],
          ]),
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: _detailInk)),
            const SizedBox(height: 14),
            child,
          ]),
        ),
      );
}

class _Skill extends StatelessWidget {
  const _Skill(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        avatar: const Icon(Icons.auto_awesome_rounded,
            size: 16, color: _detailPurple),
        label: Text(label),
        side: const BorderSide(color: _detailLine),
        backgroundColor: const Color(0xFFF8F6FF),
      );
}

class _RatingSummary extends StatelessWidget {
  const _RatingSummary({required this.employee});
  final Pelayan employee;

  @override
  Widget build(BuildContext context) {
    final reviews = employee.reviewItems;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        width: 95,
        child: Column(children: [
          Text(employee.rating.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                  color: _detailInk)),
          const Text('★★★★★',
              style: TextStyle(color: Colors.amber, letterSpacing: 1)),
          Text('${reviews.length} ulasan',
              style: const TextStyle(fontSize: 11, color: _detailMuted)),
        ]),
      ),
      const SizedBox(width: 15),
      Expanded(
        child: Column(
          children: List.generate(5, (index) {
            final star = 5 - index;
            final count =
                reviews.where((review) => review.rating.round() == star).length;
            final ratio = reviews.isEmpty ? 0.0 : count / reviews.length;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                SizedBox(
                    width: 22,
                    child: Text('$star', style: const TextStyle(fontSize: 11))),
                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                const SizedBox(width: 5),
                Expanded(child: LinearProgressIndicator(value: ratio)),
                const SizedBox(width: 8),
                SizedBox(
                    width: 22,
                    child:
                        Text('$count', style: const TextStyle(fontSize: 10))),
              ]),
            );
          }),
        ),
      ),
    ]);
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});
  final Review review;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: _detailLine))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFECE8FF),
            child: Text(review.userName.isEmpty ? 'U' : review.userName[0]),
          ),
          const SizedBox(width: 11),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(review.userName,
                        style: const TextStyle(fontWeight: FontWeight.w800))),
                Text(review.createdAt,
                    style: const TextStyle(fontSize: 9, color: _detailMuted)),
              ]),
              Text('★' * review.rating.round(),
                  style: const TextStyle(color: Colors.amber)),
              const SizedBox(height: 5),
              Text(review.comment,
                  style: const TextStyle(color: _detailMuted, height: 1.4)),
            ]),
          ),
        ]),
      );
}

class _BottomSelection extends StatelessWidget {
  const _BottomSelection({required this.service, required this.onChoose});
  final Layanan service;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Color(0x16000000), blurRadius: 16)],
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppFormatters.currency(service.price),
                      style: const TextStyle(
                          color: _detailPurple,
                          fontSize: 17,
                          fontWeight: FontWeight.w900)),
                  Text('${service.name} • ${service.duration}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontSize: 10, color: _detailMuted)),
                ],
              ),
            ),
            FilledButton(
                onPressed: onChoose, child: const Text('Pilih Pelayan')),
          ]),
        ),
      );
}
