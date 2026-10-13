import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/app_store.dart';
import '../models/app_models.dart';
import '../utils/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/bottom_navs.dart';

const _chatPurple = Color(0xFF663CE2);
const _chatPurpleDark = Color(0xFF4B26D9);
const _chatInk = Color(0xFF10143D);
const _chatMuted = Color(0xFF777A9B);
const _chatLine = Color(0xFFE9E4F5);
const _chatSurface = Color(0xFFFCFAFF);

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final controller = TextEditingController();
  final scrollController = ScrollController();
  Timer? poller;
  var sending = false;
  var bootstrapped = false;
  String? requestedId;
  Booking? activeBooking;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (bootstrapped) return;
    bootstrapped = true;
    requestedId = ModalRoute.of(context)?.settings.arguments as String?;
    if (requestedId != null) {
      _openBooking(requestedId!, replace: false);
    }
  }

  @override
  void dispose() {
    poller?.cancel();
    controller.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final conversations = store.bookings
        .where((item) => _chatAllowed(item.status))
        .toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    final compactHeight = MediaQuery.sizeOf(context).height < 700;

    if (activeBooking != null) {
      return _ChatRoom(
        booking: activeBooking!,
        messages: store.chats,
        controller: controller,
        scrollController: scrollController,
        sending: sending,
        onBack: () {
          poller?.cancel();
          setState(() => activeBooking = null);
        },
        onSend: () => _send(activeBooking!.id),
      );
    }

    return Scaffold(
      backgroundColor: _chatSurface,
      bottomNavigationBar: store.currentUser?.role == AppRole.user
          ? const UserBottomNav(currentIndex: 2)
          : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 10),
          child: conversations.isEmpty
              ? ListView(
                  children: [
                    _ChatListHeader(onSearch: () {}),
                    SizedBox(height: compactHeight ? 14 : 20),
                    const _ChatTabs(),
                    SizedBox(height: compactHeight ? 12 : 18),
                    const _ChatTipCard(),
                    SizedBox(height: compactHeight ? 12 : 18),
                    const _EmptyChatState(),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ChatListHeader(onSearch: () {}),
                    SizedBox(height: compactHeight ? 14 : 20),
                    const _ChatTabs(),
                    SizedBox(height: compactHeight ? 12 : 18),
                    const _ChatTipCard(),
                    SizedBox(height: compactHeight ? 12 : 18),
                    Expanded(
                      child: ListView.separated(
                        itemCount: conversations.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: _chatLine),
                        itemBuilder: (_, index) {
                          final booking = conversations[index];
                          return _ConversationTile(
                            booking: booking,
                            selected: index == 0,
                            onTap: () => _openBooking(booking.id),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _openBooking(String bookingId, {bool replace = true}) async {
    final booking = AppStore.instance.bookingById(bookingId);
    setState(() {
      activeBooking = booking;
      if (replace) requestedId = bookingId;
    });
    await _refreshRoom(bookingId);
    poller?.cancel();
    poller = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _refreshRoom(bookingId, jump: false),
    );
  }

  Future<void> _refreshRoom(String bookingId, {bool jump = true}) async {
    try {
      await AppStore.instance.refreshChats(bookingId, silent: true);
      if (!mounted) return;
      setState(() {});
      if (jump) _scrollToBottom();
    } catch (_) {
      // Keep the chat screen usable if one polling request fails.
    }
  }

  Future<void> _send(String bookingId) async {
    final message = controller.text.trim();
    if (message.isEmpty) return;
    final store = AppStore.instance;
    final current = store.currentUser;
    if (current == null) return;
    final booking = store.bookingById(bookingId);
    final receiverId = _receiverUserId(booking, current, store);
    if (receiverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Penerima chat tidak ditemukan.')),
      );
      return;
    }
    setState(() => sending = true);
    try {
      await store.sendChat(
          bookingId: bookingId, receiverId: receiverId, message: message);
      controller.clear();
      if (mounted) {
        setState(() {});
        _scrollToBottom();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }
}

class _ChatListHeader extends StatelessWidget {
  const _ChatListHeader({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chat',
                  style: TextStyle(
                      color: _chatInk,
                      fontSize: 32,
                      fontWeight: FontWeight.w900)),
              SizedBox(height: 8),
              Text('Komunikasi dengan pelanggan & tim',
                  style: TextStyle(color: _chatMuted, fontSize: 14)),
            ],
          ),
        ),
        _RoundIconButton(icon: Icons.search_rounded, onTap: onSearch),
        const SizedBox(width: 10),
        _RoundIconButton(icon: Icons.tune_rounded, onTap: () {}),
      ],
    );
  }
}

