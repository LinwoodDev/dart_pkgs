import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_onenote/flutter_onenote.dart';

Future<void> main() async {
  await RustLib.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _pathController = TextEditingController();
  Future<OneNoteSection>? _section;

  Future<OneNoteSection> _loadSection(String fileName) async {
    final data = await File(fileName).readAsBytes();
    return parseOneNote(data: data);
  }

  @override
  void dispose() {
    super.dispose();
    _pathController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('flutter_rust_bridge quickstart')),
        body: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pathController,
                    decoration: const InputDecoration(
                      labelText: 'Path to file',
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _section = _loadSection(_pathController.text);
                    });
                  },
                  child: const Text('Load'),
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<OneNoteSection>(
                future: _section,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: Text('No data'));
                  }

                  final section = snapshot.data!;
                  return ListView(
                    children: [
                      ListTile(
                        title: const Text('Title'),
                        subtitle: Text(section.toString()),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
