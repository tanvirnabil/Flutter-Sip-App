class ContactItem {
  final String id;
  final String name;
  final String extension;
  final String? email;
  final bool isFavorite;
  final String? avatarUrl;
  final bool isDeviceContact;

  ContactItem({
    required this.id,
    required this.name,
    required this.extension,
    this.email,
    this.isFavorite = false,
    this.avatarUrl,
    this.isDeviceContact = false,
  });

  ContactItem copyWith({
    String? id,
    String? name,
    String? extension,
    String? email,
    bool? isFavorite,
    String? avatarUrl,
    bool? isDeviceContact,
  }) {
    return ContactItem(
      id: id ?? this.id,
      name: name ?? this.name,
      extension: extension ?? this.extension,
      email: email ?? this.email,
      isFavorite: isFavorite ?? this.isFavorite,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isDeviceContact: isDeviceContact ?? this.isDeviceContact,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'extension': extension,
      'email': email,
      'isFavorite': isFavorite ? 1 : 0,
      'avatarUrl': avatarUrl,
    };
  }

  factory ContactItem.fromMap(Map<String, dynamic> map) {
    return ContactItem(
      id: map['id'] as String,
      name: map['name'] as String,
      extension: map['extension'] as String,
      email: map['email'] as String?,
      isFavorite: (map['isFavorite'] as int?) == 1,
      avatarUrl: map['avatarUrl'] as String?,
      isDeviceContact: false,
    );
  }
}
