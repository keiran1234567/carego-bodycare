import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';
import 'api_client.dart';

class AppStore extends ChangeNotifier {
  AppStore._();

  static final AppStore instance = AppStore._();
  static const _roleKey = 'bodycare_last_role';
  static const _tokenKey = 'carego_api_token';
  static const _userKey = 'carego_api_user';

  final api = ApiClient.instance;

  List<Booking> _bookings = [];
  List<Mitra> _mitras = [];
  List<Pelayan> _pelayans = [];
  List<Layanan> _layanans = [];
  List<User> _users = [];
  List<Review> _reviews = [];
  List<Riwayat> _histories = [];
  List<Pembayaran> _payments = [];
  List<AppNotification> _notifications = [];
  Map<String, dynamic> _dashboard = {};
  Map<String, dynamic> _income = {};
  List<ChatMessage> _chats = [];
  List<Map<String, dynamic>> _vouchers = [];
  List<Map<String, dynamic>> _voucherHistory = [];
  List<Map<String, dynamic>> _addresses = [];
  List<Map<String, dynamic>> _favorites = [];
  Map<String, dynamic> _wallet = {};
  AppRole? _lastRole;
  User? _currentUser;
  bool _loading = false;
  String? _error;
  bool _online = false;
  bool _initialized = false;

  List<Booking> get bookings => List.unmodifiable(_bookings);
  List<Mitra> get mitras => List.unmodifiable(_mitras);
  List<Pelayan> get pelayans => List.unmodifiable(_pelayans);
  List<Layanan> get layanans => List.unmodifiable(_layanans);
  List<User> get users => List.unmodifiable(_users);
  List<Review> get reviews => List.unmodifiable(_reviews);
  List<Riwayat> get histories => List.unmodifiable(_histories);
  List<Pembayaran> get payments => List.unmodifiable(_payments);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  Map<String, dynamic> get dashboard => Map.unmodifiable(_dashboard);
  Map<String, dynamic> get income => Map.unmodifiable(_income);
  List<ChatMessage> get chats => List.unmodifiable(_chats);
  List<Map<String, dynamic>> get vouchers => List.unmodifiable(_vouchers);
  List<Map<String, dynamic>> get voucherHistory =>
      List.unmodifiable(_voucherHistory);
  List<Map<String, dynamic>> get addresses => List.unmodifiable(_addresses);
  List<Map<String, dynamic>> get favorites => List.unmodifiable(_favorites);
  Map<String, dynamic> get wallet => Map.unmodifiable(_wallet);
  AppRole? get lastRole => _lastRole;
  User? get currentUser => _currentUser;
  bool get isAuthenticated => api.token != null;
  bool get loading => _loading;
  bool get online => _online;
  bool get initialized => _initialized;
  String? get error => _error;
  String get apiBaseUrl => ApiClient.baseUrl;

