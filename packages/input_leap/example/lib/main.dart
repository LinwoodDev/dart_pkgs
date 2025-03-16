import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Object? _event;

  void _changeEvent(PointerEvent event) {
    setState(() {
      _event =
          "${event.runtimeType}: ${event.position} / ${event.buttons} / ${event.pressure}"
          " / ${event.pressureMin} / ${event.pressureMax} / ${event.distance} / ${event.distanceMax} / ${event.size} / ${event.kind}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: Listener(
          onPointerDown: _changeEvent,
          onPointerMove: _changeEvent,
          onPointerUp: _changeEvent,
          behavior: HitTestBehavior.opaque,
          child: SizedBox.expand(
            child: Stack(children: [Center(child: Text('$_event'))]),
          ),
        ),
      ),
    );
  }
}
