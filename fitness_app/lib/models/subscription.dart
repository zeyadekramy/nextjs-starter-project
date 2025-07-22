import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionType {
  monthly,
  quarterly,
  yearly,
}

enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  pending,
}

class Subscription {
  final String id;
  final String userId;
  final SubscriptionType type;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double price;
  final String? gymId;
  final String? gymName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Subscription({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.price,
    this.gymId,
    this.gymName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return Subscription(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: SubscriptionType.values.byName(data['type'] ?? 'monthly'),
      status: SubscriptionStatus.values.byName(data['status'] ?? 'active'),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      gymId: data['gymId'],
      gymName: data['gymName'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'status': status.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'price': price,
      'gymId': gymId,
      'gymName': gymName,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isExpiringSoon {
    final now = DateTime.now();
    final weekBeforeEnd = endDate.subtract(const Duration(days: 7));
    return now.isAfter(weekBeforeEnd) && now.isBefore(endDate);
  }

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  bool get isActive => status == SubscriptionStatus.active;
  bool get isExpired => status == SubscriptionStatus.expired || endDate.isBefore(DateTime.now());
}

class GymSession {
  final String id;
  final String userId;
  final String gymId;
  final String gymName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String qrCodeId;
  final String? sessionType;
  final Duration? duration;
  final DateTime createdAt;

  const GymSession({
    required this.id,
    required this.userId,
    required this.gymId,
    required this.gymName,
    required this.checkInTime,
    this.checkOutTime,
    required this.qrCodeId,
    this.sessionType,
    this.duration,
    required this.createdAt,
  });

  factory GymSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return GymSession(
      id: doc.id,
      userId: data['userId'] ?? '',
      gymId: data['gymId'] ?? '',
      gymName: data['gymName'] ?? '',
      checkInTime: (data['checkInTime'] as Timestamp).toDate(),
      checkOutTime: data['checkOutTime'] != null 
          ? (data['checkOutTime'] as Timestamp).toDate() 
          : null,
      qrCodeId: data['qrCodeId'] ?? '',
      sessionType: data['sessionType'],
      duration: data['duration'] != null 
          ? Duration(seconds: data['duration']) 
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'gymId': gymId,
      'gymName': gymName,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkOutTime': checkOutTime != null ? Timestamp.fromDate(checkOutTime!) : null,
      'qrCodeId': qrCodeId,
      'sessionType': sessionType,
      'duration': duration?.inSeconds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Duration? get calculatedDuration {
    if (checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime);
  }
}

class QRCode {
  final String id;
  final String gymId;
  final String gymName;
  final String code;
  final String? location;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QRCode({
    required this.id,
    required this.gymId,
    required this.gymName,
    required this.code,
    this.location,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QRCode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return QRCode(
      id: doc.id,
      gymId: data['gymId'] ?? '',
      gymName: data['gymName'] ?? '',
      code: data['code'] ?? '',
      location: data['location'],
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'gymId': gymId,
      'gymName': gymName,
      'code': code,
      'location': location,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
