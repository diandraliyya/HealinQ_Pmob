class UserCounselorModel {
  final String id;
  final String name;
  final String username;
  final String email;

  final String specialization;
  final int yearsExperience;
  final String location;
  final String bio;

  final bool offersOnline;
  final bool offersOffline;

  final double priceOnline;
  final double priceOffline;

  final double rating;
  final int totalReviews;

  final bool isAvailable;

  final String? avatarPath;

  UserCounselorModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.specialization,
    required this.yearsExperience,
    required this.location,
    required this.bio,
    required this.offersOnline,
    required this.offersOffline,
    required this.priceOnline,
    required this.priceOffline,
    required this.rating,
    required this.totalReviews,
    required this.isAvailable,
    this.avatarPath,
  });

  factory UserCounselorModel.fromMap(Map<String, dynamic> map) {
    return UserCounselorModel(
      id: map['id'],

      name: map['name'] ?? '',

      username: map['username'] ?? '',

      email: map['email'] ?? '',

      specialization: map['specialization'] ?? '',

      yearsExperience: map['years_experience'] ?? 0,

      location: map['location'] ?? '',

      bio: map['bio'] ?? '',

      offersOnline: map['offers_online'] ?? false,

      offersOffline: map['offers_offline'] ?? false,

      priceOnline:
          (map['price_online'] ?? 0).toDouble(),

      priceOffline:
          (map['price_offline'] ?? 0).toDouble(),

      rating:
          (map['rating'] ?? 0).toDouble(),

      totalReviews:
          map['total_reviews'] ?? 0,

      isAvailable:
          map['is_available'] ?? false,

      avatarPath: map['avatar_path'],
    );
  }
}