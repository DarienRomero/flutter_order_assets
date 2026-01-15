# Flutter Order Assets

Automatically organizes your Flutter project assets into structured folders by file type. This tool makes the organization process very easy and fast.

## What It does?

- [x] Organizes assets into folders by file type (images, icons, fonts, audio, videos, animations, etc.)
- [x] Automatically updates the `pubspec.yaml` file with the new asset paths
- [x] Updates asset references in all Dart files in the project
- [x] Updates font references in `pubspec.yaml` when they are in `assets/fonts/`
- [x] Cleans invalid directories and unnecessary subfolders
- [x] Special support for `audioplayers`: preserves audio files in the root of `assets/` if it detects the dependency

## Asset Categories

Assets are automatically organized into the following folders:

- **icons**: `.svg`, `.ico`
- **images**: `.png`, `.jpg`, `.jpeg`, `.webp`, `.bmp`, `.gif`
- **fonts**: `.otf`, `.ttf`, `.woff`, `.woff2`
- **audio**: `.mp3`, `.wav`, `.ogg`, `.m4a`, `.aac`
- **videos**: `.mp4`, `.mov`, `.avi`, `.webm`, `.mkv`, `.flv`
- **animations**: `.json`, `.riv`, `.flr`
- **data**: `.json`, `.yaml`, `.yml`, `.xml`, `.csv`
- **env**: `.env`
- **models**: `.obj`, `.fbx`, `.glb`, `.gltf`, `.stl`
- **docs**: `.txt`, `.md`, `.pdf`, `.docx`
- **textures**: `.atlas`, `.ktx`, `.dds`, `.tga`
- **misc**: Other files that don't match any category

## How to Use?

Add Flutter Order Assets to your `pubspec.yaml` in the `dev_dependencies:` section:

```yaml
dev_dependencies: 
  flutter_order_assets: ^1.1.0
```

or run this command:

```bash
flutter pub add -d flutter_order_assets
```

Update dependencies:

```bash
flutter pub get
```

Run this command to organize your assets:

```bash
dart run flutter_order_assets:main
```

The command:
1. Scans the `assets/` folder of your project
2. Organizes files into folders by type
3. Updates `pubspec.yaml` with the new paths
4. Updates all references in your Dart files

## Requirements

- Flutter SDK (>=2.12.0)
- An `assets/` folder in the root of your project
- A `pubspec.yaml` file in the root of your project
- A `lib/` folder in the root of your project

## Notes

- If you have the `audioplayers` or `audioplayer` dependency in your `pubspec.yaml`, audio files that are directly in `assets/` will not be moved (they are preserved for compatibility with audioplayers)
- Audio files in subdirectories will be organized normally
- Asset references in your Dart files are automatically updated when files are moved

## Limitations

- Dynamic asset paths (e.g., `/assets/images/${some_value}`) are not processed. The tool only handles static asset paths and cannot update references that use string interpolation or dynamic path construction.

## Meta

Darien Romero - [GitHub](https://github.com/DarienRomero)

Distributed under the MIT license.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request
