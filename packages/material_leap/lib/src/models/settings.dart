import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_leap/src/api/full_screen.dart';

abstract class LeapSettings {
  bool get nativeTitleBar;
  bool get fullScreen;

  LeapSettings copyWith({
    bool nativeTitleBar,
    bool fullScreen,
  });
}

mixin LeapSettingsBlocBaseMixin<T extends LeapSettings> on BlocBase<T> {
  Future<void> changeFullScreen(bool value, [bool modify = true]) async {
    if (modify) setFullScreen(value);
    emit(state.copyWith(fullScreen: value) as T);
  }

  Future<void> toggleFullScreen() async {
    setFullScreen(!state.fullScreen);
    emit(state.copyWith(fullScreen: !state.fullScreen) as T);
  }
}
