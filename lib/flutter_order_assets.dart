library flutter_order_assets;

import 'dart:io';
import 'package:yaml/yaml.dart';

import 'package:flutter_order_assets/asset_sorter.dart';
import 'package:flutter_order_assets/pubspec_updater.dart';
import 'package:flutter_order_assets/reference_updater.dart';

class FlutterOrderAssets {
  static Future<void> start(List<String> arguments) async {
    final assetsDir = Directory('assets');
    final pubspec = File('pubspec.yaml');
    final libDir = Directory('lib');

    if (!assetsDir.existsSync()) {
      throw Exception('Carpeta assets/ no encontrada.');
    }

    if (!pubspec.existsSync()) {
      throw Exception('Archivo pubspec no encontrado.');
    }
    
    if (!libDir.existsSync()) {
      throw Exception('Carpeta lib/ no encontrada.');
    }

    // Detectar si existe audioplayers en las dependencias
    final hasAudioPlayer = _hasAudioPlayerDependency(pubspec);
    
    final sorter = AssetSorter(assetsDir, excludeAudio: hasAudioPlayer);
    
    final movedPaths = await sorter.sort();

    final updater = PubspecUpdater(pubspec, excludeAudio: hasAudioPlayer);
    updater.updateAssets();

    final refUpdater = ReferenceUpdater();
    refUpdater.updateReferences(movedPaths);

    print('✅ Proceso completed.');
  }

  /// Verifica si existe la dependencia audioplayers en el pubspec.yaml
  static bool _hasAudioPlayerDependency(File pubspecFile) {
    final pubspecContent = pubspecFile.readAsStringSync();
    final yaml = loadYaml(pubspecContent);
    if (yaml['dependencies'] == null) return false;
    
    final dependencies = yaml['dependencies'] as Map;
    return dependencies.keys.any((key) {
      final keyStr = key.toString().toLowerCase();
      return keyStr == 'audioplayers' || keyStr == 'audioplayer';
    });
  }
}