  Future<void> initialize({bool force = false}) async {
    if (_initialized && !force) return;
    _initialized = false;
    _error = null;
    try {
      await api.initialize();
      final prefs = await SharedPreferences.getInstance();
      api.token = prefs.getString(_tokenKey);
      final savedUser = prefs.getString(_userKey);
      if (savedUser != null) {
        _currentUser =
            _userFromApi(jsonDecode(savedUser) as Map<String, dynamic>);
      }
      final savedRole = prefs.getString(_roleKey);
      if (savedRole != null) _lastRole = roleFromJson(savedRole);
      await (() async {
        await refreshCatalog(silent: true);
        if (isAuthenticated) {
          await refreshSession(silent: true, refreshData: false);
        }
      })()
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      _online = false;
      _error = 'Koneksi backend terlalu lama. Periksa server dan Wi-Fi.';
    } on ApiException catch (error) {
      if (_isUnauthenticated(error)) {
        await _clearPersistedSession();
        _error = 'Sesi login sudah berakhir. Silakan masuk lagi.';
      } else {
        _error = error.message;
      }
      _online = false;
    } catch (_) {
      _online = false;
      _error = 'Aplikasi gagal memuat data awal.';
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<void> login({
    required String email,
    required String password,
    AppRole? expectedRole,
  }) async {
    await _run(() async {
      final payload = {
        'email': email,
        'password': password,
        if (expectedRole != null) 'role': expectedRole.name.toUpperCase(),
      };
      final data = Map<String, dynamic>.from(
        await api.post('/auth/login', payload) as Map,
      );
      final userData = Map<String, dynamic>.from(data['user'] as Map);
      final user = _userFromApi(userData);
      if (expectedRole != null && user.role != expectedRole) {
        throw ApiException(
          'Akun ini terdaftar sebagai ${user.role.label}, bukan ${expectedRole.label}.',
        );
      }
      api.token = data['token'] as String;
      _currentUser = user;
      _clearRoleScopedData();
      await setLastRole(user.role);
      await _persistSession(userData);
      await refreshAll(silent: true);
    });
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required AppRole role,
    String? businessName,
    String? address,
    String? description,
    String? ktpImageBase64,
    String? logoImageBase64,
    String? mitraId,
    String? specialization,
  }) async {
    await _run(() async {
      final data = Map<String, dynamic>.from(await api.post('/auth/register', {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': password,
        'role': role.name.toUpperCase(),
        if (businessName != null) 'business_name': businessName,
        if (address != null) 'address': address,
        if (description != null) 'description': description,
        if (ktpImageBase64 != null) 'ktp_image_base64': ktpImageBase64,
        if (logoImageBase64 != null) 'logo_image_base64': logoImageBase64,
        if (mitraId != null) 'mitra_id': int.tryParse(mitraId),
        if (specialization != null) 'specialization': specialization,
      }) as Map);
      final userData = Map<String, dynamic>.from(data['user'] as Map);
      api.token = data['token'] as String;
      _currentUser = _userFromApi(userData);
      await setLastRole(role);
      await _persistSession(userData);
      await refreshAll(silent: true);
    });
  }

  Future<void> logout() async {
    try {
      if (api.token != null) await api.post('/auth/logout');
    } finally {
      api.token = null;
      _currentUser = null;
      _clearRoleScopedData();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      notifyListeners();
    }
  }

  Future<void> refreshSession({
    bool silent = false,
    bool refreshData = true,
  }) async {
    await _run(() async {
      final data = Map<String, dynamic>.from(await api.get('/auth/me') as Map);
      _currentUser = _userFromApi(data);
      await _persistSession(data);
      if (refreshData) await refreshAll(silent: true);
    }, silent: silent);
  }

  Future<void> refreshAll({bool silent = false}) async {
    await refreshCatalog(silent: true);
    if (isAuthenticated) {
      await refreshBookings(silent: true);
      await refreshInteractions(silent: true);
      await refreshDashboard(silent: true);
      if (_currentUser?.role == AppRole.mitra ||
          _currentUser?.role == AppRole.pelayan) {
        await refreshIncome(silent: true);
      }
      if (_currentUser?.role == AppRole.user) {
        await refreshWallet(silent: true);
      }
      if (_currentUser?.role == AppRole.admin) {
        await refreshUsers(silent: true);
        await refreshAdminVouchers(silent: true);
        await refreshAdminPayments(silent: true);
      }
    }
    if (!silent) notifyListeners();
  }

  Future<void> refreshDashboard({bool silent = false}) async {
    await _run(() async {
      _dashboard =
          Map<String, dynamic>.from(await api.get('/dashboard') as Map);
    }, silent: silent);
  }

  Future<void> refreshIncome({bool silent = false}) async {
    await _run(() async {
      _income = Map<String, dynamic>.from(await api.get('/income') as Map);
    }, silent: silent);
  }

  Future<void> refreshWallet({bool silent = false}) async {
    await _run(() async {
      _wallet = Map<String, dynamic>.from(await api.get('/wallet') as Map);
    }, silent: silent);
  }

  Mitra? get currentMitra {
    final user = _currentUser;
    if (user == null) return null;
    final index = _mitras.indexWhere((item) => item.userId == user.id);
    return index < 0 ? null : _mitras[index];
  }

  Pelayan? get currentPelayan {
    final user = _currentUser;
    if (user == null) return null;
    if (user.role != AppRole.pelayan) return null;
    var index = _pelayans.indexWhere((item) => item.userId == user.id);
    if (index < 0) {
      index = _pelayans.indexWhere(
        (item) => item.email.toLowerCase() == user.email.toLowerCase(),
      );
    }
    return index < 0 ? null : _pelayans[index];
  }

  Future<void> createPelayan({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String specialization,
    int experienceYears = 0,
    bool silent = false,
    String? mitraId,
  }) async {
    await _run(() async {
      await api.post('/pelayans', {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'specialization': specialization,
        'experience_years': experienceYears,
        if (mitraId != null) 'mitra_id': int.parse(mitraId),
      });
      await refreshCatalog(silent: true);
    }, silent: silent);
  }

  Future<void> updateAdminPelayan(
    String id, {
    required String mitraId,
    required String name,
    required String email,
    required String phone,
    String? password,
    required String specialization,
    required int experienceYears,
    required bool available,
  }) async {
    await _run(() async {
      await api.patch('/pelayans/$id', {
        'mitra_id': int.parse(mitraId),
        'name': name,
        'email': email,
        'phone': phone,
        if (password != null && password.isNotEmpty) 'password': password,
        'specialization': specialization,
        'experience_years': experienceYears,
        'is_available': available,
      });
      await refreshCatalog(silent: true);
      await refreshUsers(silent: true);
    });
  }

  Future<void> updatePelayanAvailability(String id, bool available) async {
    await _run(() async {
      await api.patch('/pelayans/$id', {'is_available': available});
      await refreshCatalog(silent: true);
    });
  }

  Future<void> deletePelayan(String id) async {
    await _run(() async {
      await api.delete('/pelayans/$id');
      await refreshCatalog(silent: true);
    });
  }

  Future<void> createLayanan({
    required String name,
    required String category,
    required String description,
    required int price,
    required int durationMinutes,
    String? mitraId,
  }) async {
    await _run(() async {
      await api.post('/layanans', {
        'name': name,
        'category': category,
        'description': description,
        'price': price,
        'duration_minutes': durationMinutes,
        if (mitraId != null) 'mitra_id': int.parse(mitraId),
      });
      await refreshCatalog(silent: true);
    });
  }

  Future<void> updateLayanan(
    String id, {
    String? mitraId,
    String? name,
    String? category,
    String? description,
    int? price,
    int? durationMinutes,
    bool? active,
  }) async {
    await _run(() async {
      await api.patch('/layanans/$id', {
        if (mitraId != null) 'mitra_id': int.parse(mitraId),
        if (name != null) 'name': name,
        if (category != null) 'category': category,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (durationMinutes != null) 'duration_minutes': durationMinutes,
        if (active != null) 'is_active': active,
      });
      await refreshCatalog(silent: true);
    });
  }

  Future<void> deleteLayanan(String id) async {
    await _run(() async {
      await api.delete('/layanans/$id');
      await refreshCatalog(silent: true);
    });
  }

  Future<void> createAdminBooking({
    required String userId,
    required String mitraId,
    required String pelayanId,
    required String layananId,
    required DateTime scheduledAt,
    required String address,
    required double distanceKm,
    String notes = '',
  }) async {
    await _run(() async {
      await api.post('/admin/bookings', {
        'user_id': int.parse(userId),
        'mitra_id': int.parse(mitraId),
        'pelayan_id': int.parse(pelayanId),
        'layanan_id': int.parse(layananId),
        'scheduled_at': scheduledAt.toIso8601String(),
        'service_address': address,
        'travel_distance_km': distanceKm,
        'notes': notes,
      });
      await refreshBookings(silent: true);
    });
  }

  Future<void> deleteAdminBooking(String id) async {
    await _run(() async {
      await api.delete('/admin/bookings/$id');
      await refreshBookings(silent: true);
      await refreshDashboard(silent: true);
    });
  }

  Future<void> createAdminPayment({
    required String bookingId,
    required String method,
    required String status,
    int? amount,
  }) async {
    await _run(() async {
      await api.post('/admin/payments', {
        'id_booking': int.parse(bookingId),
        'metode_pembayaran': method,
        'status_pembayaran': status,
        if (amount != null) 'total_bayar': amount,
      });
      await refreshAdminPayments(silent: true);
      await refreshBookings(silent: true);
      await refreshDashboard(silent: true);
    });
  }

  Future<void> updateAdminPayment(
    String id, {
    required String bookingId,
    required String method,
    required String status,
    int? amount,
  }) async {
    await _run(() async {
      await api.patch('/admin/payments/$id', {
        'id_booking': int.parse(bookingId),
        'metode_pembayaran': method,
        'status_pembayaran': status,
        if (amount != null) 'total_bayar': amount,
      });
      await refreshAdminPayments(silent: true);
      await refreshBookings(silent: true);
      await refreshDashboard(silent: true);
    });
  }

  Future<void> deleteAdminPayment(String id) async {
    await _run(() async {
      await api.delete('/admin/payments/$id');
      await refreshAdminPayments(silent: true);
      await refreshBookings(silent: true);
      await refreshDashboard(silent: true);
    });
  }

  Future<void> refreshUsers({bool silent = false}) async {
    await _run(() async {
      final page =
          Map<String, dynamic>.from(await api.get('/admin/users') as Map);
      _users = (page['data'] as List)
          .map((e) => _userFromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
    }, silent: silent);
  }

  Future<void> createAdminUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    AppRole role = AppRole.user,
    String status = 'ACTIVE',
  }) async {
    await _run(() async {
      await api.post('/admin/users', {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'role': role.name.toUpperCase(),
        'status': status,
      });
      await refreshUsers(silent: true);
    });
  }

