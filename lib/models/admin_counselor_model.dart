class AdminCounselorModel {
  final String id;
  final String username;
  final String name;
  final String email;
  final String status;
  final DateTime createdAt;

  final String specialization;
  final int yearsExperience;
  final String location;
  final String bio;

  final bool offersOnline;
  final bool offersOffline;

  final double priceOnline;
  final double priceOffline;

  final double rating;
  final int ratingCount;

  final bool isAvailable;

  final DateTime? approvedAt;
  final String? approvedBy;

  const AdminCounselorModel({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.status,
    required this.createdAt,
    required this.specialization,
    required this.yearsExperience,
    required this.location,
    required this.bio,
    required this.offersOnline,
    required this.offersOffline,
    required this.priceOnline,
    required this.priceOffline,
    required this.rating,
    required this.ratingCount,
    required this.isAvailable,
    this.approvedAt,
    this.approvedBy,
  });

  factory AdminCounselorModel.fromMap(
    Map<String, dynamic> map,
  ) {
    final Map<String, dynamic> counselorProfile =
        _extractCounselorProfile(
      map['counselor_profiles'],
    );

    return AdminCounselorModel(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      name: map['full_name']?.toString() ?? 'Unknown Counselor',
      email: map['email']?.toString() ?? '',
      status: map['status']?.toString().toLowerCase() ?? 'pending',
      createdAt: _toDateTime(map['created_at']) ?? DateTime.now(),

      specialization:
          counselorProfile['specialization']?.toString() ??
              'Not specified',

      yearsExperience: _toInt(
        counselorProfile['years_experience'],
      ),

      location:
          counselorProfile['location']?.toString() ??
              'Location not specified',

      bio:
          counselorProfile['professional_bio']?.toString() ?? '',

      offersOnline:
          counselorProfile['offers_online'] == true,

      offersOffline:
          counselorProfile['offers_offline'] == true,

      priceOnline: _toDouble(
        counselorProfile['price_online'],
      ),

      priceOffline: _toDouble(
        counselorProfile['price_offline'],
      ),

      rating: _toDouble(
        counselorProfile['rating'],
      ),

      ratingCount: _toInt(
        counselorProfile['rating_count'],
      ),

      isAvailable:
          counselorProfile['is_available'] == true,

      approvedAt: _toDateTime(
        counselorProfile['approved_at'],
      ),

      approvedBy:
          counselorProfile['approved_by']?.toString(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'active':
        return 'Active';

      case 'inactive':
        return 'Inactive';

      case 'pending':
        return 'Pending';

      case 'suspended':
        return 'Suspended';

      default:
        return status;
    }
  }

  String get consultationType {
    if (offersOnline && offersOffline) {
      return 'Online & Offline';
    }

    if (offersOnline) {
      return 'Online';
    }

    if (offersOffline) {
      return 'Offline';
    }

    return 'Unavailable';
  }

  bool get isApproved {
    return status == 'active' && approvedAt != null;
  }

  AdminCounselorModel copyWith({
    String? id,
    String? username,
    String? name,
    String? email,
    String? status,
    DateTime? createdAt,
    String? specialization,
    int? yearsExperience,
    String? location,
    String? bio,
    bool? offersOnline,
    bool? offersOffline,
    double? priceOnline,
    double? priceOffline,
    double? rating,
    int? ratingCount,
    bool? isAvailable,
    DateTime? approvedAt,
    String? approvedBy,
  }) {
    return AdminCounselorModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      specialization:
          specialization ?? this.specialization,
      yearsExperience:
          yearsExperience ?? this.yearsExperience,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      offersOnline:
          offersOnline ?? this.offersOnline,
      offersOffline:
          offersOffline ?? this.offersOffline,
      priceOnline:
          priceOnline ?? this.priceOnline,
      priceOffline:
          priceOffline ?? this.priceOffline,
      rating: rating ?? this.rating,
      ratingCount:
          ratingCount ?? this.ratingCount,
      isAvailable:
          isAvailable ?? this.isAvailable,
      approvedAt:
          approvedAt ?? this.approvedAt,
      approvedBy:
          approvedBy ?? this.approvedBy,
    );
  }

  static Map<String, dynamic> _extractCounselorProfile(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    if (value is List && value.isNotEmpty) {
      final dynamic firstItem = value.first;

      if (firstItem is Map<String, dynamic>) {
        return firstItem;
      }

      if (firstItem is Map) {
        return Map<String, dynamic>.from(firstItem);
      }
    }

    return <String, dynamic>{};
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    return DateTime.tryParse(value.toString());
  }

  static int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }
}