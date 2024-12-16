// ignore_for_file: deprecated_member_use

import 'dart:ui';

int convertColor(int color, int alpha) => Color(color).withAlpha(alpha).value;
int convertOldColor(int color, int old) =>
    convertColor(color, Color(old).alpha);
