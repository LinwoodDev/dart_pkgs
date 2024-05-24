import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LeapSettings {
  bool get nativeTitleBar;
  bool get fullScreen;
}

abstract class LeapSettingsCubit<T extends LeapSettings>
    extends StateStreamable<T> {
  FutureOr<void> changeNativeTitleBar(bool value);
  void setFullScreen(bool value);
  void toggleFullScreen() => setFullScreen(!state.fullScreen);
}
