import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_leap/material_leap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:window_manager/window_manager.dart';

final isWindow =
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

enum FullScreenMode { disabled, enabled, enabledExitButton, enabledHidden }

class WindowTitleBar<
  C extends LeapSettingsBlocBaseMixin<M>,
  M extends LeapSettings
>
    extends StatelessWidget
    implements PreferredSizeWidget {
  final List<Widget> actions;
  final Widget? title;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool onlyShowOnDesktop;
  final bool inView;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? surfaceTintColor;
  final Color? shadowColor;
  final double? elevation;
  final double? scrolledUnderElevation;
  final double height;
  final bool titleIgnorePointer;
  final bool? centerTitle;
  final double? leadingWidth;
  final double? titleSpacing;
  final FullScreenMode fullScreenMode;

  const WindowTitleBar({
    super.key,
    this.title,
    this.titleIgnorePointer = true,
    this.leading,
    this.bottom,
    this.leadingWidth,
    this.titleSpacing,
    this.backgroundColor,
    this.foregroundColor,
    this.surfaceTintColor,
    this.shadowColor,
    this.elevation,
    this.scrolledUnderElevation,
    this.actions = const [],
    this.onlyShowOnDesktop = false,
    this.inView = false,
    this.height = kToolbarHeight,
    this.fullScreenMode = FullScreenMode.enabledExitButton,
    this.centerTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, M>(
      buildWhen: (previous, current) =>
          previous.nativeTitleBar != current.nativeTitleBar,
      builder: (context, settings) {
        final isDesktop = isWindow && !kIsWeb;
        if (onlyShowOnDesktop && (!isDesktop || settings.nativeTitleBar)) {
          return const SizedBox.shrink();
        }
        final useWindowButtons =
            isDesktop && !inView && !settings.nativeTitleBar;
        var title = this.title;
        if (title != null && titleIgnorePointer) {
          title = IgnorePointer(child: title);
        }
        final colorScheme = Theme.of(context).colorScheme;
        return AppBar(
          title: title,
          centerTitle: centerTitle,
          backgroundColor: backgroundColor ?? colorScheme.surfaceContainer,
          foregroundColor: foregroundColor,
          surfaceTintColor: surfaceTintColor ?? Colors.transparent,
          shadowColor: shadowColor,
          elevation: elevation,
          scrolledUnderElevation: scrolledUnderElevation,
          automaticallyImplyLeading: !inView,
          leading: leading,
          bottom: bottom,
          actionsPadding: EdgeInsets.zero,
          leadingWidth: leadingWidth,
          titleSpacing: titleSpacing,
          toolbarHeight: height,
          flexibleSpace: WindowFreeSpace<C, M>(),
          actions: [
            ...actions,
            if (useWindowButtons) ...[
              if (actions.isNotEmpty) ...[
                const SizedBox(width: 8),
                SizedBox(
                  height: height * 0.48,
                  child: const VerticalDivider(width: 1),
                ),
                const SizedBox(width: 8),
              ],
              WindowButtons<C, M>(
                fullScreenMode: fullScreenMode,
                height: height,
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));
}

class WindowFreeSpace<
  C extends LeapSettingsBlocBaseMixin<M>,
  M extends LeapSettings
>
    extends StatelessWidget {
  const WindowFreeSpace({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, M>(
      buildWhen: (previous, current) =>
          previous.nativeTitleBar != current.nativeTitleBar,
      builder: (context, settings) {
        if (!isWindow || kIsWeb || settings.nativeTitleBar) {
          return const SizedBox.shrink();
        }
        return GestureDetector(
          child: DragToMoveArea(child: Container(color: Colors.transparent)),
          onSecondaryTap: () => windowManager.popUpWindowMenu(),
          onLongPress: () => windowManager.popUpWindowMenu(),
        );
      },
    );
  }
}

class WindowButtons<
  C extends LeapSettingsBlocBaseMixin<M>,
  M extends LeapSettings
>
    extends StatefulWidget {
  final FullScreenMode fullScreenMode;
  final bool updateSettings;
  final double height;

  const WindowButtons({
    super.key,
    this.updateSettings = true,
    this.height = kToolbarHeight,
    this.fullScreenMode = FullScreenMode.enabledExitButton,
  });

  @override
  State<WindowButtons<C, M>> createState() => _WindowButtonsState<C, M>();
}

class _WindowButtonsState<
  C extends LeapSettingsBlocBaseMixin<M>,
  M extends LeapSettings
>
    extends State<WindowButtons<C, M>>
    with WindowListener {
  bool maximized = false, alwaysOnTop = false, fullScreen = false;

  @override
  void initState() {
    if (!kIsWeb && isWindow) {
      windowManager.addListener(this);
    }
    super.initState();
    updateStates();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> updateStates() async {
    final nextMaximized = await windowManager.isMaximized();
    final nextAlwaysOnTop = await windowManager.isAlwaysOnTop();
    final nextFullScreen = await windowManager.isFullScreen();
    if (mounted) {
      setState(() {
        maximized = nextMaximized;
        alwaysOnTop = nextAlwaysOnTop;
        fullScreen = nextFullScreen;
      });
    }
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => maximized = false);
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => maximized = true);
  }

  @override
  void onWindowEnterFullScreen() {
    if (mounted) setState(() => fullScreen = true);
  }

  @override
  void onWindowLeaveFullScreen() {
    if (mounted) setState(() => fullScreen = false);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, M>(
      buildWhen: (previous, current) =>
          previous.nativeTitleBar != current.nativeTitleBar,
      builder: (context, settings) {
        if (!kIsWeb && isWindow && !settings.nativeTitleBar) {
          final localizations = LeapLocalizations.of(context);
          final colorScheme = Theme.of(context).colorScheme;
          return SizedBox(
            height: widget.height,
            child: Align(
              alignment: Alignment.topRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (fullScreen &&
                      widget.fullScreenMode ==
                          FullScreenMode.enabledExitButton) ...[
                    IconButton(
                      icon: const PhosphorIcon(PhosphorIconsLight.arrowsIn),
                      tooltip: localizations.exitFullScreen,
                      style: _windowButtonStyle(context),
                      onPressed: () async {
                        context.read<WindowCubit>().changeFullScreen(false);
                      },
                    ),
                  ],
                  if (!fullScreen ||
                      widget.fullScreenMode == FullScreenMode.enabled ||
                      widget.fullScreenMode == FullScreenMode.disabled) ...[
                    IconButton(
                      icon: const PhosphorIcon(PhosphorIconsLight.minus),
                      tooltip: localizations.minimize,
                      style: _windowButtonStyle(context),
                      onPressed: () => windowManager.minimize(),
                    ),
                    MenuAnchor(
                      builder: (context, controller, child) => GestureDetector(
                        onLongPress: controller.toggle,
                        onSecondaryTap: controller.toggle,
                        child: IconButton(
                          tooltip: maximized || fullScreen
                              ? localizations.restore
                              : localizations.maximize,
                          icon: PhosphorIcon(
                            PhosphorIconsLight.square,
                            size: maximized ? 14 : 18,
                          ),
                          onPressed: fullScreen
                              ? () {
                                  context.read<WindowCubit>().changeFullScreen(
                                    false,
                                  );
                                }
                              : () async => await windowManager.isMaximized()
                                    ? windowManager.unmaximize()
                                    : windowManager.maximize(),
                          style: _windowButtonStyle(context),
                        ),
                      ),
                      menuChildren: [
                        MenuItemButton(
                          leadingIcon: PhosphorIcon(
                            alwaysOnTop
                                ? PhosphorIconsFill.pushPin
                                : PhosphorIconsLight.pushPin,
                          ),
                          child: Text(
                            alwaysOnTop
                                ? localizations.exitAlwaysOnTop
                                : localizations.alwaysOnTop,
                          ),
                          onPressed: () async {
                            await windowManager.setAlwaysOnTop(!alwaysOnTop);
                            setState(() => alwaysOnTop = !alwaysOnTop);
                          },
                        ),
                        if (widget.fullScreenMode != FullScreenMode.disabled)
                          MenuItemButton(
                            leadingIcon: PhosphorIcon(
                              fullScreen
                                  ? PhosphorIconsLight.arrowsIn
                                  : PhosphorIconsLight.arrowsOut,
                            ),
                            child: Text(
                              fullScreen
                                  ? localizations.exitFullScreen
                                  : localizations.fullScreen,
                            ),
                            onPressed: () {
                              context.read<WindowCubit>().toggleFullScreen();
                            },
                          ),
                      ],
                    ),
                    IconButton(
                      icon: const PhosphorIcon(PhosphorIconsLight.x),
                      tooltip: localizations.close,
                      color: colorScheme.error,
                      style: _windowButtonStyle(context, isClose: true),
                      onPressed: () async {
                        windowManager.close();
                      },
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        return Container();
      },
    );
  }
}

ButtonStyle _windowButtonStyle(BuildContext context, {bool isClose = false}) {
  final colorScheme = Theme.of(context).colorScheme;
  return IconButton.styleFrom(
    fixedSize: const Size.square(40),
    minimumSize: const Size.square(40),
    maximumSize: const Size.square(40),
    foregroundColor: isClose ? colorScheme.error : null,
    hoverColor: isClose
        ? colorScheme.errorContainer.withValues(alpha: 0.75)
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
    highlightColor: isClose
        ? colorScheme.errorContainer
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.12),
    padding: EdgeInsets.zero,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    alignment: Alignment.center,
  );
}
