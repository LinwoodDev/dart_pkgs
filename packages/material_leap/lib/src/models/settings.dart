import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LeapSettings {
  bool get nativeTitleBar;
  bool get fullScreen;
}

mixin LeapSettingsStreamableMixin<T extends LeapSettings>
    on StateStreamable<T> {
  void setFullScreen(bool value);
  void toggleFullScreen() => setFullScreen(!state.fullScreen);
}
