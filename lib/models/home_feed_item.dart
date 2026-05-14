/*
 * @file       home_feed_item.dart
 * @brief      Lightweight model for the Home tab daily traffic/weather cards.
 */

enum HomeFeedKind { traffic, weather }

class HomeFeedItem {
  final HomeFeedKind kind;
  final String title;
  final String summary;
  final String url;
  final String source;
  final DateTime? publishedAt;
  final bool isLive;

  const HomeFeedItem({
    required this.kind,
    required this.title,
    required this.summary,
    required this.url,
    required this.source,
    this.publishedAt,
    this.isLive = false,
  });
}
