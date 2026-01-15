import 'dart:io';
import 'package:flutter_order_assets/pubspec_updater.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  late Directory tempDir;
  late File pubspecFile;

  setUp(() async {
    // Create a temporary directory for each test
    tempDir = await Directory.systemTemp.createTemp('pubspec_updater_test_');
    pubspecFile = File('${tempDir.path}/pubspec.yaml');
  });

  tearDown(() async {
    // Clean up after each test
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('preserves audio files in assets/ and files outside assets/ when excludeAudio is true', () {
    // Create directory structure
    final assetsDir = Directory('${tempDir.path}/assets');
    assetsDir.createSync(recursive: true);
    
    // Create image subdirectories
    Directory('${assetsDir.path}/images/png/onboarding').createSync(recursive: true);
    Directory('${assetsDir.path}/images/png/permisos').createSync(recursive: true);
    Directory('${assetsDir.path}/images/png/login').createSync(recursive: true);
    Directory('${assetsDir.path}/images/png/iconos').createSync(recursive: true);
    Directory('${assetsDir.path}/images/png/default').createSync(recursive: true);
    Directory('${assetsDir.path}/images/png/marca').createSync(recursive: true);
    Directory('${assetsDir.path}/images/svg').createSync(recursive: true);
    Directory('${assetsDir.path}/themes').createSync(recursive: true);
    Directory('${assetsDir.path}/fonts').createSync(recursive: true);

    // Create audio files directly in assets/
    File('${assetsDir.path}/aceptoservicio.mp3').writeAsStringSync('dummy');
    File('${assetsDir.path}/encuentrarutas.mp3').writeAsStringSync('dummy');
    File('${assetsDir.path}/enviaoferta.mp3').writeAsStringSync('dummy');
    File('${assetsDir.path}/llegacontraoferta.mp3').writeAsStringSync('dummy');
    File('${assetsDir.path}/nohayrutas.mp3').writeAsStringSync('dummy');
    File('${assetsDir.path}/ofertarechazada.mp3').writeAsStringSync('dummy');

    // Create shorebird.yaml file outside assets/
    File('${tempDir.path}/shorebird.yaml').writeAsStringSync('dummy');

    // Create pubspec.yaml with initial structure
    final initialPubspec = '''
name: test_app
version: 1.0.0

flutter:
  assets:
    - assets/
    - assets/images/png/
    - assets/images/png/onboarding/
    - assets/images/png/permisos/
    - assets/images/png/login/
    - assets/images/png/iconos/
    - assets/images/png/default/
    - assets/images/png/marca/
    - assets/images/svg/
    - assets/aceptoservicio.mp3
    - assets/encuentrarutas.mp3
    - assets/enviaoferta.mp3
    - assets/llegacontraoferta.mp3
    - assets/nohayrutas.mp3
    - assets/ofertarechazada.mp3
    - assets/themes/
    - shorebird.yaml
''';

    pubspecFile.writeAsStringSync(initialPubspec);

    // Change to temporary directory so the code works correctly
    final originalDir = Directory.current;
    Directory.current = tempDir;

    try {
      // Create the updater with excludeAudio = true (use relative path after changing directory)
      final updater = PubspecUpdater(
        pubspecFile,
        excludeAudio: true,
      );
      updater.updateAssets();

      // Read the updated pubspec
      final updatedContent = pubspecFile.readAsStringSync();
      print("updatedContent");
      print(updatedContent);
      final updatedYaml = loadYaml(updatedContent);
      final updatedAssets = (updatedYaml['flutter']['assets'] as List)
          .map((e) => e.toString())
          .toList();

      // Verify that audio files in assets/ are preserved
      expect(updatedAssets, contains('assets/aceptoservicio.mp3'));
      expect(updatedAssets, contains('assets/encuentrarutas.mp3'));
      expect(updatedAssets, contains('assets/enviaoferta.mp3'));
      expect(updatedAssets, contains('assets/llegacontraoferta.mp3'));
      expect(updatedAssets, contains('assets/nohayrutas.mp3'));
      expect(updatedAssets, contains('assets/ofertarechazada.mp3'));

      // Verify that shorebird.yaml is preserved
      expect(updatedAssets, contains('shorebird.yaml'));

      // Verify that image directories are consolidated
      expect(updatedAssets, contains('assets/images/'));
      expect(updatedAssets, isNot(contains('assets/images/png/')));
      expect(updatedAssets, isNot(contains('assets/images/png/onboarding/')));

      // Verify that fonts/ is preserved
      expect(updatedAssets, contains('assets/fonts/'));

      // Verify that themes/ is not present (since it doesn't exist in the expected final structure)
      // But if the directory exists, it should be present
      if (Directory('${assetsDir.path}/themes').existsSync()) {
        expect(updatedAssets, contains('assets/themes/'));
      }
    } finally {
      Directory.current = originalDir;
    }
  });

  test('does not preserve audio files when excludeAudio is false but always keeps assets outside assets/', () {
    // Create directory structure
    final assetsDir = Directory('${tempDir.path}/assets');
    assetsDir.createSync(recursive: true);
    Directory('${assetsDir.path}/images').createSync(recursive: true);

    // Create audio file directly in assets/
    File('${assetsDir.path}/aceptoservicio.mp3').writeAsStringSync('dummy');

    // Create pubspec.yaml with audio file and an asset outside assets/
    final initialPubspec = '''
name: test_app
version: 1.0.0

flutter:
  assets:
    - assets/images/
    - assets/aceptoservicio.mp3
    - shorebird.yaml
''';

    pubspecFile.writeAsStringSync(initialPubspec);

    final originalDir = Directory.current;
    Directory.current = tempDir;

    try {
      // Create the updater with excludeAudio = false (use relative path after changing directory)
      final updater = PubspecUpdater(
        File('pubspec.yaml'),
        excludeAudio: false,
      );
      updater.updateAssets();

      // Read the updated pubspec
      final updatedContent = pubspecFile.readAsStringSync();
      final updatedYaml = loadYaml(updatedContent);
      final updatedAssets = (updatedYaml['flutter']['assets'] as List)
          .map((e) => e.toString())
          .toList();

      // Verify that the audio file is NOT preserved when excludeAudio is false
      expect(updatedAssets, isNot(contains('assets/aceptoservicio.mp3')));
      // Verify that shorebird.yaml IS preserved even if excludeAudio is false
      expect(updatedAssets, contains('shorebird.yaml'));
    } finally {
      Directory.current = originalDir;
    }
  });

  test('updateFonts: success case - updates references when files are in assets/fonts/', () {
    // Create directory structure
    final assetsDir = Directory('${tempDir.path}/assets');
    assetsDir.createSync(recursive: true);
    final fontsDir = Directory('${assetsDir.path}/fonts');
    fontsDir.createSync(recursive: true);

    // Create font files in assets/fonts/
    File('${fontsDir.path}/ClanOT-Black.otf').writeAsStringSync('dummy');
    File('${fontsDir.path}/ClanOT-Bold.otf').writeAsStringSync('dummy');
    File('${fontsDir.path}/Roboto-Regular.ttf').writeAsStringSync('dummy');

    // Create pubspec.yaml with fonts pointing to old paths
    final initialPubspec = '''
name: test_app
version: 1.0.0

flutter:
  assets:
    - assets/fonts/
  fonts:
    - family: Clan
      fonts:
        - asset: assets/fuentes/CCC/ClanOT-Black.otf
        - asset: assets/fuentes/CCC/ClanOT-Bold.otf
    - family: Roboto
      fonts:
        - asset: assets/fonts/old/Roboto-Regular.ttf
''';

    pubspecFile.writeAsStringSync(initialPubspec);

    final originalDir = Directory.current;
    Directory.current = tempDir;

    try {
      final updater = PubspecUpdater(File('pubspec.yaml'));
      updater.updateAssets();

      // Leer el pubspec actualizado
      final updatedContent = pubspecFile.readAsStringSync();
      final updatedYaml = loadYaml(updatedContent);
      final fontsList = updatedYaml['flutter']['fonts'] as List;

      // Verify that paths were updated correctly
      final clanFamily = fontsList[0] as Map;
      final clanFonts = clanFamily['fonts'] as List;
      expect(clanFonts[0]['asset'].toString(), equals('assets/fonts/ClanOT-Black.otf'));
      expect(clanFonts[1]['asset'].toString(), equals('assets/fonts/ClanOT-Bold.otf'));

      final robotoFamily = fontsList[1] as Map;
      final robotoFonts = robotoFamily['fonts'] as List;
      expect(robotoFonts[0]['asset'].toString(), equals('assets/fonts/Roboto-Regular.ttf'));
    } finally {
      Directory.current = originalDir;
    }
  });

  test('updateFonts: more files than declarations - only updates matching ones', () {
    // Create directory structure
    final assetsDir = Directory('${tempDir.path}/assets');
    assetsDir.createSync(recursive: true);
    final fontsDir = Directory('${assetsDir.path}/fonts');
    fontsDir.createSync(recursive: true);

    // Create more font files than are declared
    File('${fontsDir.path}/ClanOT-Black.otf').writeAsStringSync('dummy');
    File('${fontsDir.path}/ClanOT-Bold.otf').writeAsStringSync('dummy');
      File('${fontsDir.path}/ClanOT-Light.otf').writeAsStringSync('dummy'); // Not declared
    File('${fontsDir.path}/Roboto-Regular.ttf').writeAsStringSync('dummy');
      File('${fontsDir.path}/Roboto-Bold.ttf').writeAsStringSync('dummy'); // Not declared

    // Create pubspec.yaml with only some fonts declared
    final initialPubspec = '''
name: test_app
version: 1.0.0

flutter:
  assets:
    - assets/fonts/
  fonts:
    - family: Clan
      fonts:
        - asset: assets/fuentes/CCC/ClanOT-Black.otf
        - asset: assets/fuentes/CCC/ClanOT-Bold.otf
    - family: Roboto
      fonts:
        - asset: assets/fonts/old/Roboto-Regular.ttf
''';

    pubspecFile.writeAsStringSync(initialPubspec);

    final originalDir = Directory.current;
    Directory.current = tempDir;

    try {
      final updater = PubspecUpdater(File('pubspec.yaml'));
      updater.updateAssets();

      // Read the updated pubspec
      final updatedContent = pubspecFile.readAsStringSync();
      final updatedYaml = loadYaml(updatedContent);
      final fontsList = updatedYaml['flutter']['fonts'] as List;

      // Verify that only declared fonts were updated
      final clanFamily = fontsList[0] as Map;
      final clanFonts = clanFamily['fonts'] as List;
      expect(clanFonts.length, equals(2)); // Only 2 declared
      expect(clanFonts[0]['asset'].toString(), equals('assets/fonts/ClanOT-Black.otf'));
      expect(clanFonts[1]['asset'].toString(), equals('assets/fonts/ClanOT-Bold.otf'));

      final robotoFamily = fontsList[1] as Map;
      final robotoFonts = robotoFamily['fonts'] as List;
      expect(robotoFonts.length, equals(1)); // Only 1 declared
      expect(robotoFonts[0]['asset'].toString(), equals('assets/fonts/Roboto-Regular.ttf'));

      // Verify that extra files were not automatically added
      final clanFontAssets = clanFonts.map((f) => f['asset'].toString()).toList();
      expect(clanFontAssets, isNot(contains('assets/fonts/ClanOT-Light.otf')));
      
      final robotoFontAssets = robotoFonts.map((f) => f['asset'].toString()).toList();
      expect(robotoFontAssets, isNot(contains('assets/fonts/Roboto-Bold.ttf')));
    } finally {
      Directory.current = originalDir;
    }
  });

  test('updateFonts: fewer files than declarations - only updates existing ones', () {
    // Create directory structure
    final assetsDir = Directory('${tempDir.path}/assets');
    assetsDir.createSync(recursive: true);
    final fontsDir = Directory('${assetsDir.path}/fonts');
    fontsDir.createSync(recursive: true);

    // Create fewer font files than are declared
    File('${fontsDir.path}/ClanOT-Black.otf').writeAsStringSync('dummy');
    // ClanOT-Bold.otf does NOT exist in assets/fonts/
    File('${fontsDir.path}/Roboto-Regular.ttf').writeAsStringSync('dummy');
    // Roboto-Bold.ttf does NOT exist in assets/fonts/

    // Create pubspec.yaml with more fonts declared than exist
    final initialPubspec = '''
name: test_app
version: 1.0.0

flutter:
  assets:
    - assets/fonts/
  fonts:
    - family: Clan
      fonts:
        - asset: assets/fuentes/CCC/ClanOT-Black.otf
        - asset: assets/fuentes/CCC/ClanOT-Bold.otf
    - family: Roboto
      fonts:
        - asset: assets/fonts/old/Roboto-Regular.ttf
        - asset: assets/fonts/old/Roboto-Bold.ttf
''';

    pubspecFile.writeAsStringSync(initialPubspec);

    final originalDir = Directory.current;
    Directory.current = tempDir;

    try {
      final updater = PubspecUpdater(File('pubspec.yaml'));
      updater.updateAssets();

      // Read the updated pubspec
      final updatedContent = pubspecFile.readAsStringSync();
      final updatedYaml = loadYaml(updatedContent);
      final fontsList = updatedYaml['flutter']['fonts'] as List;

      // Verify that only existing fonts were updated
      final clanFamily = fontsList[0] as Map;
      final clanFonts = clanFamily['fonts'] as List;
      expect(clanFonts.length, equals(2)); // Keeps both declarations
      expect(clanFonts[0]['asset'].toString(), equals('assets/fonts/ClanOT-Black.otf')); // Updated
      expect(clanFonts[1]['asset'].toString(), equals('assets/fuentes/CCC/ClanOT-Bold.otf')); // Not updated (doesn't exist)

      final robotoFamily = fontsList[1] as Map;
      final robotoFonts = robotoFamily['fonts'] as List;
      expect(robotoFonts.length, equals(2)); // Keeps both declarations
      expect(robotoFonts[0]['asset'].toString(), equals('assets/fonts/Roboto-Regular.ttf')); // Updated
      expect(robotoFonts[1]['asset'].toString(), equals('assets/fonts/old/Roboto-Bold.ttf')); // Not updated (doesn't exist)
    } finally {
      Directory.current = originalDir;
    }
  });
}
