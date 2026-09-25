import 'package:material_leap/material_leap.dart';
import 'package:material_ui/material_ui.dart';

class WidgetsView extends StatefulWidget {
  const WidgetsView({super.key});

  @override
  State<WidgetsView> createState() => _WidgetsViewState();
}

class _WidgetsViewState extends State<WidgetsView> {
  double number = 5, slider = 2.5, stepper = 4;
  bool enabled = true, selected = false;
  Offset offset = const Offset(12, 24);
  DateTime? date;
  Color color = Colors.blue;

  Widget section(String title, List<Widget> children) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Widgets', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          section('Numbers', [
            const Text(
                'Arrow keys and the mouse wheel step the field. Shift uses 5× steps, Alt uses 0.1× steps, and Ctrl-drag scrubs.'),
            const SizedBox(height: 16),
            const Text('NumberInput'),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 220,
                child: NumberInput(
                  value: number,
                  min: 0,
                  max: 20,
                  onChanged: (value) => setState(() => number = value),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ExactSlider(
              header: const Text('ExactSlider'),
              subtitle: const Text(
                  'The slider snaps; the field keeps precise values.'),
              value: slider,
              min: 0,
              max: 10,
              sliderStep: 1,
              onChanged: (value) => setState(() => slider = value),
            ),
            const SizedBox(height: 16),
            InputStepper(
              title: const Text('InputStepper'),
              subtitle: const Text('A field with reset and step controls.'),
              value: stepper,
              min: 0,
              max: 10,
              defaultValue: 4,
              onChanged: (value) => setState(() => stepper = value),
            ),
          ]),
          section('Fields', [
            AdvancedTextField(
              label: 'AdvancedTextField',
              initialValue: 'Editable text',
              resetValue: 'Reset text',
            ),
            const SizedBox(height: 16),
            DateTimeField(
              label: 'DateTimeField',
              initialValue: date,
              canBeEmpty: true,
              onChanged: (value) => setState(() => date = value),
            ),
            OffsetListTile(
              title: const Text('OffsetListTile'),
              value: offset,
              onChanged: (value) => setState(() => offset = value),
            ),
          ]),
          section('Selection', [
            AdvancedSwitchListTile(
              title: const Text('AdvancedSwitchListTile'),
              subtitle:
                  const Text('The tile and switch have separate actions.'),
              value: enabled,
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tile action selected')),
              ),
              onChanged: (value) => setState(() => enabled = value),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                BoxTile(
                  title: const Text('BoxTile'),
                  subtitle: const Text('Tap to select'),
                  icon: const Icon(Icons.widgets_outlined),
                  selected: selected,
                  onTap: () => setState(() => selected = !selected),
                ),
                ColorButton(
                  color: color,
                  size: 72,
                  selected: true,
                  onTap: () => setState(() => color =
                      color == Colors.blue ? Colors.orange : Colors.blue),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('ThemeBox'),
                    ThemeBox(theme: Theme.of(context)),
                  ],
                ),
              ],
            ),
          ]),
          section('Navigation and menus', [
            Header(
              leading: const Icon(Icons.dashboard_outlined),
              title: const Text('Header'),
              actions: [
                IconButton(
                  onPressed: () {},
                  tooltip: 'Example action',
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const DefaultTabController(
              length: 2,
              child: TabBar(
                tabs: [
                  HorizontalTab(
                      icon: Icon(Icons.home_outlined), label: Text('Home')),
                  HorizontalTab(
                      icon: Icon(Icons.settings_outlined),
                      label: Text('Settings')),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ContextRegion(
              tooltip: 'Open example menu',
              menuChildren: [
                MenuItemButton(
                    onPressed: () {}, child: const Text('First action')),
                MenuItemButton(
                    onPressed: () {}, child: const Text('Second action')),
              ],
              builder: (context, button, controller) => Row(
                children: [
                  const Expanded(
                      child: Text('ContextRegion: click or right-click')),
                  button,
                ],
              ),
            ),
          ]),
        ],
      );
}
