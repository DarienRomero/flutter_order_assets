import 'dart:io';
import 'package:path/path.dart' as path;

/// Esta clase se encarga de organizar los activos en el directorio de assets.
/// Clasifica los archivos por extensión en carpetas predefinidas (como imágenes, iconos, etc.),
/// mueve los archivos a sus respectivas carpetas y limpia directorios no válidos o subcarpetas innecesarias.
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
        final oldPath = entity.path.replaceAll('\\', '/');
        entity.renameSync(newPath);
        movedPaths[oldPath] = newPath.replaceAll('\\', '/');
      }
    }


    final validFolders = _groups.keys.toSet();

    for (final entity in assetsDir.listSync()) {
      if (entity is Directory) {
        final folderName = path.basename(entity.path);

        // Si no está en las carpetas válidas → eliminarla
        if (!validFolders.contains(folderName)) {
          entity.deleteSync(recursive: true);
        } else {
          // Si es válida, borrar subcarpetas dentro de ella
          for (final sub in entity.listSync()) {
            if (sub is Directory) {
              sub.deleteSync(recursive: true);
            }
          }
        }
      }
    }

    return movedPaths;
  }
}
