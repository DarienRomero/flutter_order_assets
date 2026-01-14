import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Esta clase se encarga de actualizar la sección de assets en el archivo pubspec.yaml.
/// Escanea el directorio 'assets' de forma recursiva para recopilar todas las carpetas de activos,
/// y actualiza el pubspec.yaml para incluir estas rutas en la configuración de Flutter.
class PubspecUpdater {
  final File pubspecFile;
  final bool excludeAudio;

  PubspecUpdater(this.pubspecFile, {this.excludeAudio = false});

  void updateAssets() {
    final content = pubspecFile.readAsStringSync();
    final yaml = loadYaml(content);
    final editor = YamlEditor(content);

    final assetsDir = Directory('assets');

    // Obtener todos los directorios de assets
    final allAssets = assetsDir
        .listSync(recursive: false)
        .whereType<Directory>()
        .map((f) => "${f.path.replaceAll('\\', '/')}/")
        .toList()
        ..sort();

    // Obtener assets existentes del pubspec.yaml para preservar algunos
    final existingAssets = <String>[];
    if (yaml['flutter'] != null && yaml['flutter']['assets'] != null) {
      final assetsList = yaml['flutter']['assets'] as List;
      existingAssets.addAll(assetsList.map((e) => e.toString()));
    }

    // Preservar archivos de audio en assets/ si excludeAudio es true
    final preservedAssets = <String>[];
    for (final asset in existingAssets) {
      if (excludeAudio && _isAudioInAssetsRoot(asset)) {
        preservedAssets.add(asset);
      } else if (!asset.startsWith('assets/')) {
        // Preservar assets fuera de assets/ siempre
        preservedAssets.add(asset);
      }
    }

    // Combinar assets preservados con los nuevos directorios
    final finalAssets = <String>[...preservedAssets, ...allAssets]
      ..sort();

    if (yaml['flutter'] == null) {
      editor.update(['flutter'], {'assets': finalAssets});
    } else if (yaml['flutter']['assets'] != null) {
      editor.update(['flutter', 'assets'], finalAssets);
    } else {
      editor.update(['flutter'], {'assets': finalAssets});
    }

    // Actualizar referencias de fuentes antes de guardar
    updateFonts(editor, yaml);
    
    // Guardar todos los cambios (assets y fuentes)
    pubspecFile.writeAsStringSync(editor.toString());
    print('✅ pubspec.yaml actualizado con ${finalAssets.length} assets');
  }

  /// Verifica si un asset es un archivo de audio directamente en assets/
  bool _isAudioInAssetsRoot(String asset) {
    if (!asset.startsWith('assets/')) return false;
    
    final audioExtensions = ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac'];
    final isAudioFile = audioExtensions.any((ext) => asset.toLowerCase().endsWith(ext));
    
    if (!isAudioFile) return false;
    
    // Verificar que no esté en un subdirectorio (debe ser assets/archivo.mp3)
    final pathWithoutAssets = asset.substring(7); // Remover "assets/"
    return !pathWithoutAssets.contains('/');
  }

  /// Actualiza las referencias de fuentes cuando los archivos están en assets/fonts/
  void updateFonts(YamlEditor editor, dynamic yaml) {
    // Verificar si existe la sección de fuentes
    if (yaml['flutter'] == null || yaml['flutter']['fonts'] == null) {
      return;
    }

    final fontsDir = Directory('assets/fonts');
    if (!fontsDir.existsSync()) {
      return;
    }

    // Obtener todos los archivos de fuentes en assets/fonts/
    final fontFiles = <String, String>{}; // nombreArchivo -> rutaCompleta
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

    // Iterar sobre cada familia de fuente
    for (int familyIndex = 0; familyIndex < fontsList.length; familyIndex++) {
      final family = fontsList[familyIndex] as Map;
      if (family['fonts'] == null) continue;

      final fontsInFamily = family['fonts'] as List;
      
      // Iterar sobre cada fuente en la familia
      for (int fontIndex = 0; fontIndex < fontsInFamily.length; fontIndex++) {
        final font = fontsInFamily[fontIndex] as Map;
        if (font['asset'] == null) continue;

        final oldAssetPath = font['asset'].toString();
        
        // Extraer el nombre del archivo del path antiguo
        final fileName = path.basename(oldAssetPath);
        
        // Verificar si el archivo existe en assets/fonts/
        if (fontFiles.containsKey(fileName)) {
          final newAssetPath = 'assets/fonts/$fileName';
          
          // Solo actualizar si la ruta es diferente
          if (oldAssetPath != newAssetPath) {
            // Actualizar la ruta usando yaml_edit
            try {
              editor.update(
                ['flutter', 'fonts', familyIndex, 'fonts', fontIndex, 'asset'],
                newAssetPath,
              );
              hasChanges = true;
              print('📝 Fuente actualizada: $oldAssetPath -> $newAssetPath');
            } catch (e) {
              print('⚠️ Error al actualizar fuente $oldAssetPath: $e');
            }
          }
        }
      }
    }

    if (hasChanges) {
      print('✅ Referencias de fuentes actualizadas');
    }
  }
}