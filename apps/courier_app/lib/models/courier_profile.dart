class CourierProfile {
  const CourierProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isAvailable,
    this.vehicleType,
    this.vehiclePlate,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final bool isAvailable;
  final String? vehicleType;
  final String? vehiclePlate;

  String get initials {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'CD';
    }
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  String get vehicleSummary {
    final values = <String>[];
    if (vehicleType != null && vehicleType!.isNotEmpty) {
      values.add(vehicleType!);
    }
    if (vehiclePlate != null && vehiclePlate!.isNotEmpty) {
      values.add(vehiclePlate!);
    }
    return values.isEmpty ? 'Equipment not set' : values.join(' | ');
  }

  CourierProfile withAvailability(bool value) {
    return CourierProfile(
      id: id,
      name: name,
      email: email,
      phone: phone,
      isAvailable: value,
      vehicleType: vehicleType,
      vehiclePlate: vehiclePlate,
    );
  }

  factory CourierProfile.fromJson(Map<String, dynamic> json) {
    final user = _asMap(json['user']);
    final firstName =
        _firstText(<dynamic>[json['firstName'], user['firstName']]);
    final lastName = _firstText(<dynamic>[json['lastName'], user['lastName']]);
    final nameParts = <String>[];
    if (firstName != null) {
      nameParts.add(firstName);
    }
    if (lastName != null) {
      nameParts.add(lastName);
    }
    final joinedName = nameParts.join(' ');

    return CourierProfile(
      id: _firstText(
              <dynamic>[json['id'], json['courierId'], json['userId']]) ??
          '',
      name: _firstText(<dynamic>[json['name'], user['name']]) ??
          (joinedName.isEmpty ? 'Courier' : joinedName),
      email: _firstText(<dynamic>[json['email'], user['email']]) ?? '',
      phone: _firstText(<dynamic>[json['phone'], user['phone']]) ?? '',
      isAvailable: _availability(<dynamic>[
        json['isAvailable'],
        json['available'],
        json['availability'],
      ]),
      vehicleType: _firstText(<dynamic>[
        json['vehicleType'],
        json['vehicle_type'],
      ]),
      vehiclePlate: _firstText(<dynamic>[
        json['vehiclePlate'],
        json['vehicle_plate'],
      ]),
    );
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    final result = <String, dynamic>{};
    if (value is Map) {
      value.forEach((dynamic key, dynamic item) {
        if (key != null) {
          result[key.toString()] = item;
        }
      });
    }
    return result;
  }

  static String? _firstText(List<dynamic> values) {
    for (final value in values) {
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return null;
  }

  static bool _availability(List<dynamic> values) {
    for (final value in values) {
      if (value is bool) {
        return value;
      }
      if (value is String) {
        switch (value.trim().toLowerCase()) {
          case 'true':
          case 'available':
          case 'online':
          case 'active':
            return true;
          case 'false':
          case 'unavailable':
          case 'offline':
          case 'paused':
            return false;
        }
      }
    }
    return false;
  }
}
