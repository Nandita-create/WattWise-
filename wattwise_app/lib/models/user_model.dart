class UserModel {
  final int? id;
  final String fullName;
  final String username;
  final String email;
  final String passwordHash;
  final double tariffRatePerKwh;
  final int householdSize;
  final String createdAt;

  const UserModel({
    this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.passwordHash,
    this.tariffRatePerKwh = 8.0,
    this.householdSize = 3,
    required this.createdAt,
  });

  UserModel copyWith({
    int? id,
    String? fullName,
    String? username,
    String? email,
    String? passwordHash,
    double? tariffRatePerKwh,
    int? householdSize,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      tariffRatePerKwh: tariffRatePerKwh ?? this.tariffRatePerKwh,
      householdSize: householdSize ?? this.householdSize,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'tariff_rate_per_kwh': tariffRatePerKwh,
      'household_size': householdSize,
      'created_at': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      fullName: map['full_name'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      tariffRatePerKwh: (map['tariff_rate_per_kwh'] as num?)?.toDouble() ?? 8.0,
      householdSize: (map['household_size'] as int?) ?? 3,
      createdAt: map['created_at'] as String,
    );
  }
}
