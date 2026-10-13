import 'package:flutter/material.dart';

enum AppRole { user, mitra, pelayan, admin }

extension AppRoleLabel on AppRole {
  String get label {
    switch (this) {
      case AppRole.user:
        return 'User';
      case AppRole.mitra:
        return 'Mitra';
      case AppRole.pelayan:
        return 'Pelayan';
      case AppRole.admin:
        return 'Admin';
    }
  }
}

AppRole roleFromJson(String value) {
  return AppRole.values.firstWhere(
    (role) => role.name == value,
    orElse: () => AppRole.user,
  );
}

class ServiceCategory {
  const ServiceCategory({required this.name, required this.icon});

  final String name;
  final IconData icon;
}

class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.address,
    required this.photoUrl,
    this.status = 'ACTIVE',
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final AppRole role;
  final String address;
  final String photoUrl;
  final String status;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: roleFromJson(json['role'] as String? ?? 'user'),
      address: json['address'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'address': address,
      'photoUrl': photoUrl,
      'status': status,
    };
  }
}

class Mitra {
  const Mitra({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.rating,
    required this.distance,
    required this.description,
    required this.serviceIds,
    required this.employeeIds,
    required this.isOpen,
    this.ownerName = '',
    this.logoUrl = '',
    this.ktpUrl = '',
    this.verificationStatus = 'approved',
    this.rejectionReason = '',
    this.adminNote = '',
    this.createdAt = '',
  });

  final String id;
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final double rating;
  final String distance;
  final String description;
  final List<String> serviceIds;
  final List<String> employeeIds;
  final bool isOpen;
  final String ownerName;
  final String logoUrl;
  final String ktpUrl;
  final String verificationStatus;
  final String rejectionReason;
  final String adminNote;
  final String createdAt;

  bool get isApproved => verificationStatus == 'approved';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';

  factory Mitra.fromJson(Map<String, dynamic> json) {
    return Mitra(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      distance: json['distance'] as String? ?? '',
      description: json['description'] as String? ?? '',
      serviceIds: List<String>.from(json['serviceIds'] as List? ?? []),
      employeeIds: List<String>.from(json['employeeIds'] as List? ?? []),
      isOpen: json['isOpen'] as bool? ?? false,
      ownerName: json['ownerName'] as String? ?? '',
      logoUrl: json['logoUrl'] as String? ?? '',
      ktpUrl: json['ktpUrl'] as String? ?? '',
      verificationStatus: json['verificationStatus'] as String? ?? 'approved',
      rejectionReason: json['rejectionReason'] as String? ?? '',
      adminNote: json['adminNote'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'rating': rating,
      'distance': distance,
      'description': description,
      'serviceIds': serviceIds,
      'employeeIds': employeeIds,
      'isOpen': isOpen,
      'ownerName': ownerName,
      'logoUrl': logoUrl,
      'ktpUrl': ktpUrl,
      'verificationStatus': verificationStatus,
      'rejectionReason': rejectionReason,
      'adminNote': adminNote,
      'createdAt': createdAt,
    };
  }
}

class Pelayan {
  const Pelayan({
    required this.id,
    this.userId = '',
    required this.mitraId,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialty,
    required this.rating,
    required this.available,
    required this.photoUrl,
    required this.portfolioItems,
    this.bio = '',
    this.experienceYears = 0,
    this.reviewItems = const [],
    this.serviceIds = const [],
    this.busySchedules = const [],
  });

  final String id;
  final String userId;
  final String mitraId;
  final String name;
  final String email;
  final String phone;
  final String specialty;
  final double rating;
  final bool available;
  final String photoUrl;
  final List<Portofolio> portfolioItems;
  final String bio;
  final int experienceYears;
  final List<Review> reviewItems;
  final List<String> serviceIds;
  final List<DateTime> busySchedules;

  List<String> get portfolio {
    return portfolioItems.map((item) => item.title).toList();
  }

