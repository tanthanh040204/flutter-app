/*
 * @file       home_feed_fetcher.dart
 * @brief      Conditional export. Android/iOS/desktop use dart:io to fetch RSS.
 *             Web falls back to local daily cards to avoid CORS surprises.
 */

export 'home_feed_fetcher_stub.dart'
    if (dart.library.io) 'home_feed_fetcher_io.dart';
