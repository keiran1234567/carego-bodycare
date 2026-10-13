import 'package:flutter/material.dart';

import '../../data/user_ui_dummy_data.dart';
import '../../utils/app_routes.dart';
import '../../widgets/user_ui_widgets.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  var selectedDay = 2;
  var selectedTime = '14:00';

  @override
  Widget build(BuildContext context) {
    return UserPage(
      children: [
        const CustomHeader(title: 'Pilih Jadwal'),
        const SizedBox(height: 18),
        const _SelectedServiceCard(),
        const SectionTitle(title: '1. Pilih Tanggal'),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(Icons.chevron_left_rounded),
          Text('Mei 2024',
              style: TextStyle(
                  fontWeight: FontWeight.w900, fontSize: 18, color: userInk)),
          Icon(Icons.chevron_right_rounded)
        ]),
        const SizedBox(height: 10),
        SoftCard(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          child: SizedBox(
            height: 106,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 7,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final days = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
                final selected = index == selectedDay;
                return InkWell(
                  onTap: () => setState(() => selectedDay = index),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 66,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? userPrimary : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(days[index],
                            style: TextStyle(
                                color: selected ? Colors.white : userMuted)),
                        const SizedBox(height: 3),
                        Text('${20 + index}',
                            style: TextStyle(
                                fontSize: 22,
                                color: selected ? Colors.white : userInk,
                                fontWeight: FontWeight.w900)),
                        Text('Mei',
                            style: TextStyle(
                                color: selected ? Colors.white : userMuted)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SectionTitle(title: '2. Pilih Waktu'),
        _TimeGroup(
            title: 'Pagi',
            icon: Icons.wb_sunny_rounded,
            times: const ['08:00', '09:00', '10:00', '11:00'],
            selected: selectedTime,
            onTap: (time) => setState(() => selectedTime = time)),
        _TimeGroup(
            title: 'Siang',
            icon: Icons.wb_sunny_outlined,
            times: const ['13:00', '14:00', '15:00', '16:00'],
            selected: selectedTime,
            onTap: (time) => setState(() => selectedTime = time)),
        _TimeGroup(
            title: 'Sore - Malam',
            icon: Icons.nightlight_round,
            times: const ['17:00', '18:00', '19:00', '20:00'],
            selected: selectedTime,
            onTap: (time) => setState(() => selectedTime = time)),
        const SizedBox(height: 12),
        const SoftCard(
            child: Text(
                'Informasi\nJadwal bersifat sementara. Silakan lanjutkan ke konfirmasi booking sebelum waktu habis.',
                style: TextStyle(color: userMuted, height: 1.5))),
        SoftCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ringkasan Pilihan',
                style: TextStyle(
                    color: userPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 18,
              runSpacing: 12,
              children: [
                const _SummaryChip(
                    label: 'Tanggal', value: 'Rabu, 22 Mei 2024'),
                _SummaryChip(label: 'Waktu', value: '$selectedTime WIB'),
                const _SummaryChip(label: 'Terapis', value: 'Sinta Aprilia'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                    onPressed: () => Navigator.pushNamed(
                        context, AppRoutes.userBookingConfirm),
                    style: FilledButton.styleFrom(backgroundColor: userPrimary),
                    child: const Text('Lanjutkan ke Konfirmasi'))),
          ]),
        ),
      ],
    );
  }
}

class _SelectedServiceCard extends StatelessWidget {
  const _SelectedServiceCard();

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 430;
          final image = ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              uiHeroImage,
              width: compact ? 104 : 120,
              height: compact ? 104 : 100,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
            ),
          );
          const details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Facial Basic',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: userInk)),
              SizedBox(height: 8),
              Text('Glow Beauty Home Service',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: userMuted)),
              SizedBox(height: 8),
              Text('Terapis: Sinta Aprilia',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: userMuted)),
              Text('Durasi: 60 Menit', style: TextStyle(color: userMuted)),
            ],
          );

          if (compact) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                image,
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      details,
                      SizedBox(height: 12),
                      Text('Rp120.000',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: userPrimary)),
                    ],
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              image,
              const SizedBox(width: 16),
              const Expanded(child: details),
              const SizedBox(width: 16),
              const Text('Rp120.000',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: userPrimary)),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF0EDFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_month_outlined,
                color: userPrimary, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text('$label\n$value',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: userInk, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _TimeGroup extends StatelessWidget {
  const _TimeGroup(
      {required this.title,
      required this.icon,
      required this.times,
      required this.selected,
      required this.onTap});
  final String title;
  final IconData icon;
  final List<String> times;
  final String selected;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: userPrimary, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, color: userInk))
        ]),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth < 340 ? 2 : 4;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              childAspectRatio: columns == 2 ? 3.4 : 2.4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: times.map((time) {
                final active = time == selected;
                return InkWell(
                  onTap: () => onTap(time),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? userPrimary : Colors.white,
                      border: Border.all(color: userPrimary),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        color: active ? Colors.white : userPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        )
      ]));
}
