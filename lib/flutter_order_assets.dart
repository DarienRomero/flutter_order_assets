library flutter_order_assets;

class FlutterOrderAssets {
  static Future<void> start(List<String> arguments) async {
    if (arguments.isEmpty) {
      print('New package name is missing. Please provide a package name.');
      return;
    }

    print("Everything ok");
  }
}
