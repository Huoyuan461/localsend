import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:zhichuan_app/util/shared_preferences/shared_preferences_portable.dart';

void main() {
  test('should put settings.json next to the executable', () {
    expect(
      buildSettingsPath(
        executablePath: path.join('opt', 'zhichuan', 'zhichuan_app'),
        fallbackDirectory: () => fail(
          'The fallback should not be used when the executable is known',
        ),
      ),
      path.join('opt', 'zhichuan', 'settings.json'),
    );
  });

  test(
    'should fall back to the working directory when the executable is unknown',
    () {
      // https://github.com/Huoyuan461/localsend/issues/3021
      expect(
        buildSettingsPath(
          executablePath: null,
          fallbackDirectory: () => path.join('home', 'user'),
        ),
        path.join('home', 'user', 'settings.json'),
      );
    },
  );
}