  factory Pelayan.fromJson(Map<String, dynamic> json) {
    return Pelayan(
      id: json['id'] as String? ?? '',
      mitraId: json['mitraId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      specialty: json['specialty'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      available: json['available'] as bool? ?? false,
      photoUrl: json['photoUrl'] as String? ?? '',
      portfolioItems: (json['portfolioItems'] as List? ?? [])
          .map((item) =>
              Portofolio.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      bio: json['bio'] as String? ?? '',
      experienceYears: json['experienceYears'] as int? ?? 0,
      reviewItems: (json['reviewItems'] as List? ?? [])
          .map(
              (item) => Review.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
      serviceIds:
          (json['serviceIds'] as List? ?? []).map((item) => '$item').toList(),
      busySchedules: (json['busySchedules'] as List? ?? [])
          .map((item) => DateTime.tryParse('$item'))
          .whereType<DateTime>()
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mitraId': mitraId,
      'name': name,
      'email': email,
      'phone': phone,
      'specialty': specialty,
      'rating': rating,
      'available': available,
      'photoUrl': photoUrl,
      'portfolioItems': portfolioItems.map((item) => item.toJson()).toList(),
      'bio': bio,
      'experienceYears': experienceYears,
      'reviewItems': reviewItems.map((item) => item.toJson()).toList(),
      'serviceIds': serviceIds,
      'busySchedules':
          busySchedules.map((item) => item.toIso8601String()).toList(),
    };
  }
}

class Layanan {
  const Layanan({
    required this.id,
    this.mitraId = '',
    required this.name,
    required this.category,
    required this.duration,
    required this.price,
    required this.icon,
    required this.description,
    required this.active,
  });

  final String id;
  final String mitraId;
  final String name;
  final String category;
  final String duration;
  final int price;
  final IconData icon;
  final String description;
  final bool active;

  factory Layanan.fromJson(Map<String, dynamic> json) {
    return Layanan(
      id: json['id'] as String? ?? '',
      mitraId: json['mitraId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      duration: json['duration'] as String? ?? '',
      price: json['price'] as int? ?? 0,
      icon: IconData(
        json['iconCodePoint'] as int? ?? Icons.spa_rounded.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      description: json['description'] as String? ?? '',
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mitraId': mitraId,
      'name': name,
      'category': category,
      'duration': duration,
      'price': price,
      'iconCodePoint': icon.codePoint,
      'description': description,
      'active': active,
    };
  }
}

class Booking {
  const Booking({
    required this.id,
    required this.userId,
    required this.userName,
    required this.partnerId,
    required this.employeeId,
    required this.serviceId,
    required this.paymentId,
    required this.address,
    required this.schedule,
    required this.date,
    required this.time,
    required this.note,
    required this.status,
    required this.total,
    this.subtotal = 0,
    this.discount = 0,
    this.voucherCode = '',
    this.travelFee = 0,
    this.travelDistanceKm = 0,
  });

  final String id;
  final String userId;
  final String userName;
  final String partnerId;
  final String employeeId;
  final String serviceId;
  final String paymentId;
  final String address;
  final String schedule;
  final String date;
  final String time;
  final String note;
  final String status;
  final int total;
  final int subtotal;
  final int discount;
  final String voucherCode;
  final int travelFee;
  final double travelDistanceKm;

  Booking copyWith({
    String? id,
    String? userId,
    String? userName,
    String? partnerId,
    String? employeeId,
    String? serviceId,
    String? paymentId,
    String? address,
    String? schedule,
    String? date,
    String? time,
    String? note,
    String? status,
    int? total,
    int? subtotal,
    int? discount,
    String? voucherCode,
    int? travelFee,
    double? travelDistanceKm,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      partnerId: partnerId ?? this.partnerId,
      employeeId: employeeId ?? this.employeeId,
      serviceId: serviceId ?? this.serviceId,
      paymentId: paymentId ?? this.paymentId,
      address: address ?? this.address,
      schedule: schedule ?? this.schedule,
      date: date ?? this.date,
      time: time ?? this.time,
      note: note ?? this.note,
      status: status ?? this.status,
      total: total ?? this.total,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      voucherCode: voucherCode ?? this.voucherCode,
      travelFee: travelFee ?? this.travelFee,
      travelDistanceKm: travelDistanceKm ?? this.travelDistanceKm,
    );
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      partnerId: json['partnerId'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      serviceId: json['serviceId'] as String? ?? '',
      paymentId: json['paymentId'] as String? ?? '',
      address: json['address'] as String? ?? '',
      schedule: json['schedule'] as String? ?? '',
      date: json['date'] as String? ?? '',
      time: json['time'] as String? ?? '',
      note: json['note'] as String? ?? '',
      status: json['status'] as String? ?? '',
      total: json['total'] as int? ?? 0,
      subtotal: json['subtotal'] as int? ?? 0,
      discount: json['discount'] as int? ?? 0,
      voucherCode: json['voucherCode'] as String? ?? '',
      travelFee: json['travelFee'] as int? ?? 0,
      travelDistanceKm: (json['travelDistanceKm'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'partnerId': partnerId,
      'employeeId': employeeId,
      'serviceId': serviceId,
      'paymentId': paymentId,
      'address': address,
      'schedule': schedule,
      'date': date,
      'time': time,
      'note': note,
      'status': status,
      'total': total,
      'subtotal': subtotal,
      'discount': discount,
      'voucherCode': voucherCode,
      'travelFee': travelFee,
      'travelDistanceKm': travelDistanceKm,
    };
  }
}

class Pembayaran {
  const Pembayaran({
    required this.id,
    required this.bookingId,
    required this.method,
    required this.status,
    required this.amount,
    required this.paidAt,
  });

  final String id;
  final String bookingId;
  final String method;
  final String status;
  final int amount;
  final String paidAt;

  factory Pembayaran.fromJson(Map<String, dynamic> json) {
    return Pembayaran(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      method: json['method'] as String? ?? '',
      status: json['status'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      paidAt: json['paidAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'method': method,
      'status': status,
      'amount': amount,
      'paidAt': paidAt,
    };
  }
}

class Review {
  const Review({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.userName,
    required this.mitraId,
    required this.employeeId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.photoUrls = const [],
  });

  final String id;
  final String bookingId;
  final String userId;
  final String userName;
  final String mitraId;
  final String employeeId;
  final double rating;
  final String comment;
  final String createdAt;
  final List<String> photoUrls;

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String? ?? '',
      mitraId: json['mitraId'] as String? ?? '',
      employeeId: json['employeeId'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      photoUrls:
          (json['photoUrls'] as List? ?? []).map((item) => '$item').toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'userId': userId,
      'userName': userName,
      'mitraId': mitraId,
      'employeeId': employeeId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      'photoUrls': photoUrls,
    };
  }
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.bookingId,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    required this.read,
  });

  final String id;
  final String bookingId;
  final String title;
  final String message;
  final String type;
  final String createdAt;
  final bool read;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String senderId;
  final String receiverId;
  final String message;
  final String createdAt;
}

class Riwayat {
  const Riwayat({
    required this.id,
    required this.bookingId,
    required this.title,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String bookingId;
  final String title;
  final String description;
  final String status;
  final String createdAt;

  factory Riwayat.fromJson(Map<String, dynamic> json) {
    return Riwayat(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      status: json['status'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingId': bookingId,
      'title': title,
      'description': description,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

class Portofolio {
  const Portofolio({
    required this.id,
    required this.pelayanId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.createdAt,
  });

  final String id;
  final String pelayanId;
  final String title;
  final String description;
  final String imageUrl;
  final String createdAt;

  factory Portofolio.fromJson(Map<String, dynamic> json) {
    return Portofolio(
      id: json['id'] as String? ?? '',
      pelayanId: json['pelayanId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pelayanId': pelayanId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': createdAt,
    };
  }
}

typedef Partner = Mitra;
typedef Employee = Pelayan;
typedef BodyCareService = Layanan;
