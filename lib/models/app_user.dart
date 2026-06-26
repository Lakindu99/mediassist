/// Represents a MediAssist user and their role.
/// Role is central to the research: Elderly users are the PRIMARY users
/// (the focus of the adaptive interface); Caregivers are SECONDARY users
/// who monitor an elderly person's medication.
enum UserRole { elderly, caregiver }

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
  });

  /// Convert a role to a string for storing in Firestore ('elderly' / 'caregiver').
  static String roleToString(UserRole role) => role.name;

  /// Convert a stored string back into a role.
  static UserRole roleFromString(String value) =>
      value == 'caregiver' ? UserRole.caregiver : UserRole.elderly;

  /// Build an AppUser from a Firestore document.
  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      role: roleFromString(map['role'] ?? 'elderly'),
    );
  }
}
