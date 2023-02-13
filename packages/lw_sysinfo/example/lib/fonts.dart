import 'package:flutter/material.dart';

import 'package:lw_sysinfo/lw_sysinfo.dart';

class FontsPage extends StatefulWidget {
  const FontsPage({super.key});

  @override
  State<FontsPage> createState() => _FontsPageState();
}

class _FontsPageState extends State<FontsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fonts'),
      ),
      body: FutureBuilder<List<String>?>(
        future: Future.value(SysInfo.getFonts()),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final fonts = List<String>.from(snapshot.data!);
            fonts.sort();
            return ListView.builder(
                itemCount: fonts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(fonts[index]),
                  );
                });
          } else {
            return const Text('Loading...');
          }
        },
      ),
    );
  }
}