  Future<void> updateAdminUser(
    String id, {
    required String name,
    required String email,
    required String phone,
    String? password,
    AppRole role = AppRole.user,
    String status = 'ACTIVE',
  }) async {
    await _run(() async {
      await api.patch('/admin/users/$id', {
        'name': name,
        'email': email,
        'phone': phone,
        if (password != null && password.isNotEmpty) 'password': password,
        'role': role.name.toUpperCase(),
        'status': status,
      });
      await refreshUsers(silent: true);
    });
  }

  Future<void> deleteAdminUser(String id) async {
    await _run(() async {
      await api.delete('/admin/users/$id');
      await refreshUsers(silent: true);
    });
  }

  Future<void> refreshAdminVouchers({bool silent = false}) async {
    await _run(() async {
      final page =
          Map<String, dynamic>.from(await api.get('/admin/vouchers') as Map);
      _vouchers = (page['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }, silent: silent);
  }

  Future<void> refreshAdminPayments({bool silent = false}) async {
    await _run(() async {
      final page =
          Map<String, dynamic>.from(await api.get('/admin/payments') as Map);
      _payments = (page['data'] as List)
          .map((e) => _paymentFromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
    }, silent: silent);
  }

  Future<void> createAdminMitra({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String address,
    required String description,
    bool verified = true,
  }) async {
    await _run(() async {
      await api.post('/mitras', {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'address': address,
        'description': description,
        'is_verified': verified,
      });
      await refreshCatalog(silent: true);
      await refreshUsers(silent: true);
    });
  }

  Future<void> updateAdminMitra(
    String id, {
    required String name,
    required String email,
    required String phone,
    String? password,
    required String address,
    required String description,
    bool verified = true,
  }) async {
    await _run(() async {
      await api.patch('/mitras/$id', {
        'name': name,
        'email': email,
        'phone': phone,
        if (password != null && password.isNotEmpty) 'password': password,
        'address': address,
        'description': description,
        'is_verified': verified,
      });
      await refreshCatalog(silent: true);
      await refreshUsers(silent: true);
    });
  }

  Future<void> approveMitra(String id) async {
    await _run(() async {
      await api.post('/mitras/$id/approve');
      await refreshCatalog(silent: true);
      await refreshUsers(silent: true);
    });
  }

  Future<void> rejectMitra(String id, String reason) async {
    await _run(() async {
      await api.post('/mitras/$id/reject', {'reason': reason});
      await refreshCatalog(silent: true);
      await refreshUsers(silent: true);
    });
  }

  Future<void> deleteAdminMitra(String id) async {
    await _run(() async {
      await api.delete('/mitras/$id');
      await refreshCatalog(silent: true);
      await refreshUsers(silent: true);
    });
  }

  Future<void> refreshInteractions({bool silent = false}) async {
    await _run(() async {
      final results = await Future.wait([
        api.get('/reviews'),
        api.get('/notifications'),
        api.get('/vouchers'),
        api.get('/voucher-history'),
        api.get('/addresses'),
        api.get('/favorites'),
      ]);
      final reviewPage = Map<String, dynamic>.from(results[0] as Map);
      final notificationPage = Map<String, dynamic>.from(results[1] as Map);
      _reviews = (reviewPage['data'] as List)
          .map((e) => _reviewFromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
      _vouchers = (results[2] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _voucherHistory = (results[3] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _addresses = (results[4] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _favorites = (results[5] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _notifications = (notificationPage['data'] as List)
          .map((e) => _notificationFromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
    }, silent: silent);
  }

  Future<void> refreshCatalog({bool silent = false}) async {
    await _run(() async {
      final pages = await Future.wait([
        api.get('/mitras'),
        api.get('/layanans'),
        api.get('/pelayans'),
      ]);
      final mitraPage = Map<String, dynamic>.from(pages[0] as Map);
      final layananPage = Map<String, dynamic>.from(pages[1] as Map);
      final pelayanPage = Map<String, dynamic>.from(pages[2] as Map);
      _mitras = (mitraPage['data'] as List)
          .map((e) => _mitraFromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
      _layanans = (layananPage['data'] as List)
          .map((e) => _layananFromApi(Map<String, dynamic>.from(e as Map)))
          .where((service) =>
              !_isRemovedCareService(service.name, service.category))
          .toList();
      _pelayans = (pelayanPage['data'] as List)
          .map((e) => _pelayanFromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
      _online = true;
      _error = null;
    }, silent: silent);
  }

  Future<void> refreshBookings({bool silent = false}) async {
    await _run(() async {
      final page = Map<String, dynamic>.from(await api.get('/bookings') as Map);
      _bookings = (page['data'] as List)
          .map((e) => _bookingFromApi(Map<String, dynamic>.from(e as Map)))
          .toList();
      _histories = (page['data'] as List).expand((e) {
        final booking = Map<String, dynamic>.from(e as Map);
        return ((booking['riwayats'] as List?) ?? []).map(
          (history) => _historyFromApi(
            Map<String, dynamic>.from(history as Map),
          ),
        );
      }).toList();
      _payments = (page['data'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((booking) => booking['pembayaran'] is Map)
          .map((booking) => _paymentFromApi(
                Map<String, dynamic>.from(booking['pembayaran'] as Map),
              ))
          .toList();
    }, silent: silent);
  }

  Future<Booking> createBooking({
    required String mitraId,
    required String pelayanId,
    required String layananId,
    required DateTime scheduledAt,
    required String address,
    String? notes,
    String? voucherCode,
  }) async {
    late Booking booking;
    await _run(() async {
      final data = Map<String, dynamic>.from(await api.post('/bookings', {
        'mitra_id': int.parse(mitraId),
        'pelayan_id': int.parse(pelayanId),
        'layanan_id': int.parse(layananId),
        'scheduled_at': scheduledAt.toIso8601String(),
        'service_address': address,
        'notes': notes,
        if (voucherCode != null && voucherCode.isNotEmpty)
          'voucher_code': voucherCode,
      }) as Map);
      booking = _bookingFromApi(data);
      _bookings.insert(0, booking);
    });
    return booking;
  }

  Future<void> updateProfile(
      {required String name,
      required String phone,
      required String address}) async {
    await _run(() async {
      final data = Map<String, dynamic>.from(await api.patch(
              '/profile', {'name': name, 'phone': phone, 'address': address})
          as Map);
      _currentUser = _userFromApi(data);
      await _persistSession(data);
    });
  }

  Future<void> addAddress(
      {required String label,
      required String address,
      required double latitude,
      required double longitude,
      bool primary = false}) async {
    await _run(() async {
      await api.post('/addresses', {
        'label': label,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        'is_primary': primary
      });
      await refreshInteractions(silent: true);
    });
  }

  Future<void> addFavorite({String? layananId, String? mitraId}) async {
    await _run(() async {
      await api.post('/favorites', {
        if (layananId != null) 'layanan_id': int.parse(layananId),
        if (mitraId != null) 'mitra_id': int.parse(mitraId)
      });
      await refreshInteractions(silent: true);
    });
  }

  Future<void> toggleServiceFavorite(String layananId) async {
    final matches = _favorites.where(
      (item) =>
          '${(item['layanan'] as Map?)?['id'] ?? item['layanan_id']}' ==
          layananId,
    );
    await _run(() async {
      if (matches.isEmpty) {
        await api.post('/favorites', {'layanan_id': int.parse(layananId)});
      } else {
        await api.delete('/favorites/${matches.first['id']}');
      }
      await refreshInteractions(silent: true);
    });
  }

  bool isServiceFavorite(String layananId) => _favorites.any(
        (item) =>
            '${(item['layanan'] as Map?)?['id'] ?? item['layanan_id']}' ==
            layananId,
      );

  Future<void> uploadProfilePhoto(String base64Image) async {
    await _run(() async {
      final data = Map<String, dynamic>.from(await api
          .post('/profile/photo', {'image_base64': base64Image}) as Map);
      _currentUser = _userFromApi(data);
      await _persistSession(data);
      await refreshCatalog(silent: true);
    });
  }

  Future<void> uploadPortfolio({
    required String title,
    required String base64Image,
    String? description,
  }) async {
    await _run(() async {
      await api.post('/portofolios/upload', {
        'title': title,
        'description': description,
        'image_base64': base64Image,
      });
      await refreshCatalog(silent: true);
    });
  }

  Future<void> deletePortfolio(String id) async {
    await _run(() async {
      await api.delete('/portofolios/$id');
      await refreshCatalog(silent: true);
    });
  }

  Future<void> createVoucher({
    required String code,
    required String name,
    required String discountType,
    required int discountValue,
    required int minTransaction,
    int? maxDiscount,
    int? quota,
    String? description,
    DateTime? startsAt,
    DateTime? expiresAt,
    bool active = true,
  }) async {
    await _run(() async {
      await api.post('/admin/vouchers', {
        'code': code,
        'name': name,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_transaction': minTransaction,
        'max_discount': maxDiscount,
        'quota': quota,
        'description': description,
        'starts_at': startsAt?.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'is_active': active,
      });
      await refreshAdminVouchers(silent: true);
    });
  }

  Future<void> updateVoucher(
    String id, {
    required String code,
    required String name,
    required String discountType,
    required int discountValue,
    required int minTransaction,
    int? maxDiscount,
    int? quota,
    String? description,
    DateTime? startsAt,
    DateTime? expiresAt,
    bool active = true,
  }) async {
    await _run(() async {
      await api.patch('/admin/vouchers/$id', {
        'code': code,
        'name': name,
        'discount_type': discountType,
        'discount_value': discountValue,
        'min_transaction': minTransaction,
        'max_discount': maxDiscount,
        'quota': quota,
        'description': description,
        'starts_at': startsAt?.toIso8601String(),
        'expires_at': expiresAt?.toIso8601String(),
        'is_active': active,
      });
      await refreshAdminVouchers(silent: true);
    });
  }

  Future<void> deleteVoucher(String id) async {
    await _run(() async {
      await api.delete('/admin/vouchers/$id');
      await refreshAdminVouchers(silent: true);
    });
  }

  Future<Map<String, dynamic>> createPayment(String bookingId) async {
    final payment = Map<String, dynamic>.from(
      await api.post('/bookings/$bookingId/payment') as Map,
    );
    await refreshBookings(silent: true);
    notifyListeners();
    return payment;
  }

  Future<bool> syncPayment(String bookingId) async {
    final payment = Map<String, dynamic>.from(
      await api.post('/bookings/$bookingId/payment/status') as Map,
    );
    await refreshBookings(silent: true);
    notifyListeners();
    return payment['status_pembayaran'] == 'PAID';
  }

  Future<void> submitReview(
    String bookingId,
    int rating,
    String review, {
    int? mitraRating,
    int? pelayanRating,
    List<String> photoUrls = const [],
  }) async {
    await _run(() async {
      await api.post('/reviews', {
        'booking_id': int.parse(bookingId),
        'rating': rating,
        'mitra_rating': mitraRating,
        'pelayan_rating': pelayanRating,
        'review': review,
        if (photoUrls.isNotEmpty) 'photo_urls': photoUrls,
      });
    });
  }

  Future<void> refreshChats(String bookingId, {bool silent = false}) async {
    await _run(() async {
      final page = Map<String, dynamic>.from(
        await api.get('/bookings/$bookingId/chats') as Map,
      );
      _chats = (page['data'] as List)
          .map((e) => _chatFromApi(Map<String, dynamic>.from(e as Map)))
          .toList()
          .reversed
          .toList();
    }, silent: silent);
  }

  Future<void> sendChat({
    required String bookingId,
    required String receiverId,
    required String message,
  }) async {
    await _run(() async {
      await api.post('/chats', {
        'booking_id': int.parse(bookingId),
        'receiver_id': int.parse(receiverId),
        'message': message,
      });
      await refreshChats(bookingId, silent: true);
    });
  }

  Future<void> cancelBooking(String bookingId) async {
    await _run(() async {
      await api.delete('/bookings/$bookingId');
      await refreshBookings(silent: true);
    });
  }

  Booking bookingById(String id) =>
      _bookings.firstWhere((booking) => booking.id == id);

  Future<void> updateBookingStatus(String id, String status) async {
    final apiStatus = _statusToApi(status);
    if (isAuthenticated) {
      await _run(() async {
        final data = Map<String, dynamic>.from(
          await api.patch('/bookings/$id/status', {'status': apiStatus}) as Map,
        );
        final booking = _bookingFromApi(data);
        final index = _bookings.indexWhere((item) => item.id == id);
        if (index >= 0) _bookings[index] = booking;
      });
      return;
    }
    final index = _bookings.indexWhere((booking) => booking.id == id);
    if (index < 0) return;
    _bookings[index] = _bookings[index].copyWith(status: status);
    notifyListeners();
  }

  Future<void> setLastRole(AppRole role) async {
    _lastRole = role;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roleKey, role.name);
  }

  Future<void> resetPrototypeData() => refreshAll();

  Future<void> updateApiBaseUrl(String value) async {
    final previousUrl = apiBaseUrl;
    await api.saveBaseUrl(value);
    try {
      await refreshCatalog(silent: true);
      if (isAuthenticated) {
        await refreshSession(silent: true);
      }
      notifyListeners();
    } catch (_) {
      await api.saveBaseUrl(previousUrl);
      rethrow;
    }
  }

  void _clearRoleScopedData() {
    _bookings = [];
    _reviews = [];
    _histories = [];
    _payments = [];
    _notifications = [];
    _dashboard = {};
    _income = {};
    _chats = [];
    _vouchers = [];
    _voucherHistory = [];
    _addresses = [];
    _favorites = [];
    _wallet = {};
  }

  Future<void> _run(Future<void> Function() operation,
      {bool silent = false}) async {
    if (!silent) {
      _loading = true;
      _error = null;
      notifyListeners();
    }
    try {
      await operation();
    } on ApiException catch (e) {
      if (_isUnauthenticated(e)) {
        await _clearPersistedSession();
        _error = 'Sesi login sudah berakhir. Silakan masuk lagi.';
      } else {
        _error = e.message;
      }
      rethrow;
    } finally {
      if (!silent) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _persistSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, api.token!);
    await prefs.setString(_userKey, jsonEncode(user));
  }

  bool _isUnauthenticated(ApiException error) =>
      error.message.toLowerCase().contains('unauthenticated');

  Future<void> _clearPersistedSession() async {
    api.token = null;
    _currentUser = null;
    _clearRoleScopedData();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  User _userFromApi(Map<String, dynamic> json) => User(
        id: '${json['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        email: '${json['email'] ?? ''}',
        phone: '${json['phone'] ?? ''}',
        role: roleFromJson('${json['role'] ?? 'USER'}'.toLowerCase()),
        address: '${json['address'] ?? ''}',
        photoUrl: _mediaUrl('${json['photo_url'] ?? ''}'),
        status: '${json['status'] ?? 'ACTIVE'}',
      );

  Mitra _mitraFromApi(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map? ?? {});
    return Mitra(
      id: '${json['id']}',
      userId: '${json['user_id']}',
      name: '${json['name'] ?? ''}',
      email: '${user['email'] ?? ''}',
      phone: '${user['phone'] ?? ''}',
      address: '${json['address'] ?? ''}',
      rating: double.tryParse('${json['rating']}') ?? 0,
      distance: '2.4 km',
      description: '${json['description'] ?? ''}',
      serviceIds: ((json['layanans'] as List?) ?? [])
          .map((e) => '${(e as Map)['id']}')
          .toList(),
      employeeIds: ((json['pelayans'] as List?) ?? [])
          .map((e) => '${(e as Map)['id']}')
          .toList(),
      isOpen: '${json['verification_status'] ?? 'approved'}' == 'approved',
      ownerName: '${json['owner_name'] ?? user['name'] ?? ''}',
      logoUrl: _mediaUrl('${json['logo_url'] ?? ''}'),
      ktpUrl: _mediaUrl('${json['ktp_url'] ?? ''}'),
      verificationStatus: '${json['verification_status'] ?? 'approved'}',
      rejectionReason: '${json['rejection_reason'] ?? ''}',
    );
  }

  Pelayan _pelayanFromApi(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map? ?? {});
    return Pelayan(
      id: '${json['id']}',
      userId: '${json['user_id'] ?? user['id'] ?? ''}',
      mitraId: '${json['mitra_id']}',
      name: '${user['name'] ?? ''}',
      email: '${user['email'] ?? ''}',
      phone: '${user['phone'] ?? ''}',
      specialty: '${json['specialization'] ?? ''}',
      rating: double.tryParse('${json['rating']}') ?? 0,
      available: json['is_available'] as bool? ?? true,
      photoUrl: _mediaUrl('${user['photo_url'] ?? ''}'),
      portfolioItems: ((json['portofolios'] as List?) ?? [])
          .map((e) => Portofolio(
                id: '${(e as Map)['id']}',
                pelayanId: '${e['pelayan_id']}',
                title: '${e['title'] ?? ''}',
                description: '${e['description'] ?? ''}',
                imageUrl: _mediaUrl('${e['image_url'] ?? ''}'),
                createdAt: '${e['created_at'] ?? ''}',
              ))
          .toList(),
      bio: '${json['bio'] ?? ''}',
      experienceYears: int.tryParse('${json['experience_years'] ?? 0}') ?? 0,
      reviewItems: ((json['reviews'] as List?) ?? [])
          .map((item) => _reviewFromApi(Map<String, dynamic>.from(item as Map)))
          .toList(),
      serviceIds: (((json['mitra'] as Map?)?['layanans'] as List?) ?? [])
          .map((item) => '${(item as Map)['id']}')
          .toList(),
      busySchedules: ((json['bookings'] as List?) ?? [])
          .map((item) => DateTime.tryParse('${(item as Map)['scheduled_at']}'))
          .whereType<DateTime>()
          .toList(),
    );
  }

  Layanan _layananFromApi(Map<String, dynamic> json) => Layanan(
        id: '${json['id']}',
        mitraId: '${json['mitra_id'] ?? (json['mitra'] as Map?)?['id'] ?? ''}',
        name: '${json['name'] ?? ''}',
        category: '${json['category'] ?? ''}',
        duration: '${json['duration_minutes'] ?? 0} menit',
        price: double.tryParse('${json['price']}')?.round() ?? 0,
        icon: _categoryIcon('${json['category'] ?? ''}'),
        description: '${json['description'] ?? ''}',
        active: json['is_active'] as bool? ?? true,
      );

  Booking _bookingFromApi(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map? ?? {});
    final payment = Map<String, dynamic>.from(json['pembayaran'] as Map? ?? {});
    final parsedSchedule = DateTime.tryParse('${json['scheduled_at']}');
    final scheduled = parsedSchedule?.toLocal();
    return Booking(
      id: '${json['id']}',
      userId: '${json['user_id'] ?? user['id'] ?? ''}',
      userName: '${user['name'] ?? ''}',
      partnerId: '${json['mitra_id'] ?? (json['mitra'] as Map?)?['id'] ?? ''}',
      employeeId:
          '${json['pelayan_id'] ?? (json['pelayan'] as Map?)?['id'] ?? ''}',
      serviceId:
          '${json['layanan_id'] ?? (json['layanan'] as Map?)?['id'] ?? ''}',
      paymentId: '${payment['id_pembayaran'] ?? ''}',
      address: '${json['service_address'] ?? ''}',
      schedule: scheduled == null
          ? ''
          : '${scheduled.day}/${scheduled.month}/${scheduled.year} • ${scheduled.hour.toString().padLeft(2, '0')}:${scheduled.minute.toString().padLeft(2, '0')}',
      date: scheduled == null
          ? ''
          : '${scheduled.day}/${scheduled.month}/${scheduled.year}',
      time: scheduled == null
          ? ''
          : '${scheduled.hour.toString().padLeft(2, '0')}:${scheduled.minute.toString().padLeft(2, '0')}',
      note: '${json['notes'] ?? ''}',
      status: _statusFromApi('${json['status'] ?? ''}'),
      total: double.tryParse('${json['total_price']}')?.round() ?? 0,
      subtotal: double.tryParse('${json['subtotal']}')?.round() ?? 0,
      discount: double.tryParse('${json['discount_amount']}')?.round() ?? 0,
      voucherCode: '${(json['voucher'] as Map?)?['code'] ?? ''}',
      travelFee: double.tryParse('${json['travel_fee']}')?.round() ?? 0,
      travelDistanceKm: double.tryParse('${json['travel_distance_km']}') ?? 0,
    );
  }

  Review _reviewFromApi(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map? ?? {});
    return Review(
      id: '${json['id'] ?? ''}',
      bookingId: '${json['booking_id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      userName: '${user['name'] ?? ''}',
      mitraId: '${json['mitra_id'] ?? ''}',
      employeeId: '${json['pelayan_id'] ?? ''}',
      rating: double.tryParse('${json['rating']}') ?? 0,
      comment: '${json['review'] ?? ''}',
      createdAt: '${json['created_at'] ?? ''}',
      photoUrls:
          ((json['photo_urls'] as List?) ?? []).map((item) => '$item').toList(),
    );
  }

  AppNotification _notificationFromApi(Map<String, dynamic> json) =>
      AppNotification(
        id: '${json['id'] ?? ''}',
        bookingId: '${json['booking_id'] ?? ''}',
        title: '${json['title'] ?? ''}',
        message: '${json['message'] ?? ''}',
        type: '${json['type'] ?? 'SYSTEM'}',
        createdAt: '${json['created_at'] ?? ''}',
        read: json['read_at'] != null,
      );

  Pembayaran _paymentFromApi(Map<String, dynamic> json) => Pembayaran(
        id: '${json['id_pembayaran'] ?? ''}',
        bookingId: '${json['id_booking'] ?? ''}',
        method: '${json['metode_pembayaran'] ?? ''}',
        status: '${json['status_pembayaran'] ?? ''}',
        amount: double.tryParse('${json['total_bayar']}')?.round() ?? 0,
        paidAt: '${json['waktu_bayar'] ?? ''}',
      );

  Riwayat _historyFromApi(Map<String, dynamic> json) => Riwayat(
        id: '${json['id'] ?? ''}',
        bookingId: '${json['booking_id'] ?? ''}',
        title: _statusFromApi('${json['status'] ?? ''}'),
        description: '${json['description'] ?? ''}',
        status: _statusFromApi('${json['status'] ?? ''}'),
        createdAt: '${json['created_at'] ?? ''}',
      );

  ChatMessage _chatFromApi(Map<String, dynamic> json) => ChatMessage(
        id: '${json['id'] ?? ''}',
        bookingId: '${json['booking_id'] ?? ''}',
        senderId: '${json['sender_id'] ?? ''}',
        receiverId: '${json['receiver_id'] ?? ''}',
        message: '${json['message'] ?? ''}',
        createdAt: '${json['created_at'] ?? ''}',
      );

  IconData _categoryIcon(String value) {
    final category = value.toLowerCase();
    if (category.contains('nail')) return Icons.back_hand_outlined;
    if (category.contains('hair') || category.contains('rambut')) {
      return Icons.content_cut_rounded;
    }
    if (category.contains('spa')) return Icons.spa_outlined;
    return Icons.face_retouching_natural_outlined;
  }

  bool _isRemovedCareService(String name, String category) {
    final value = '$name $category'.toLowerCase();
    return value.contains('spa') ||
        value.contains('massage') ||
        value.contains('pijat');
  }

  String _mediaUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final apiUri = Uri.parse(ApiClient.baseUrl);
    final origin = '${apiUri.scheme}://${apiUri.host}'
        '${apiUri.hasPort ? ':${apiUri.port}' : ''}';
    if (trimmed.startsWith('http')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null &&
          uri.path.startsWith('/storage/') &&
          _isPrivateHost(uri.host)) {
        return '$origin${uri.path}';
      }
      return trimmed;
    }
    return trimmed.startsWith('/') ? '$origin$trimmed' : '$origin/$trimmed';
  }

  bool _isPrivateHost(String host) {
    final value = host.toLowerCase();
    if (value == 'localhost' || value == '127.0.0.1') return true;
    if (value.startsWith('192.168.')) return true;
    if (value.startsWith('10.')) return true;
    final parts = value.split('.');
    if (parts.length == 4) {
      final first = int.tryParse(parts[0]);
      final second = int.tryParse(parts[1]);
      if (first == 172 && second != null && second >= 16 && second <= 31) {
        return true;
      }
    }
    return false;
  }

  String _statusToApi(String status) {
    const aliases = {
      'Diterima Mitra': 'DITERIMA_MITRA',
      'Dikirim ke Pelayan': 'DIKIRIM_KE_PELAYAN',
      'Diterima': 'DITERIMA_PELAYAN',
      'Diterima Pelayan': 'DITERIMA_PELAYAN',
      'Pelayan Menuju Lokasi': 'MENUJU_LOKASI',
      'Menuju Lokasi': 'MENUJU_LOKASI',
      'Sedang Dikerjakan': 'SEDANG_DIKERJAKAN',
      'Selesai': 'SELESAI',
      'Dibatalkan': 'DIBATALKAN',
      'Ditolak Mitra': 'DITOLAK_MITRA',
      'Ditolak Pelayan': 'DITOLAK_PELAYAN',
    };
    return aliases[status] ?? status.toUpperCase().replaceAll(' ', '_');
  }

  String _statusFromApi(String status) {
    const aliases = {
      'MENUNGGU_PEMBAYARAN': 'Menunggu Pembayaran',
      'MENUNGGU_KONFIRMASI_MITRA': 'Menunggu Mitra',
      'DITERIMA_MITRA': 'Diterima Mitra',
      'DIKIRIM_KE_PELAYAN': 'Dikirim ke Pelayan',
      'DITERIMA_PELAYAN': 'Diterima Pelayan',
      'MENUJU_LOKASI': 'Menuju Lokasi',
      'SEDANG_DIKERJAKAN': 'Sedang Dikerjakan',
      'SELESAI': 'Selesai',
      'DIBATALKAN': 'Dibatalkan',
      'DITOLAK_MITRA': 'Ditolak Mitra',
      'DITOLAK_PELAYAN': 'Ditolak Pelayan',
    };
    return aliases[status] ?? status;
  }
}
