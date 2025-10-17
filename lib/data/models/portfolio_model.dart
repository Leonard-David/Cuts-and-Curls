// lib/data/models/portfolio_item.dart
// Model for barber portfolio items (images, captions).
// Maps to /portfolio/{itemId}

class PortfolioItem {
  final String id;
  final String barberId;
  final String imageUrl;
  final String? caption;
  final int createdAtEpoch;

  PortfolioItem({
    required this.id,
    required this.barberId,
    required this.imageUrl,
    this.caption,
    required this.createdAtEpoch,
  });

  factory PortfolioItem.fromMap(Map<String, dynamic> map, String id) {
    return PortfolioItem(
      id: id,
      barberId: map['barberId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      caption: map['caption'] as String?,
      createdAtEpoch: map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  Map<String, dynamic> toMap() => {
        'barberId': barberId,
        'imageUrl': imageUrl,
        'caption': caption,
        'createdAt': createdAtEpoch,
      }..removeWhere((k, v) => v == null);
}
