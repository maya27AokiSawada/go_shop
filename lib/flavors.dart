// lib/flavors.dart
// フレーバーは起動時の --dart-define=FLAVOR=prod/dev で決定されます。
// ハードコードは禁止。必ず launch.json / tasks.json の dart-define で指定してください。
const _flavorFromEnv = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

enum Flavor {
  dev,
  staging,
  prod,
}

class F {
  static Flavor? _override;

  // ignore: avoid_setters_without_getters
  static set appFlavor(Flavor flavor) => _override = flavor;

  static Flavor get appFlavor {
    if (_override != null) return _override!;
    switch (_flavorFromEnv) {
      case 'dev':
        return Flavor.dev;
      case 'staging':
        return Flavor.staging;
      default:
        return Flavor.prod;
    }
  }

  static String get name => appFlavor.name;

  static String get title {
    switch (appFlavor) {
      case Flavor.dev:
        return 'My App (Dev)';
      case Flavor.staging:
        return 'My App (Staging)';
      case Flavor.prod:
        return 'My App';
    }
  }

// APIエンドポイントなどの設定もここに追加
}
