/*
 * @file       home_feed_fetcher_stub.dart
 * @brief      Safe fallback when network RSS fetching is not available.
 */

import '../models/home_feed_item.dart';

Future<List<HomeFeedItem>> loadRemoteHomeFeedItems() async {
  return const <HomeFeedItem>[];
}
