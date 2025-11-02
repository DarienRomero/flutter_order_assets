library flutter_order_assets;

import 'dart:io';

import 'package:flutter_order_assets/asset_sorter.dart';
import 'package:flutter_order_assets/pubspec_updater.dart';
import 'package:flutter_order_assets/reference_updater.dart';

class FlutterOrderAssets {
  static Future<void> start(List<String> arguments) async {
    final assetsDir = Directory('assets');
    final pubspec = File('pubspec.yaml');

    if (!assetsDir.existsSync()) {
      throw Exception('Carpeta assets/ no encontrada.');
    }

    if (!pubspec.existsSync()) {
      throw Exception('Archivo pubspec no encontrado.');
    }

    print('📁 Ordenando assets...');
    final sorter = AssetSorter(assetsDir);
    final movedFiles = await sorter.sort();

    print('🧾 Actualizando pubspec.yaml...');
    final updater = PubspecUpdater(pubspec);
    updater.updateAssets();

    // // Map de rutas viejas a nuevas para actualizar referencias
    // final movedPaths = <String, String>{};
    // for (final file in movedFiles) {
    //   final old = file.path.split('/').takeWhile((e) => e != 'assets').join('/');
    //   movedPaths[old] = file.path;
    // }

    // print('🔗 Actualizando referencias en /lib...');
    // final refUpdater = ReferenceUpdater();
    // refUpdater.updateReferences(movedPaths);

    print('✅ Proceso completado.');
  }
}
