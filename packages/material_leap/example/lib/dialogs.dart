import 'package:flutter/material.dart';
import 'package:material_leap/material_leap.dart';

class DialogsView extends StatelessWidget {
  const DialogsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Dialogs", style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        ElevatedButton(
            onPressed: () => showDialog(
                  context: context,
                  builder: (context) => ColorPicker<void>(
                    primaryActions: (close) => [
                      TextButton(
                        child: const Text("Primary Action"),
                        onPressed: () => close(null),
                      )
                    ],
                    secondaryActions: (close) => [
                      TextButton(
                        child: const Text("Secondary Action"),
                        onPressed: () => close(null),
                      )
                    ],
                    suggested: const [
                      Colors.white,
                      Colors.red,
                      Colors.orange,
                      Colors.amber,
                      Colors.yellow,
                      Colors.green,
                      Colors.teal,
                      Colors.blue,
                      Colors.purple,
                      Colors.black,
                    ],
                  ),
                ),
            child: const Text("Color picker"))
      ],
    );
  }
}
