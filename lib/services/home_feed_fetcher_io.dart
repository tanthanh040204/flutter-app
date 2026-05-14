/*
 * @file       home_feed_fetcher_io.dart
 * @brief      Fetches a few latest RSS items for Home tab traffic/weather cards
 *             without adding a new pubspec dependency.
 */

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/home_feed_item.dart';

const String kTuoiTreVehicleRssUrl = 'https://tuoitre.vn/rss/xe.rss';
const String kTuoiTreWeatherRssUrl = 'https://tuoitre.vn/rss/thoi-tiet.rss';
const String kTuoiTreVehicleUrl = 'https://tuoitre.vn/xe.htm';
const String kTuoiTreWeatherUrl = 'https://tuoitre.vn/thoi-tiet.htm';

Future<List<HomeFeedItem>> loadRemoteHomeFeedItems() async {
  final List<HomeFeedItem> items = <HomeFeedItem>[];

  final List<HomeFeedItem> trafficItems = await _readRss(
    uri: Uri.parse(kTuoiTreVehicleRssUrl),
    fallbackUrl: kTuoiTreVehicleUrl,
    kind: HomeFeedKind.traffic,
    source: 'Tuổi Trẻ Online',
    limit: 2,
  );
  items.addAll(trafficItems);

  final List<HomeFeedItem> weatherItems = await _readRss(
    uri: Uri.parse(kTuoiTreWeatherRssUrl),
    fallbackUrl: kTuoiTreWeatherUrl,
    kind: HomeFeedKind.weather,
    source: 'Tuổi Trẻ Online',
    limit: 2,
  );
  items.addAll(weatherItems);

  return items.take(4).toList(growable: false);
}

Future<List<HomeFeedItem>> _readRss({
  required Uri uri,
  required String fallbackUrl,
  required HomeFeedKind kind,
  required String source,
  required int limit,
}) async {
  try {
    final HttpClient client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 6)
      ..userAgent = 'UTE-go Flutter app';

    final HttpClientRequest request = await client.getUrl(uri).timeout(
          const Duration(seconds: 6),
        );
    request.headers.set(HttpHeaders.acceptHeader, 'application/rss+xml,text/xml,*/*');

    final HttpClientResponse response = await request.close().timeout(
          const Duration(seconds: 8),
        );

    final String body = await response.transform(utf8.decoder).join();
    client.close(force: true);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return const <HomeFeedItem>[];
    }

    return _parseRss(
      xml: body,
      fallbackUrl: fallbackUrl,
      kind: kind,
      source: source,
      limit: limit,
    );
  } catch (_) {
    return const <HomeFeedItem>[];
  }
}

List<HomeFeedItem> _parseRss({
  required String xml,
  required String fallbackUrl,
  required HomeFeedKind kind,
  required String source,
  required int limit,
}) {
  final Iterable<RegExpMatch> matches = RegExp(
    r'<item[\s\S]*?</item>',
    caseSensitive: false,
  ).allMatches(xml);

  final List<HomeFeedItem> items = <HomeFeedItem>[];
  for (final RegExpMatch match in matches) {
    if (items.length >= limit) break;

    final String itemXml = match.group(0) ?? '';
    final String title = _cleanText(_tagValue(itemXml, 'title'));
    final String summary = _shorten(_cleanText(_tagValue(itemXml, 'description')), 130);
    final String link = _cleanText(_tagValue(itemXml, 'link'));
    final String pubDate = _cleanText(_tagValue(itemXml, 'pubDate'));

    if (title.isEmpty) continue;

    items.add(
      HomeFeedItem(
        kind: kind,
        title: title,
        summary: summary.isEmpty ? 'Bấm đọc thêm để xem chi tiết.' : summary,
        url: link.isEmpty ? fallbackUrl : link,
        source: source,
        publishedAt: _tryParseHttpDate(pubDate),
        isLive: true,
      ),
    );
  }

  return items;
}

DateTime? _tryParseHttpDate(String value) {
  if (value.isEmpty) return null;
  try {
    return HttpDate.parse(value);
  } catch (_) {
    return null;
  }
}

String _tagValue(String xml, String tag) {
  final RegExpMatch? match = RegExp(
    '<$tag[^>]*>([\\s\\S]*?)</$tag>',
    caseSensitive: false,
  ).firstMatch(xml);
  return match?.group(1) ?? '';
}

String _cleanText(String value) {
  String text = value
      .replaceAll(RegExp(r'<!\[CDATA\[|\]\]>'), '')
      .replaceAll(RegExp(r'<[^>]+>'), ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'")
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  text = text.replaceAll(RegExp(r'Ảnh:\s*[^.]+\.?', caseSensitive: false), '').trim();
  return text;
}

String _shorten(String value, int maxLength) {
  if (value.length <= maxLength) return value;
  return '${value.substring(0, maxLength).trimRight()}...';
}
