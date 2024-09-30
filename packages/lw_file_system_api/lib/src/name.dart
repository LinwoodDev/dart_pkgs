import 'package:path/path.dart' as p;

const invalidFileName = r'[\\/:\*\?"<>\|\n\0-\x1F\x7F-\xFF]';

String convertNameToFile({
  String? name,
  String? suffix,
  String? directory,
  required String Function() getUnnamed,
}) {
  name ??= '';
  suffix ??= '';
  directory ??= '';
  if (name.isEmpty) {
    name = getUnnamed();
  }
  name = name.replaceAll(invalidFileName, '_');
  return p.join(directory, '$name$suffix');
}

bool hasInvalidFileName(String name) => RegExp(invalidFileName).hasMatch(name);

String unnamedStatic() => 'Unnamed';
String unnamedDate() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}
