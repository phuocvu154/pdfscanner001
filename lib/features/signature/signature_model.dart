class SignatureItem {
  final String id;
  final String imagePath;
  final String name;
  final DateTime createdAt;

  const SignatureItem({
    required this.id,
    required this.imagePath,
    required this.name,
    required this.createdAt,
  });

  SignatureItem copyWith({String? name}) {
    return SignatureItem(
      id: id,
      imagePath: imagePath,
      name: name ?? this.name,
      createdAt: createdAt,
    );
  }
}
