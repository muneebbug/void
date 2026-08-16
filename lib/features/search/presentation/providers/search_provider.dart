import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live query string entered in the top bar search pill.
/// Reactively filters the currently active view (Home lists/items or Collection items).
final globalSearchQueryProvider = StateProvider<String>((ref) => '');
