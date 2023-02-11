import 'package:flutter/material.dart';

import 'package:lw_sysinfo/lw_sysinfo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          appBar: AppBar(
            title: const Text('Plugin example app'),
          ),
          body: ListView(
            children: [
              ListTile(
                title: const Text('Fonts'),
                subtitle: FutureBuilder<List<String>?>(
                    future: Future.value(SysInfo.getFonts()),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                            "(${snapshot.data!.length}) ${snapshot.data!.join(', ')}");
                      } else {
                        return const Text('Loading...');
                      }
                    }),
              ),
            ],
          )),
    );
  }
}
