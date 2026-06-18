import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/app_language_provider.dart';

class LanguageSwitch extends StatelessWidget {
  final double width;
  final double height;

  const LanguageSwitch({
    super.key,
    this.width = 108,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    final AppLanguageProvider language = context.watch<AppLanguageProvider>();

    return Semantics(
      label: context.tr.language,
      child: SizedBox(
        width: width,
        height: height,
        child: SegmentedButton<AppLanguage>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment<AppLanguage>(
              value: AppLanguage.vi,
              label: Text('VN'),
            ),
            ButtonSegment<AppLanguage>(
              value: AppLanguage.en,
              label: Text('EN'),
            ),
          ],
          selected: {language.language},
          onSelectionChanged: (value) => context
              .read<AppLanguageProvider>()
              .setLanguage(value.first),
        ),
      ),
    );
  }
}
