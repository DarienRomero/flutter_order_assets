import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Esta clase se encarga de actualizar la sección de assets en el archivo pubspec.yaml.
/// Escanea el directorio 'assets' de forma recursiva para recopilar todas las carpetas de activos,
/// y actualiza el pubspec.yaml para incluir estas rutas en la configuración de Flutter.
class PubspecUpdater {
  final File pubspecFile;

  PubspecUpdater(this.pubspecFile);

  void updateAssets() {
    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content);
    final editor = YamlEditor(content);

    final assetsDir = Directory('assets');

    final allAssets = assetsDir
        .listSync(recursive: true)
        .whereType<Directory>()
        .map((f) => "${f.path.replaceAll('\\', '/')}/")
        .toList()
        ..sort();

    print("allAssets");
    print(allAssets);
    if (yaml['flutter'] == null) {
      editor.update(['flutter'], {'assets': allAssets});
    } else if (yaml['flutter']['assets'] != null) {
      editor.update(['flutter', 'assets'], allAssets);
    } else {
      editor.update(['flutter'], {'assets': allAssets});
    }

    pubspecFile.writeAsStringSync(editor.toString());
    print('✅ pubspec.yaml actualizado con ${allAssets.length} assets');
  }
}