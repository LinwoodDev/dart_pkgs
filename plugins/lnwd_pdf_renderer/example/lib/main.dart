import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

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
  final TextEditingController _dataController = TextEditingController();
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
          TextField(
            controller: _dataController,
            decoration: const InputDecoration(
                hintText: 'Enter data', labelText: 'Base64 encoded data'),
          ),
          ElevatedButton(
            child: const Text('Render'),
            onPressed: () async {
              final data = _dataController.text;
              document = await _lnwdPdfRendererPlugin
                  .render(Uint8List.fromList(base64.decode(data)));
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
