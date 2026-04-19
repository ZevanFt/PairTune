import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global app state: owner (me/partner), duo mode, current tab index.
class AppState {
  const AppState({
    this.owner = 'me',
    this.duoEnabled = false,
    this.duoModeSelected = false,
    this.tabIndex = 0,
  });

  final String owner;
  final bool duoEnabled;
  final bool duoModeSelected;
  final int tabIndex;

  AppState copyWith({
    String? owner,
    bool? duoEnabled,
    bool? duoModeSelected,
    int? tabIndex,
  }) {
    return AppState(
      owner: owner ?? this.owner,
      duoEnabled: duoEnabled ?? this.duoEnabled,
      duoModeSelected: duoModeSelected ?? this.duoModeSelected,
      tabIndex: tabIndex ?? this.tabIndex,
    );
  }
}

class AppNotifier extends StateNotifier<AppState> {
  AppNotifier() : super(const AppState());

  void setOwner(String owner) => state = state.copyWith(owner: owner);
  void setDuoEnabled(bool enabled) => state = state.copyWith(duoEnabled: enabled, duoModeSelected: true);
  void setTabIndex(int index) => state = state.copyWith(tabIndex: index);

  void selectSoloMode() {
    state = state.copyWith(duoEnabled: false, duoModeSelected: true, owner: 'me');
  }

  void selectDuoMode() {
    state = state.copyWith(duoEnabled: true, duoModeSelected: true, owner: 'me');
  }

  void reset() {
    state = const AppState();
  }
}

final appProvider = StateNotifierProvider<AppNotifier, AppState>((ref) {
  return AppNotifier();
});
