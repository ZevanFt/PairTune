class UserProfile {
  UserProfile({
    required this.owner,
    required this.displayName,
    this.bio,
    this.avatar,
    required this.relationshipLabel,
  });

  final String owner;
  final String displayName;
  final String? bio;
  final String? avatar;
  final String relationshipLabel;

  static UserProfile fromMap(Map<String, dynamic> map) {
    return UserProfile(
      owner: map['owner'] as String,
      displayName: map['display_name'] as String,
      bio: map['bio'] as String?,
      avatar: map['avatar'] as String?,
      relationshipLabel: (map['relationship_label'] as String?) ?? '搭档',
    );
  }
}
