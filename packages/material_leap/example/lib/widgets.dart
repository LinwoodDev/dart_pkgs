import 'package:flutter/material.dart';
import 'package:material_leap/material_leap.dart';

class WidgetsView extends StatelessWidget {
  const WidgetsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Widgets", style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        Text("Exact Slider", style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const ExactSlider(
          header: Text("Slider Header"),
        ),
      ],
    );
  }
}