class _ChatTabs extends StatelessWidget {
  const _ChatTabs();

  @override
  Widget build(BuildContext context) {
    const tabs = ['Semua', 'Pelanggan', 'Pelayan', 'Tim CareGo'];
    return Container(
      height: 50,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2EFF8),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: i == 0
                      ? const LinearGradient(
                          colors: [_chatPurple, _chatPurpleDark])
                      : null,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  tabs[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: i == 0 ? Colors.white : _chatInk,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChatTipCard extends StatelessWidget {
  const _ChatTipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE1D6FA)),
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE1D6FA)),
            ),
            child: const Icon(Icons.chat_bubble_rounded,
                color: _chatPurple, size: 30),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Respon cepat, pelanggan puas!',
                    style: TextStyle(
                        color: _chatInk,
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
                SizedBox(height: 6),
                Text(
                  'Jangan lupa membalas pesan pelanggan dengan ramah dan profesional.',
                  style: TextStyle(color: _chatMuted, height: 1.4),
                ),
              ],
            ),
          ),
          const Icon(Icons.close_rounded, color: _chatPurple),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.booking,
    required this.selected,
    required this.onTap,
  });

  final Booking booking;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final contact = _contactName(booking, store);
    final service = _serviceFor(booking);
    final employee = _employeeFor(booking.employeeId);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: selected ? _chatPurple : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            _Avatar(name: contact, photoUrl: employee?.photoUrl ?? ''),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _chatInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text('Pesanan: ${service?.name ?? 'Booking CareGo'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: _chatPurple,
                          fontSize: 12,
                          fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(_previewText(booking),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: _chatMuted, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(booking.time.isEmpty ? 'Baru' : booking.time,
                    style: const TextStyle(color: _chatMuted, fontSize: 11)),
                const SizedBox(height: 12),
                if (selected)
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: _chatPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('1',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatRoom extends StatelessWidget {
  const _ChatRoom({
    required this.booking,
    required this.messages,
    required this.controller,
    required this.scrollController,
    required this.sending,
    required this.onBack,
    required this.onSend,
  });

  final Booking booking;
  final List<ChatMessage> messages;
  final TextEditingController controller;
  final ScrollController scrollController;
  final bool sending;
  final VoidCallback onBack;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    final contact = _contactName(booking, store);
    final service = _serviceFor(booking);
    final employee = _employeeFor(booking.employeeId);
    final currentUserId = store.currentUser?.id ?? '';
    return Scaffold(
      backgroundColor: _chatSurface,
      body: SafeArea(
        child: Column(
          children: [
            _RoomHeader(
              contact: contact,
              subtitle: _contactSubtitle(booking, store),
              photoUrl: employee?.photoUrl ?? '',
              onBack: onBack,
            ),
            _BookingSummary(booking: booking, service: service),
            Expanded(
              child: messages.isEmpty
                  ? const _EmptyChatState()
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(22, 16, 22, 22),
                      itemCount: messages.length,
                      itemBuilder: (_, index) {
                        final chat = messages[index];
                        return _MessageBubble(
                          message: chat,
                          mine: chat.senderId == currentUserId,
                        );
                      },
                    ),
            ),
            _MessageComposer(
              controller: controller,
              sending: sending,
              onSend: onSend,
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomHeader extends StatelessWidget {
  const _RoomHeader({
    required this.contact,
    required this.subtitle,
    required this.photoUrl,
    required this.onBack,
  });

  final String contact;
  final String subtitle;
  final String photoUrl;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      color: Colors.white,
      child: Row(
        children: [
          _RoundIconButton(icon: Icons.arrow_back_rounded, onTap: onBack),
          const SizedBox(width: 12),
          _Avatar(name: contact, photoUrl: photoUrl, size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: _chatInk,
                        fontSize: 18,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _chatMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                          color: Color(0xFF21C883), shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 5),
                    const Text('Online',
                        style: TextStyle(color: _chatMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          _RoundIconButton(icon: Icons.phone_rounded, onTap: () {}),
          const SizedBox(width: 8),
          _RoundIconButton(icon: Icons.more_vert_rounded, onTap: () {}),
        ],
      ),
    );
  }
}

class _BookingSummary extends StatelessWidget {
  const _BookingSummary({required this.booking, required this.service});

  final Booking booking;
  final Layanan? service;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(22, 18, 22, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              _serviceImage(service),
              width: 78,
              height: 78,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(service?.name ?? 'Booking CareGo',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: _chatInk,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EDFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(booking.status,
                          style: const TextStyle(
                              color: _chatPurple,
                              fontSize: 11,
                              fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${booking.date} • ${booking.time}',
                    style: const TextStyle(color: _chatMuted, fontSize: 12)),
                const SizedBox(height: 6),
                Text(AppFormatters.currency(booking.total),
                    style: const TextStyle(
                        color: _chatPurple,
                        fontSize: 14,
                        fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _chatPurple),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.mine});

  final ChatMessage message;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .72),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 9),
        decoration: BoxDecoration(
          color: mine ? _chatPurple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 6),
            bottomRight: Radius.circular(mine ? 6 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(message.message,
                style: TextStyle(
                    color: mine ? Colors.white : _chatInk,
                    height: 1.38,
                    fontSize: 15)),
            const SizedBox(height: 6),
            Text(_messageTime(message.createdAt),
                style: TextStyle(
                    color:
                        mine ? Colors.white.withValues(alpha: .8) : _chatMuted,
                    fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .04),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Row(
        children: [
          _CircleAction(icon: Icons.add_rounded, onTap: () {}),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ketik pesan...',
                hintStyle: const TextStyle(color: _chatMuted),
                filled: true,
                fillColor: Colors.white,
                suffixIcon: const Icon(Icons.sentiment_satisfied_alt_rounded,
                    color: _chatMuted),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: _chatLine),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: _chatLine),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(999),
                  borderSide: const BorderSide(color: _chatPurple),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _CircleAction(
            icon: sending ? Icons.hourglass_top_rounded : Icons.send_rounded,
            onTap: sending ? null : onSend,
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.photoUrl, this.size = 58});

  final String name;
  final String photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: const Color(0xFFEDE7FF),
          backgroundImage: photoUrl.isEmpty ? null : NetworkImage(photoUrl),
          child: photoUrl.isEmpty
              ? Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                  style: const TextStyle(
                      color: _chatPurple, fontWeight: FontWeight.w900))
              : null,
        ),
        Positioned(
          right: 1,
          bottom: 2,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: const Color(0xFF21C883),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 52,
        height: 52,
        decoration: const BoxDecoration(
          color: Color(0xFFF3EEFC),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _chatPurple),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [_chatPurple, _chatPurpleDark]),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded,
                color: _chatPurple, size: 54),
            const SizedBox(height: 12),
            const Text('Belum ada chat aktif',
                style: TextStyle(
                    color: _chatInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Text(
              'Chat aktif setelah status Pelayan Ditugaskan.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted.withValues(alpha: .9)),
            ),
          ],
        ),
      ),
    );
  }
}

String _receiverUserId(Booking booking, User current, AppStore store) {
  if (current.role == AppRole.user) {
    return _employeeFor(booking.employeeId)?.userId ?? '';
  }
  if (current.role == AppRole.pelayan) {
    return booking.userId;
  }
  return booking.userId;
}

String _contactName(Booking booking, AppStore store) {
  final role = store.currentUser?.role;
  if (role == AppRole.user) {
    return _employeeFor(booking.employeeId)?.name ?? 'Pelayan CareGo';
  }
  return booking.userName.isEmpty ? 'Pelanggan CareGo' : booking.userName;
}

String _contactSubtitle(Booking booking, AppStore store) {
  final role = store.currentUser?.role;
  if (role == AppRole.user) return 'Pelayan';
  return 'Pelanggan';
}

String _previewText(Booking booking) {
  if (booking.status == 'Selesai') {
    return 'Pesanan selesai. Chat tetap tersimpan.';
  }
  return 'Ketuk untuk membuka percakapan booking ini.';
}

String _messageTime(String value) {
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return '';
  return '${parsed.hour.toString().padLeft(2, '0')}.${parsed.minute.toString().padLeft(2, '0')}';
}

Layanan? _serviceFor(Booking booking) {
  return AppStore.instance.layanans
      .where((item) => item.id == booking.serviceId)
      .firstOrNull;
}

Pelayan? _employeeFor(String id) {
  return AppStore.instance.pelayans.where((item) => item.id == id).firstOrNull;
}

String _serviceImage(Layanan? service) {
  final value =
      '${service?.name ?? ''} ${service?.category ?? ''}'.toLowerCase();
  if (value.contains('nail')) return 'assets/images/service_nail_care.png';
  if (value.contains('hair') || value.contains('rambut')) {
    return 'assets/images/service_premium_haircut.png';
  }
  return 'assets/images/service_facial_glow.png';
}

bool _chatAllowed(String status) => const {
      'Dikirim ke Pelayan',
      'Diterima Pelayan',
      'Pelayan Menuju Lokasi',
      'Sedang Dikerjakan',
      'Selesai',
    }.contains(status);
