import 'dart:io';
import 'package:flutter_order_assets/asset_sorter.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

void main() {
  late Directory tempDir;
  late AssetSorter sorter;

  setUp(() async {
    // Create a temporary directory for each test
    tempDir = await Directory.systemTemp.createTemp('asset_sorter_test_');
    sorter = AssetSorter(tempDir);
  });

  tearDown(() async {
    // Clean up after each test
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('moves files to the correct folders based on their extensions', () async {
    // Create test files
    final files = [
      File(path.join(tempDir.path, 'icon.svg')),
      File(path.join(tempDir.path, 'photo.png')),
      File(path.join(tempDir.path, 'png', 'capture.png'))
        ..parent.createSync(recursive: true),
      File(path.join(tempDir.path, 'images', 'image.png'))
        ..parent.createSync(recursive: true),
      File(path.join(tempDir.path, 'font.otf')),
      File(path.join(tempDir.path, 'sound.mp3')),
      File(path.join(tempDir.path, 'music/sound.mp3'))
        ..parent.createSync(recursive: true),
      File(path.join(tempDir.path, 'unknown.xyz')),
    ];

    for (var f in files) {
      await f.writeAsString('dummy');
    }

    final moved = await sorter.sort();

    // Verify that files were moved
    expect(moved.keys.length, 7);
    expect(File(path.join(tempDir.path, 'icons', 'icon.svg')).existsSync(), isTrue);
    expect(File(path.join(tempDir.path, 'images', 'photo.png')).existsSync(), isTrue);
    expect(File(path.join(tempDir.path, 'images', 'capture.png')).existsSync(), isTrue);
    expect(File(path.join(tempDir.path, 'images', 'image.png')).existsSync(), isTrue);
    expect(File(path.join(tempDir.path, 'fonts', 'font.otf')).existsSync(), isTrue);
    expect(File(path.join(tempDir.path, 'audio', 'sound.mp3')).existsSync(), isTrue);
    expect(File(path.join(tempDir.path, 'misc', 'unknown.xyz')).existsSync(), isTrue);
  });

  test('removes invalid folders', () async {
    // Create a folder not included in _groups
    final invalidDir = Directory(path.join(tempDir.path, 'temp_folder'))..createSync();
    final validDir = Directory(path.join(tempDir.path, 'images'))..createSync();

    // Add a file inside a valid folder
    final file = File(path.join(validDir.path, 'photo.png'));
    await file.writeAsString('img');

    await sorter.sort();

    // Invalid folder should be deleted
    expect(invalidDir.existsSync(), isFalse);

    // Valid folder should still exist
    expect(validDir.existsSync(), isTrue);
  });

  test('removes subfolders inside valid folders', () async {
    final imagesDir = Directory(path.join(tempDir.path, 'images'))..createSync();
    final subDir = Directory(path.join(imagesDir.path, 'nested'))..createSync();

    final file = File(path.join(imagesDir.path, 'photo.png'));
    await file.writeAsString('img');

    await sorter.sort();

    // Subfolder inside a valid folder should be deleted
    expect(subDir.existsSync(), isFalse);
    expect(imagesDir.existsSync(), isTrue);
  });
}