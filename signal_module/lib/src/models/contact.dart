/// Represents a contact/recipient in the Signal app
class Contact {
  const Contact({
    required this.id,
    required this.displayName,
    this.phoneNumber,
    this.avatarUrl,
    this.about,
    this.isVerified = false,
    this.isMuted = false,
    this.disappearingMessagesSeconds,
    this.customNotificationSound,
  });

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
    id: json['id'] as String,
    displayName: json['displayName'] as String,
    phoneNumber: json['phoneNumber'] as String?,
    avatarUrl: json['avatarUrl'] as String?,
    about: json['about'] as String?,
    isVerified: json['isVerified'] as bool? ?? false,
    isMuted: json['isMuted'] as bool? ?? false,
    disappearingMessagesSeconds: json['disappearingMessagesSeconds'] as int?,
    customNotificationSound: json['customNotificationSound'] as String?,
  );

  final String id;
  final String displayName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? about;
  final bool isVerified;
  final bool isMuted;
  final int? disappearingMessagesSeconds;
  final String? customNotificationSound;

  /// Generate initials from display name
  String get initials {
    final parts = displayName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  /// Format disappearing messages duration
  String? get disappearingMessagesFormatted {
    final seconds = disappearingMessagesSeconds;
    if (seconds == null || seconds == 0) {
      return null;
    }

    if (seconds < 60) {
      return '$seconds seconds';
    }
    if (seconds < 3600) {
      return '${seconds ~/ 60} minutes';
    }
    if (seconds < 86400) {
      return '${seconds ~/ 3600} hours';
    }
    if (seconds < 604800) {
      return '${seconds ~/ 86400} days';
    }
    return '${seconds ~/ 604800} weeks';
  }

  Contact copyWith({
    String? id,
    String? displayName,
    String? phoneNumber,
    String? avatarUrl,
    String? about,
    bool? isVerified,
    bool? isMuted,
    int? disappearingMessagesSeconds,
    String? customNotificationSound,
  }) {
    return Contact(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      about: about ?? this.about,
      isVerified: isVerified ?? this.isVerified,
      isMuted: isMuted ?? this.isMuted,
      disappearingMessagesSeconds:
          disappearingMessagesSeconds ?? this.disappearingMessagesSeconds,
      customNotificationSound:
          customNotificationSound ?? this.customNotificationSound,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'phoneNumber': phoneNumber,
    'avatarUrl': avatarUrl,
    'about': about,
    'isVerified': isVerified,
    'isMuted': isMuted,
    'disappearingMessagesSeconds': disappearingMessagesSeconds,
    'customNotificationSound': customNotificationSound,
  };
}

/// Mock contacts for development
class MockContacts {
  MockContacts._();

  static const alice = Contact(
    id: 'contact_alice',
    displayName: 'Alice Johnson',
    phoneNumber: '+1 (555) 123-4567',
    about: 'Available',
    isVerified: true,
    disappearingMessagesSeconds: 604800, // 1 week
  );

  static const bob = Contact(
    id: 'contact_bob',
    displayName: 'Bob Smith',
    phoneNumber: '+1 (555) 987-6543',
    about: 'At work',
    isMuted: true,
  );
}
