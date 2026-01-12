import 'dart:io';
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
        .listSync(recursive: true)
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

    print("allAssets");
    print(finalAssets);
    if (yaml['flutter'] == null) {
      editor.update(['flutter'], {'assets': finalAssets});
    } else if (yaml['flutter']['assets'] != null) {
      editor.update(['flutter', 'assets'], finalAssets);
    } else {
      editor.update(['flutter'], {'assets': finalAssets});
    }

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
}