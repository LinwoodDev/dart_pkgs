import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_leap/material_leap.dart';
import 'package:window_manager/window_manager.dart';

import 'dialogs.dart';
import 'widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (isWindow) {
    await windowManager.ensureInitialized();
    await windowManager.setTitleBarStyle(TitleBarStyle.hidden);
  }
  runApp(const MyApp());
}

class DummySettings with LeapSettings {
  @override
  final bool nativeTitleBar;

  const DummySettings({this.nativeTitleBar = false});
}

class DummySettingsCubit extends Cubit<DummySettings>
    with LeapSettingsBlocBaseMixin<DummySettings> {
  DummySettingsCubit() : super(const DummySettings());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => DummySettingsCubit()),
        if (isWindow)
          BlocProvider(create: (context) => WindowCubit(fullScreen: false)),
      ],
      child: MaterialApp(
        title: 'Material Leap Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: _themeMode,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          LeapLocalizations.delegate,
        ],
        supportedLocales: LeapLocalizations.supportedLocales,
        home: Scaffold(
          appBar: WindowTitleBar<DummySettingsCubit, DummySettings>(
            title: const Text('Material Leap Demo'),
            actions: [
              IconButton(
                onPressed: () => setState(() => _themeMode =
                    ThemeMode.light == _themeMode
                        ? ThemeMode.dark
                        : ThemeMode.light),
                tooltip: _themeMode == ThemeMode.light
                    ? 'Use dark theme'
                    : 'Use light theme',
                icon: _themeMode == ThemeMode.light
                    ? const Icon(Icons.dark_mode)
                    : const Icon(Icons.light_mode),
              ),
            ],
          ),
          body: ListView(
            children: const [
              DialogsView(),
              WidgetsView(),
            ],
          ),
        ),
      ),
    );
  }
}
