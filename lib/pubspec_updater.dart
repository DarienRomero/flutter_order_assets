import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';
import 'package:path/path.dart' as p;

class PubspecUpdater {
  final File pubspecFile;

  PubspecUpdater(this.pubspecFile);

  void updateAssets() {
    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content);
    final editor = YamlEditor(content);

    final assetsDir = Directory('assets');
    if (!assetsDir.existsSync()) return;

    final allAssets = assetsDir
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => p.relative(f.path))
        .toList()
      ..sort();

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