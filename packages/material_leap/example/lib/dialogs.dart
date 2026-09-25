import 'package:material_leap/material_leap.dart';
import 'package:material_ui/material_ui.dart';

class DialogsView extends StatefulWidget {
  const DialogsView({super.key});

  @override
  State<DialogsView> createState() => _DialogsViewState();
}

class _DialogsViewState extends State<DialogsView> {
  SRGBColor color = SRGBColor.blue;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Dialogs and sheets',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => ColorPicker<void>.native(
                        primaryActions: (close) => [
                          TextButton(
                              onPressed: () => close(null),
                              child: const Text('Done')),
                        ],
                        suggested: const [
                          Colors.white,
                          Colors.red,
                          Colors.orange,
                          Colors.yellow,
                          Colors.green,
                          Colors.blue,
                          Colors.purple,
                          Colors.black,
                        ],
                      ),
                    ),
                    child: const Text('ColorPicker'),
                  ),
                  OutlinedButton(
                    onPressed: () => showDialog<String>(
                      context: context,
                      builder: (context) => NameDialog(
                        title: 'NameDialog',
                        hint: 'Enter a name',
                        validator: defaultNameValidator(context),
                      ),
                    ),
                    child: const Text('NameDialog'),
                  ),
                  OutlinedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => ResponsiveDialog(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('ResponsiveDialog'),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: const Text('ResponsiveDialog'),
                  ),
                  OutlinedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (context) => ResponsiveAlertDialog(
                        title: const Text('ResponsiveAlertDialog'),
                        content: const Text(
                            'This dialog adapts to the available width.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                    child: const Text('ResponsiveAlertDialog'),
                  ),
                  OutlinedButton(
                    onPressed: () => showLeapBottomSheet<void>(
                      context: context,
                      titleBuilder: (context) =>
                          const Text('Leap bottom sheet'),
                      childrenBuilder: (context) => [
                        const ListTile(title: Text('showLeapBottomSheet')),
                        ListTile(
                          title: const Text('Close'),
                          onTap: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    child: const Text('Bottom sheet'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('ColorWheelPicker',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 240,
                  height: 300,
                  child: ColorWheelPicker(
                    value: color,
                    onChanged: (value) => setState(() => color = value),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
