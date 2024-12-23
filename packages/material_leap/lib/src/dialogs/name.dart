import 'package:flutter/material.dart';
import 'package:lw_file_system_api/lw_file_system_api.dart';
import 'package:material_leap/l10n/leap_localizations.dart';

class NameDialog extends StatelessWidget {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final FormFieldValidator<String> Function(String?)? validator;
  final String? value, title, hint, button;
  final bool obscureText;

  NameDialog({
    super.key,
    this.validator,
    this.value,
    this.title,
    this.hint,
    this.button,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    String value = this.value ?? '';
    void submit() {
      if (_formKey.currentState!.validate()) {
        Navigator.of(context).pop(value);
      }
    }

    return Form(
      key: _formKey,
      child: AlertDialog(
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(MaterialLocalizations.of(context).cancelButtonLabel)),
          ElevatedButton(
              onPressed: submit,
              child: Text(button ?? LeapLocalizations.of(context).create)),
        ],
        title: Text(title ?? LeapLocalizations.of(context).enterName),
        content: TextFormField(
          decoration: InputDecoration(
            filled: true,
            hintText: hint ?? LeapLocalizations.of(context).name,
          ),
          autofocus: true,
          initialValue: value,
          onChanged: (e) => value = e,
          validator: validator?.call(value),
          onFieldSubmitted: (value) => submit(),
          obscureText: obscureText,
        ),
      ),
    );
  }
}

FormFieldValidator<String> Function(String?) defaultNameValidator(
    BuildContext context,
    [List<String> existingNames = const []]) {
  return (oldName) => (value) {
        if (value == null || value.isEmpty) {
          return LeapLocalizations.of(context).shouldNotEmpty;
        }
        if (value == oldName) return null;
        if (existingNames.contains(value)) {
          return LeapLocalizations.of(context).alreadyExists;
        }
        return null;
      };
}

FormFieldValidator<String> Function(String?) defaultFileNameValidator(
  BuildContext context, [
  List<String> existingNames = const [],
]) {
  final nameValidator = defaultNameValidator(context, existingNames);
  return (oldName) => (value) {
        final nameError = nameValidator(oldName)(value);
        if (nameError != null) return nameError;
        if (value == null || value.isEmpty) {
          return LeapLocalizations.of(context).shouldNotEmpty;
        }
        if (hasInvalidFileName(value)) {
          return LeapLocalizations.of(context).invalidName;
        }
        return null;
      };
}
