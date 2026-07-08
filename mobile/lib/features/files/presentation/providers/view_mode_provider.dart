import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ViewMode { list, grid }

class ViewModeNotifier extends Notifier<ViewMode> {
  @override
  ViewMode build() {
    _loadFromPrefs();
    return ViewMode.list; // Default initial state
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final isGrid = prefs.getBool('isGrid') ?? false;
    state = isGrid ? ViewMode.grid : ViewMode.list;
  }

  Future<void> toggleMode() async {
    final newMode = state == ViewMode.list ? ViewMode.grid : ViewMode.list;
    state = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGrid', newMode == ViewMode.grid);
  }
}

final viewModeProvider = NotifierProvider<ViewModeNotifier, ViewMode>(() {
  return ViewModeNotifier();
});
