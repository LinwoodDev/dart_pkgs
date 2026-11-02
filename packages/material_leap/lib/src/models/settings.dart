import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_leap/src/api/full_screen.dart';
import 'package:window_manager/window_manager.dart';

import '../widgets/window.dart' show isWindow;

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

class WindowCubit extends Cubit<WindowState> {
  Window? _window;
  ListenerId? _listener;

  WindowCubit({required bool fullScreen})
    : super(WindowState(fullScreen: fullScreen)) {
    if (isWindow) {
      _window = WindowManager.instance.getCurrent();
      _listener = _window?.addListener(_onWindowEvent);
    }
  }

  @override
  Future<void> close() {
    dispose();
    return super.close();
  }

  void _onWindowEvent(WindowEvent event) {
    if (isClosed) return;
    switch (event) {
      case WindowEnteredFullScreenEvent():
        emit(state.withFullScreen(true));
      case WindowExitedFullScreenEvent():
        emit(state.withFullScreen(false));
      default:
        break;
    }
  }

  void dispose() {
    final listener = _listener;
    if (listener != null) _window?.removeListener(listener);
    _listener = null;
    _window?.dispose();
    _window = null;
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
