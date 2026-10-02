import 'package:lw_file_system_api/lw_file_system_api.dart';
import 'package:test/test.dart';

void main() {
  test('filename separators and reserved characters are sanitized', () {
    expect(
      convertNameToFile(
        name: r'a/b\c:d?e',
        suffix: '.bfly',
        directory: '/notes',
        getUnnamed: () => 'unnamed',
      ),
      '/notes/a_b_c_d_e.bfly',
    );
  });
  test('absolute local paths override the base, including Windows paths', () {
    expect(
      const LocalStorage(
        paths: {'': '/base', 'documents': '/other'},
      ).getFullPath('documents'),
      '/other',
    );
    expect(
      const LocalStorage(
        paths: {'': r'C:\base', 'documents': r'D:\notes'},
      ).getFullPath('documents'),
      'D:/notes',
    );
    expect(
      const LocalStorage(
        paths: {'': r'C:\base', 'documents': 'Documents'},
      ).getFullPath('documents'),
      'C:/base/Documents',
    );
  });
  test('absolute locations survive serialization and navigation', () {
    final location = AssetLocation.local('/mnt/notes/note.bfly', true);
    expect(AssetLocationMapper.fromJson(location.toJson()), location);
    expect(location.buildParentLocation().absolute, isTrue);
    expect(location.buildSiblingLocation('other.bfly').absolute, isTrue);
    expect(location.copyWith(path: '/mnt/notes/other.bfly').absolute, isTrue);
    expect(
      AssetLocationMapper.fromMap({'path': '/note.bfly'}).absolute,
      isFalse,
    );
  });
}
