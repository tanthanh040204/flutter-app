// Smoke test: verify the root widget can be instantiated.
//
// Real integration coverage lives outside this widget test since the app
// depends on Firebase + MQTT initialisation that isn't wired in tests.

import 'package:first_flutter_project/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TnGoUserApp constructs', () {
    // Construct without pumping into the binding — ensures the widget
    // tree wiring in main.dart still compiles.
    const TnGoUserApp();
  });
}
