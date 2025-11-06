library flutter_order_assets;

import 'dart:io';

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

    final sorter = AssetSorter(assetsDir);
    
    final movedPaths = await sorter.sort();

    final updater = PubspecUpdater(pubspec);
    updater.updateAssets();

    final refUpdater = ReferenceUpdater();
    refUpdater.updateReferences(movedPaths);

    print('✅ Proceso completed.');
  }
}
