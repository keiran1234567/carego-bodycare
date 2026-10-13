import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../../models/app_models.dart';
import '../../utils/app_routes.dart';
import '../../utils/formatters.dart';
import 'therapist_confirmation_sheet.dart';

const _categoryPurple = Color(0xFF6548EE);
const _categoryInk = Color(0xFF151529);
const _categoryMuted = Color(0xFF74758A);

class CategoryTherapistsPage extends StatefulWidget {
  const CategoryTherapistsPage({super.key});

  @override
  State<CategoryTherapistsPage> createState() => _CategoryTherapistsPageState();
}

class _CategoryTherapistsPageState extends State<CategoryTherapistsPage> {
  final search = TextEditingController();
  bool availableOnly = false;
  bool highestRating = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category =
        (ModalRoute.of(context)?.settings.arguments as String?) ?? 'Layanan';
    final store = AppStore.instance;
    final categoryServices = store.layanans
        .where((service) =>
            _matches(category, service.category) ||
            _matches(category, service.name))
        .toList();
    var employees = store.pelayans
        .where((employee) {
          return _employeeMatchesCategory(employee, category);
        })
        .where((employee) {
          final value = search.text.trim().toLowerCase();
          return value.isEmpty ||
              employee.name.toLowerCase().contains(value) ||
              employee.specialty.toLowerCase().contains(value);
        })
        .where((employee) => !availableOnly || employee.available)
        .toList();
    if (highestRating) {
      employees.sort((a, b) => b.rating.compareTo(a.rating));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFF),
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(category, style: const TextStyle(fontWeight: FontWeight.w900)),
          const Text('Pilih pelayan terbaik untuk perawatan Anda',
              style: TextStyle(fontSize: 11, color: _categoryMuted)),
        ]),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 26),
            children: [
              TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Cari nama pelayan...',
                  prefixIcon: Icon(Icons.search_rounded),
                  suffixIcon: Icon(Icons.tune_rounded),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  FilterChip(
                    selected: !availableOnly && !highestRating,
                    label: const Text('Semua Pelayan'),
                    onSelected: (_) => setState(() {
                      availableOnly = false;
                      highestRating = false;
                    }),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: highestRating,
                    label: const Text('Rating Tertinggi'),
                    onSelected: (value) =>
                        setState(() => highestRating = value),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    selected: availableOnly,
                    label: const Text('Tersedia'),
                    onSelected: (value) =>
                        setState(() => availableOnly = value),
                  ),
                ]),
              ),
              const SizedBox(height: 14),
              if (employees.isEmpty)
                const _EmptyCategory()
              else
                ...employees.map((employee) {
                  final services = categoryServices
                      .where((service) =>
                          service.mitraId == employee.mitraId &&
                          _employeeMatchesService(employee, service))
                      .toList();
                  final service = services.isEmpty ? null : services.first;
                  return _TherapistCard(
                    employee: employee,
                    service: service,
                    onChoose: () {
                      if (service == null) return;
                      showTherapistConfirmationSheet(
                        context,
                        employee: employee,
                        service: service,
                      );
                    },
                    onDetail: () => Navigator.pushNamed(
                      context,
                      AppRoutes.userTherapistDetail,
                      arguments: {
                        'employeeId': employee.id,
                        'serviceId': service?.id ?? '',
                        'category': category,
                      },
                    ),
                  );
                }),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1EEFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(children: [
                  Icon(Icons.verified_user_rounded, color: _categoryPurple),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Semua pelayan terhubung dengan Mitra CareGo dan datanya berasal dari backend.',
                      style: TextStyle(fontSize: 12, color: _categoryMuted),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TherapistCard extends StatelessWidget {
  const _TherapistCard(
      {required this.employee,
      required this.service,
      required this.onChoose,
      required this.onDetail});
  final Pelayan employee;
  final Layanan? service;
  final VoidCallback onChoose;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: service == null ? onDetail : onChoose,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Stack(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _PersonImage(
                    url: employee.photoUrl, width: 112, height: 150),
              ),
              Positioned(
                left: 5,
                top: 5,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: employee.available
                        ? const Color(0xFF20B86A)
                        : const Color(0xFF8B8B9B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                      employee.available ? 'Tersedia' : 'Tidak tersedia',
                      style: const TextStyle(color: Colors.white, fontSize: 8)),
                ),
              ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(
                        child: Text(employee.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _categoryInk)),
                      ),
                      const SizedBox(width: 5),
                      const Icon(Icons.verified_rounded,
                          size: 16, color: _categoryPurple),
                    ]),
                    Text(employee.specialty,
                        style: const TextStyle(
                            fontSize: 11, color: _categoryMuted)),
                    const SizedBox(height: 7),
                    Text(
                      '⭐ ${employee.rating.toStringAsFixed(1)}  (${employee.reviewItems.length})   •   ${employee.experienceYears} Tahun',
                      style:
                          const TextStyle(fontSize: 10, color: _categoryMuted),
                    ),
                    const SizedBox(height: 7),
                    Text('Spesialis: ${employee.specialty}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 10, color: _categoryMuted)),
                    const SizedBox(height: 6),
                    const Text('◉ 2.4 km dari Anda',
                        style: TextStyle(fontSize: 10, color: _categoryMuted)),
                    const SizedBox(height: 8),
                    Row(children: [
                      Expanded(
                        child: Text(
                          service == null
                              ? 'Harga belum tersedia'
                              : AppFormatters.currency(service!.price),
                          style: const TextStyle(
                              color: _categoryPurple,
                              fontWeight: FontWeight.w900,
                              fontSize: 15),
                        ),
                      ),
                      FilledButton(
                        onPressed: service == null ? null : onChoose,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(68, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text('Pilih'),
                      ),
                    ]),
                  ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _PersonImage extends StatelessWidget {
  const _PersonImage(
      {required this.url, required this.width, required this.height});
  final String url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: const Color(0xFFECE8FF),
        child:
            const Icon(Icons.person_rounded, size: 60, color: _categoryPurple),
      );
    }
    return Image.network(url,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
              width: width,
              height: height,
              color: const Color(0xFFECE8FF),
              child: const Icon(Icons.person_rounded,
                  size: 60, color: _categoryPurple),
            ));
  }
}

class _EmptyCategory extends StatelessWidget {
  const _EmptyCategory();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(children: [
            Icon(Icons.person_search_rounded, size: 58, color: _categoryPurple),
            SizedBox(height: 12),
            Text('Belum ada pelayan pada kategori ini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800)),
          ]),
        ),
      );
}

bool _matches(String category, String value) {
  String normalize(String text) {
    final value = text.toLowerCase().trim();
    if (value.contains('make up') || value.contains('makeup')) {
      return 'makeup';
    }
    if (value.contains('nail care') || value.contains('nail art')) {
      return 'nail art';
    }
    if (value.contains('cukur rambut') || value.contains('barber')) {
      return 'cukur rambut';
    }
    if (value.contains('salon') || value.contains('hair treatment')) {
      return 'salon';
    }
    if (value.contains('facial')) {
      return 'facial';
    }
    return value;
  }

  final a = normalize(category);
  final b = normalize(value);
  return a == b || a.contains(b) || b.contains(a);
}

bool _employeeMatchesCategory(Pelayan employee, String category) {
  final selected = employee.specialty
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty);
  return selected.any((specialty) => _matches(category, specialty));
}

bool _employeeMatchesService(Pelayan employee, Layanan service) {
  final selected = employee.specialty
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty);
  return selected.any(
    (specialty) =>
        _matches(specialty, service.category) ||
        _matches(specialty, service.name),
  );
}
