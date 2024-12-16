import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_leap/l10n/leap_localizations.dart';
import 'package:material_leap/material_leap.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:window_manager/window_manager.dart';

final isWindow =
    !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

enum FullScreenMode { disabled, enabled, enabledExitButton, enabledHidden }

class WindowTitleBar<C extends LeapSettingsBlocBaseMixin<M>,
        M extends LeapSettings> extends StatelessWidget
    implements PreferredSizeWidget {
  final List<Widget> actions;
  final Widget? title;
  final Widget? leading;
  final PreferredSizeWidget? bottom;
  final bool onlyShowOnDesktop;
  final bool inView;
  final Color? backgroundColor;
  final double height;
  final double? leadingWidth;
  final FullScreenMode fullScreenMode;

  const WindowTitleBar({
    super.key,
    this.title,
    this.leading,
    this.bottom,
    this.leadingWidth,
    this.backgroundColor,
    this.actions = const [],
    this.onlyShowOnDesktop = false,
    this.inView = false,
    this.height = 70,
    this.fullScreenMode = FullScreenMode.enabledExitButton,
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
          return AppBar(
            title: title,
            backgroundColor: backgroundColor,
            automaticallyImplyLeading: !inView,
            leading: leading,
            bottom: bottom,
            leadingWidth: leadingWidth,
            toolbarHeight: height,
            flexibleSpace: WindowFreeSpace<C, M>(),
            actions: [
              ...actions,
              if (isDesktop && !inView)
                WindowButtons<C, M>(
                  divider: actions.isNotEmpty,
                  fullScreenMode: fullScreenMode,
                ),
            ],
          );
        });
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));
}

class WindowFreeSpace<C extends LeapSettingsBlocBaseMixin<M>,
    M extends LeapSettings> extends StatelessWidget {
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
            child: DragToMoveArea(
              child: Container(
                color: Colors.transparent,
              ),
            ),
            onSecondaryTap: () => windowManager.popUpWindowMenu(),
            onLongPress: () => windowManager.popUpWindowMenu(),
          );
        });
  }
}

class WindowButtons<C extends LeapSettingsBlocBaseMixin<M>,
    M extends LeapSettings> extends StatefulWidget {
  final bool divider;
  final FullScreenMode fullScreenMode;
  final bool updateSettings;

  const WindowButtons({
    super.key,
    this.divider = true,
    this.updateSettings = true,
    this.fullScreenMode = FullScreenMode.enabledExitButton,
  });

  @override
  State<WindowButtons<C, M>> createState() => _WindowButtonsState<C, M>();
}

class _WindowButtonsState<C extends LeapSettingsBlocBaseMixin<M>,
        M extends LeapSettings> extends State<WindowButtons<C, M>>
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
  void onWindowUnmaximize() => setState(() => maximized = false);

  @override
  void onWindowMaximize() => setState(() => maximized = true);

  @override
  void onWindowEnterFullScreen() => setState(() => fullScreen = true);

  @override
  void onWindowLeaveFullScreen() => setState(() => fullScreen = false);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<C, M>(
        buildWhen: (previous, current) =>
            previous.nativeTitleBar != current.nativeTitleBar,
        builder: (context, settings) {
          if (!kIsWeb && isWindow && !settings.nativeTitleBar) {
            return LayoutBuilder(
              builder: (context, constraints) => Align(
                alignment: Alignment.topRight,
                child: Card(
                  margin: EdgeInsets.zero,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 42),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.divider) const VerticalDivider(),
                        Row(
                          children: [
                            if (fullScreen &&
                                widget.fullScreenMode ==
                                    FullScreenMode.enabledExitButton) ...[
                              IconButton(
                                icon: const PhosphorIcon(
                                    PhosphorIconsLight.arrowsIn),
                                tooltip: LeapLocalizations.of(context)
                                    .exitFullScreen,
                                splashRadius: 20,
                                onPressed: () async {
                                  context
                                      .read<WindowCubit>()
                                      .changeFullScreen(false);
                                },
                              ),
                            ],
                            if (!fullScreen ||
                                widget.fullScreenMode ==
                                    FullScreenMode.enabled ||
                                widget.fullScreenMode ==
                                    FullScreenMode.disabled) ...[
                              IconButton(
                                icon: const PhosphorIcon(
                                    PhosphorIconsLight.minus),
                                tooltip: LeapLocalizations.of(context).minimize,
                                splashRadius: 20,
                                onPressed: () => windowManager.minimize(),
                              ),
                              const SizedBox(width: 8),
                              MenuAnchor(
                                builder: (context, controller, child) =>
                                    GestureDetector(
                                  onLongPress: controller.toggle,
                                  onSecondaryTap: controller.toggle,
                                  child: IconButton(
                                    tooltip: maximized || fullScreen
                                        ? LeapLocalizations.of(context).restore
                                        : LeapLocalizations.of(context)
                                            .maximize,
                                    icon: PhosphorIcon(
                                      PhosphorIconsLight.square,
                                      size: maximized ? 14 : 20,
                                      color: Theme.of(context).iconTheme.color,
                                    ),
                                    onPressed: fullScreen
                                        ? () {
                                            context
                                                .read<WindowCubit>()
                                                .changeFullScreen(false);
                                          }
                                        : () async =>
                                            await windowManager.isMaximized()
                                                ? windowManager.unmaximize()
                                                : windowManager.maximize(),
                                  ),
                                ),
                                menuChildren: [
                                  MenuItemButton(
                                    leadingIcon: PhosphorIcon(alwaysOnTop
                                        ? PhosphorIconsFill.pushPin
                                        : PhosphorIconsLight.pushPin),
                                    child: Text(alwaysOnTop
                                        ? LeapLocalizations.of(context)
                                            .exitAlwaysOnTop
                                        : LeapLocalizations.of(context)
                                            .alwaysOnTop),
                                    onPressed: () async {
                                      await windowManager
                                          .setAlwaysOnTop(!alwaysOnTop);
                                      setState(
                                          () => alwaysOnTop = !alwaysOnTop);
                                    },
                                  ),
                                  if (widget.fullScreenMode !=
                                      FullScreenMode.disabled)
                                    MenuItemButton(
                                      leadingIcon: PhosphorIcon(fullScreen
                                          ? PhosphorIconsLight.arrowsIn
                                          : PhosphorIconsLight.arrowsOut),
                                      child: Text(fullScreen
                                          ? LeapLocalizations.of(context)
                                              .exitFullScreen
                                          : LeapLocalizations.of(context)
                                              .fullScreen),
                                      onPressed: () {
                                        context
                                            .read<WindowCubit>()
                                            .toggleFullScreen();
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: Theme.of(context)
                                      .colorScheme
                                      .copyWith(
                                        secondaryContainer:
                                            Colors.red.withValues(alpha: 0.2),
                                      ),
                                ),
                                child: IconButton.filledTonal(
                                  icon:
                                      const PhosphorIcon(PhosphorIconsLight.x),
                                  tooltip: LeapLocalizations.of(context).close,
                                  color: Colors.red,
                                  splashRadius: 20,
                                  onPressed: () async {
                                    windowManager.close();
                                  },
                                ),
                              ),
                            ]
                          ]
                              .map((e) => e is SizedBox
                                  ? e
                                  : AspectRatio(aspectRatio: 1, child: e))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
          return Container();
        });
  }
}
