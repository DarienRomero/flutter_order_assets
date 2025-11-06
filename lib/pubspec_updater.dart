import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

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