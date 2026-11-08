import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_leap/src/api/full_screen.dart';
import 'package:window_manager/window_manager.dart';

mixin LeapSettings {
  bool get nativeTitleBar;
}

mixin LeapSettingsBlocBaseMixin<T extends LeapSettings> on BlocBase<T> {}

class WindowState {
  final bool fullScreen;

  WindowState({this.fullScreen = false});

  WindowState withFullScreen(bool fullScreen) {
    return WindowState(fullScreen: fullScreen);
  }
}

class WindowCubit extends Cubit<WindowState> with WindowListener {
  WindowCubit({required bool fullScreen})
    : super(WindowState(fullScreen: fullScreen)) {
    windowManager.addListener(this);
  }

  @override
  Future<void> close() {
    dispose();
    return super.close();
  }

  @override
  void onWindowEnterFullScreen() {
    emit(state.withFullScreen(true));
  }

  @override
  void onWindowLeaveFullScreen() {
    emit(state.withFullScreen(false));
  }

  void dispose() {
    windowManager.removeListener(this);
  }

  Future<void> changeFullScreen(bool value, [bool modify = true]) async {
    if (modify) setFullScreen(value);
    emit(state.withFullScreen(value));
  }

  Future<void> toggleFullScreen() async {
    setFullScreen(!state.fullScreen);
    emit(state.withFullScreen(!state.fullScreen));
  }
}
