import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// This class is responsible for updating the assets section in the pubspec.yaml file.
/// Recursively scans the 'assets' directory to collect all asset folders,
/// and updates the pubspec.yaml to include these paths in the Flutter configuration.
class PubspecUpdater {
  final File pubspecFile;
  final bool excludeAudio;

  PubspecUpdater(this.pubspecFile, {this.excludeAudio = false});

  void updateAssets() {
    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content);
    final editor = YamlEditor(content);

    final assetsDir = Directory('assets');

    // Get all asset directories
    final allAssets = assetsDir
        .listSync(recursive: false)
        .whereType<Directory>()
        .map((f) => "${f.path.replaceAll('\\', '/')}/")
        .toList()
        ..sort();

    // Get existing assets from pubspec.yaml to preserve some
    final existingAssets = <String>[];
    if (yaml['flutter'] != null && yaml['flutter']['assets'] != null) {
      final assetsList = yaml['flutter']['assets'] as List;
      existingAssets.addAll(assetsList.map((e) => e.toString()));
    }

    // Preserve audio files in assets/ if excludeAudio is true
    final preservedAssets = <String>[];
    for (final asset in existingAssets) {
      if (excludeAudio && _isAudioInAssetsRoot(asset)) {
        preservedAssets.add(asset);
      } else if (!asset.startsWith('assets/')) {
        // Always preserve assets outside assets/
        preservedAssets.add(asset);
      }
    }

    // Combine preserved assets with new directories
    final finalAssets = <String>[...preservedAssets, ...allAssets]
      ..sort();

    if (yaml['flutter'] == null) {
      editor.update(['flutter'], {'assets': finalAssets});
    } else if (yaml['flutter']['assets'] != null) {
      editor.update(['flutter', 'assets'], finalAssets);
    } else {
      editor.update(['flutter'], {'assets': finalAssets});
    }

    // Update font references before saving
    updateFonts(editor, yaml);
    
    // Save all changes (assets and fonts)
    pubspecFile.writeAsStringSync(editor.toString());
    print('✅ pubspec.yaml updated with ${finalAssets.length} assets');
  }

  /// Checks if an asset is an audio file directly in assets/
  bool _isAudioInAssetsRoot(String asset) {
    if (!asset.startsWith('assets/')) return false;
    
    final audioExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'];
    final isAudioFile = audioExtensions.any((ext) => asset.toLowerCase().endsWith(ext));
    
    if (!isAudioFile) return false;
    
    // Check that it's not in a subdirectory (must be assets/file.mp3)
    final pathWithoutAssets = asset.substring(7); // Remover "assets/"
    return !pathWithoutAssets.contains('/');
  }

  /// Updates font references when files are in assets/fonts/
  void updateFonts(YamlEditor editor, dynamic yaml) {
    // Check if fonts section exists
    if (yaml['flutter'] == null || yaml['flutter']['fonts'] == null) {
      return;
    }

    final fontsDir = Directory('assets/fonts');
    if (!fontsDir.existsSync()) {
      return;
    }

    // Get all font files in assets/fonts/
    final fontFiles = <String, String>{}; // fileName -> fullPath
    for (final entity in fontsDir.listSync()) {
      if (entity is File) {
        final fileName = path.basename(entity.path);
        fontFiles[fileName] = entity.path.replaceAll('\\', '/');
      }
    }

    if (fontFiles.isEmpty) {
      return;
    }

    final fontsList = yaml['flutter']['fonts'] as List;
    bool hasChanges = false;

    // Iterate over each font family
    for (int familyIndex = 0; familyIndex < fontsList.length; familyIndex++) {
      final family = fontsList[familyIndex] as Map;
      if (family['fonts'] == null) continue;

      final fontsInFamily = family['fonts'] as List;
      
      // Iterate over each font in the family
      for (int fontIndex = 0; fontIndex < fontsInFamily.length; fontIndex++) {
        final font = fontsInFamily[fontIndex] as Map;
        if (font['asset'] == null) continue;

        final oldAssetPath = font['asset'].toString();
        
        // Extract the file name from the old path
        final fileName = path.basename(oldAssetPath);
        
        // Check if the file exists in assets/fonts/
        if (fontFiles.containsKey(fileName)) {
          final newAssetPath = 'assets/fonts/$fileName';
          
          // Only update if the path is different
          if (oldAssetPath != newAssetPath) {
            // Update the path using yaml_edit
            try {
              editor.update(
                ['flutter', 'fonts', familyIndex, 'fonts', fontIndex, 'asset'],
                newAssetPath,
              );
              hasChanges = true;
              print('📝 Font updated: $oldAssetPath -> $newAssetPath');
            } catch (e) {
              print('⚠️ Error updating font $oldAssetPath: $e');
            }
          }
        }
      }
    }

    if (hasChanges) {
      print('✅ Font references updated');
    }
  }
}