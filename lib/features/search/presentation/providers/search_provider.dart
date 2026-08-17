import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlobalSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  @override
  set state(String value) => super.state = value;
  void updateQuery(String value) => state = value;
}

/// Live query string entered in the top bar search pill.
/// Reactively filters the currently active view (Home lists/items or Collection items).
final globalSearchQueryProvider =
    NotifierProvider<GlobalSearchQueryNotifier, String>(
  GlobalSearchQueryNotifier.new,
);
