import 'dart:io';
import 'package:path/path.dart' as path;

/// This class is responsible for organizing assets in the assets directory.
/// Classifies files by extension into predefined folders (such as images, icons, etc.),
/// moves files to their respective folders and cleans invalid directories or unnecessary subfolders.
class AssetSorter {
  final Directory assetsDir;
  final bool excludeAudio;

  AssetSorter(this.assetsDir, {this.excludeAudio = false});

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

      // If excludeAudio is true and the file is audio in the root of assets/, don't move it
      if (excludeAudio && _isAudioInAssetsRoot(entity.path)) {
        continue;
      }

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

        // If not in valid folders → delete it
        if (!validFolders.contains(folderName)) {
          entity.deleteSync(recursive: true);
        } else {
          // If valid, delete subfolders inside it
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

  /// Checks if a file is audio and is directly in assets/ (not in subdirectories)
  bool _isAudioInAssetsRoot(String filePath) {
    final audioExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'];
    final ext = path.extension(filePath).toLowerCase();
    
    if (!audioExtensions.contains(ext)) return false;
    
    // Get the relative path from assetsDir
    final relativePath = path.relative(filePath, from: assetsDir.path);
    
    // If it doesn't contain '/', it's directly in assets/
    return !relativePath.contains(path.separator);
  }
}
