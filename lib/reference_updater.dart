import 'dart:io';
import 'package:path/path.dart' as p;

class ReferenceUpdater {
  void updateReferences(Map<String, String> movedPaths) {
    final libDir = Directory('lib');

    for (final file in libDir.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;

      var content = file.readAsStringSync();
      bool changed = false;

      movedPaths.forEach((old, newPath) {
        if (content.contains(old)) {
          print(file.path);
          content = content.replaceAll(old, newPath);
          changed = true;
        }
      });

      if (changed) {
        file.writeAsStringSync(content);
      }
    }
  }
}