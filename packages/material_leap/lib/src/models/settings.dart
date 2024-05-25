import 'package:flutter_bloc/flutter_bloc.dart';

abstract class LeapSettings {
  bool get nativeTitleBar;
}

mixin LeapSettingsStreamableMixin<T extends LeapSettings>
    on StateStreamable<T> {}
