import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:material_leap/material_leap.dart';

class WidgetsView extends StatelessWidget {
  const WidgetsView({super.key});

  @override
  Widget build(BuildContext context) {
    var currentValue = false;
    return Column(
      children: [
        Text("Widgets", style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Text("Exact Slider", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const ExactSlider(
          header: Text("Slider Header"),
        ),
        const SizedBox(height: 8),
        Text("Advanced switch list tile",
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        StatefulBuilder(
            builder: (context, setState) => AdvancedSwitchListTile(
                  title: const Text("Switch List Tile"),
                  value: currentValue,
                  onTap: () {
                    if (kDebugMode) {
                      print("onTap");
                    }
                  },
                  onChanged: (value) {
                    if (kDebugMode) {
                      print("onChanged");
                    }
                    setState(() {
                      currentValue = value;
                    });
                  },
                )),
        const SizedBox(height: 8),
        Text("Date time field",
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        DateTimeField(
          label: 'Date Time Field Label',
          onChanged: (value) {
            if (kDebugMode) {
              print('Date time changed: $value');
            }
          },
        ),
      ],
    );
  }
}
