import 'dart:io';
import 'package:flutter_order_assets/pubspec_updater.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  late Directory tempDir;
  late File pubspecFile;

  setUp(() async {
    // Crear un directorio temporal para cada test
    tempDir = await Directory.systemTemp.createTemp('pubspec_updater_test_');
    pubspecFile = File('${tempDir.path}/pubspec.yaml');
  });

  tearDown(() async {
    // Limpiar después de cada test
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('mantiene archivos de audio en assets/ y archivos fuera de assets/ cuando excludeAudio es true', () {
    // Crear estructura de directorios
    final assetsDir = Directory('${tempDir.path}/assets');
    assetsDir.createSync(recursive: true);
    
    // Crear subdirectorios de imágenes
    Directory('${assetsDir.path}/images/png/onboarding').createSync(recursive: true);
    Directory('${assetsDir.path}/images/png/permisos').createSync(recursive: true);
    Directory('${assetsDir.path}/images/png/login').createSync(recursive: true);
    Directory('${assetsDir.path}/images/png/iconos').createSync(recursive: true);
    Directory('${assetsDir.path}/images/png/default').createSync(recursive: true);
    Directory('${assetsDir.path}/images/png/marca').createSync(recursive: true);
    Directory('${assetsDir.path}/images/svg').createSync(recursive: true);
    Directory('${assetsDir.path}/themes').createSync(recursive: true);
    Directory('${assetsDir.path}/fonts').createSync(recursive: true);

    // Crear archivos de audio directamente en assets/
    File('${assetsDir.path}/aceptoservicio.mp3').writeAsStringSync('dummy');
    File('${assetsDir.path}/encuentrarutas.mp3').writeAsStringSync('dummy');
    File('${assetsDir.path}/enviaoferta.mp3').writeAsStringSync('dummy');
    File('${assetsDir.path}/llegacontraoferta.mp3').writeAsStringSync('dummy');
    File('${assetsDir.path}/nohayrutas.mp3').writeAsStringSync('dummy');
    File('${assetsDir.path}/ofertarechazada.mp3').writeAsStringSync('dummy');

    // Crear archivo shorebird.yaml fuera de assets/
    File('${tempDir.path}/shorebird.yaml').writeAsStringSync('dummy');

    // Crear pubspec.yaml con la estructura inicial
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

    // Cambiar al directorio temporal para que el código funcione correctamente
    final originalDir = Directory.current;
    Directory.current = tempDir;

    try {
      // Crear el updater con excludeAudio = true (usar ruta relativa después de cambiar directorio)
      final updater = PubspecUpdater(
        File('pubspec.yaml'),
        excludeAudio: true,
      );
      updater.updateAssets();

      // Leer el pubspec actualizado
      final updatedContent = pubspecFile.readAsStringSync();
      final updatedYaml = loadYaml(updatedContent);
      final updatedAssets = (updatedYaml['flutter']['assets'] as List)
          .map((e) => e.toString())
          .toList();

      // Verificar que los archivos de audio en assets/ se mantienen
      expect(updatedAssets, contains('assets/aceptoservicio.mp3'));
      expect(updatedAssets, contains('assets/encuentrarutas.mp3'));
      expect(updatedAssets, contains('assets/enviaoferta.mp3'));
      expect(updatedAssets, contains('assets/llegacontraoferta.mp3'));
      expect(updatedAssets, contains('assets/nohayrutas.mp3'));
      expect(updatedAssets, contains('assets/ofertarechazada.mp3'));

      // Verificar que shorebird.yaml se mantiene
      expect(updatedAssets, contains('shorebird.yaml'));

      // Verificar que los directorios de imágenes se consolidan
      expect(updatedAssets, contains('assets/images/'));
      expect(updatedAssets, isNot(contains('assets/images/png/')));
      expect(updatedAssets, isNot(contains('assets/images/png/onboarding/')));

      // Verificar que fonts/ se mantiene
      expect(updatedAssets, contains('assets/fonts/'));

      // Verificar que themes/ no está (ya que no existe en la estructura final esperada)
      // Pero si existe el directorio, debería estar
      if (Directory('${assetsDir.path}/themes').existsSync()) {
        expect(updatedAssets, contains('assets/themes/'));
      }

      print('Assets actualizados:');
      for (final asset in updatedAssets) {
        print('  - $asset');
      }
    } finally {
      Directory.current = originalDir;
    }
  });

  test('no preserva archivos de audio cuando excludeAudio es false pero siempre mantiene assets fuera de assets/', () {
    // Crear estructura de directorios
    final assetsDir = Directory('${tempDir.path}/assets');
    assetsDir.createSync(recursive: true);
    Directory('${assetsDir.path}/images').createSync(recursive: true);

    // Crear archivo de audio directamente en assets/
    File('${assetsDir.path}/aceptoservicio.mp3').writeAsStringSync('dummy');

    // Crear pubspec.yaml con archivo de audio y un asset fuera de assets/
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
      // Crear el updater con excludeAudio = false (usar ruta relativa después de cambiar directorio)
      final updater = PubspecUpdater(
        File('pubspec.yaml'),
        excludeAudio: false,
      );
      updater.updateAssets();

      // Leer el pubspec actualizado
      final updatedContent = pubspecFile.readAsStringSync();
      final updatedYaml = loadYaml(updatedContent);
      final updatedAssets = (updatedYaml['flutter']['assets'] as List)
          .map((e) => e.toString())
          .toList();

      // Verificar que el archivo de audio NO se mantiene cuando excludeAudio es false
      expect(updatedAssets, isNot(contains('assets/aceptoservicio.mp3')));
      // Verificar que shorebird.yaml SÍ se mantiene aunque excludeAudio sea false
      expect(updatedAssets, contains('shorebird.yaml'));
    } finally {
      Directory.current = originalDir;
    }
  });
}
