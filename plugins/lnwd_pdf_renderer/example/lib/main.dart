import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:lnwd_pdf_renderer/lnwd_pdf_renderer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  PdfDocument? document;
  final _lnwdPdfRendererPlugin = LnwdPdfRenderer();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: ListView(children: [
          ElevatedButton(
            child: const Text('Render from clipboard'),
            onPressed: () async {
              final data = await Clipboard.getData('text/plain')
                  .then((value) => value?.text);
              if (data != null) {
                await _lnwdPdfRendererPlugin
                    .render(Uint8List.fromList(base64.decode(data)))
                    .then((value) => setState(() => document = value));
              }
              if (kDebugMode) {
                print('Rendered ${document?.pages.length} pages');
              }
            },
          ),
          if (document != null) ...[
            const Divider(),
            Text('Pages: ${document!.pages.length}'),
            const Divider(),
            ...document!.pages.map((page) {
              return Column(
                children: [
                  Text('Page: ${page.width}x${page.height}'),
                  const Divider(),
                  Image.memory(page.data),
                ],
              );
            }),
          ]
        ]),
      ),
    );
  }
}
