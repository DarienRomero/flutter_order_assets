import 'dart:io';
import 'package:path/path.dart' as path;

class AssetSorter {
  final Directory assetsDir;

  AssetSorter(this.assetsDir);

  final Map<String, List<String>> _groups = {
    'icons': ['.svg', '.ico'],
    'images': ['.png', '.jpg', '.jpeg', '.webp', '.bmp', '.gif'],
    'fonts': ['.otf', '.ttf', '.woff', '.woff2'],
    'audio': ['.mp3', '.wav', '.ogg', '.m4a', '.aac'],
    'videos': ['.mp4', '.mov', '.avi', '.webm', '.mkv', '.flv'],
    'animations': ['.json', '.riv', '.flr'],
    'data': ['.json', '.yaml', '.yml', '.xml', '.csv'],
    'env': ['.env'],
    'models': ['.obj', '.fbx', '.glb', '.gltf', '.stl'],
    'docs': ['.txt', '.md', '.pdf', '.docx'],
    'textures': ['.atlas', '.ktx', '.dds', '.tga'],
    'misc': [],
  };

  Future<Map<String, String>> sort() async {
    // --- 1️⃣ Mover archivos según la extensión ---
    final movedPaths = <String, String>{};
    for (final entity in assetsDir.listSync(recursive: true)) {
      if (entity is! File) continue;

      final ext = path.extension(entity.path).toLowerCase();
      String targetFolder = 'misc';

      _groups.forEach((folder, exts) {
        if (exts.contains(ext)) targetFolder = folder;
      });

      final newDir = Directory(path.join(assetsDir.path, targetFolder));
      if (!newDir.existsSync()) newDir.createSync(recursive: true);

      final newPath = path.join(newDir.path, path.basename(entity.path));
      if (entity.path != newPath) {
        final oldPath = entity.path;
        entity.renameSync(newPath);
        movedPaths[oldPath] = newPath;
      }
    }


    // --- 2️⃣ Eliminar carpetas que no son de primer nivel válidas ---
    final validFolders = _groups.keys.toSet();

    for (final entity in assetsDir.listSync()) {
      if (entity is Directory) {
        final folderName = path.basename(entity.path);

        // Si no está en las carpetas válidas → eliminarla
        if (!validFolders.contains(folderName)) {
          entity.deleteSync(recursive: true);
          print('🗑️ Carpeta eliminada: $folderName');
        } else {
          // Si es válida, borrar subcarpetas dentro de ella
          for (final sub in entity.listSync()) {
            if (sub is Directory) {
              sub.deleteSync(recursive: true);
              print('🧹 Subcarpeta eliminada: ${sub.path}');
            }
          }
        }
      }
    }

    return movedPaths;
  }
}
