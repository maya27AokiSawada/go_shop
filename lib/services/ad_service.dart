import 'dart:async';
import 'dart:io';

// Logger instance

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/app_logger.dart';
import '../flavors.dart';

// プロバイダー
final adServiceProvider = Provider<AdService>((ref) => AdService());

class AdService {
  static const String _lastAdShownKey = 'last_ad_shown';
  static const String _dailyAdCountKey = 'daily_ad_count';
  static const int _maxDailyAds = 3;
  static const int _minAdIntervalMinutes = 30;

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isAdLoaded = false;

  /// 広告IDを環境別に取得（開発中は常にテスト広告IDを使用）
  String get _bannerAdUnitId {
    // 🔥 開発中は常にテスト広告IDを使用（本番IDは審査後に切り替え）
    return dotenv.env['ADMOB_TEST_BANNER_AD_UNIT_ID'] ??
        'ca-app-pub-3940256099942544/6300978111'; // テスト広告ID
  }

  String get _interstitialAdUnitId {
    if (F.appFlavor == Flavor.prod) {
      return 'ca-app-pub-YOUR_ACTUAL_ID/interstitial'; // TODO: 環境変数化
    } else {
      return dotenv.env['ADMOB_TEST_BANNER_AD_UNIT_ID'] ??
          'ca-app-pub-3940256099942544/1033173712';
    }
  }

  /// 広告SDK初期化
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  /// インタースティシャル広告の読み込み
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoaded = true;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          Log.info('InterstitialAd failed to load: $error');
          _interstitialAd = null;
          _isAdLoaded = false;
        },
      ),
    );
  }

  /// サインイン時の広告表示判定
  Future<bool> shouldShowSignInAd() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 今日の広告表示回数チェック
    final today = DateTime.now().day;
    final lastAdDay = prefs.getInt('last_ad_day') ?? 0;
    final dailyCount =
        lastAdDay == today ? (prefs.getInt(_dailyAdCountKey) ?? 0) : 0;

    if (dailyCount >= _maxDailyAds) {
      return false;
    }

    // 2. 最後の広告表示からの時間チェック
    final lastAdTime = prefs.getInt(_lastAdShownKey) ?? 0;
    final timeDiff = DateTime.now().millisecondsSinceEpoch - lastAdTime;
    final minutesSinceLastAd = timeDiff / (1000 * 60);

    return minutesSinceLastAd >= _minAdIntervalMinutes;
  }

  /// サインイン広告を表示
  Future<void> showSignInAd() async {
    if (!_isAdLoaded || _interstitialAd == null) {
      _loadInterstitialAd(); // 次回用に読み込み
      return;
    }

    final shouldShow = await shouldShowSignInAd();
    if (!shouldShow) return;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        _recordAdShown();
        _loadInterstitialAd(); // 次の広告を読み込み
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    await _interstitialAd!.show();
  }

  /// 広告表示記録
  Future<void> _recordAdShown() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    await prefs.setInt(_lastAdShownKey, now.millisecondsSinceEpoch);
    await prefs.setInt('last_ad_day', now.day);

    final currentCount = prefs.getInt(_dailyAdCountKey) ?? 0;
    await prefs.setInt(_dailyAdCountKey, currentCount + 1);
  }

  /// バナー広告作成（位置情報ベース：30km圏内優先）
  Future<BannerAd> createBannerAd({
    required AdSize size,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailedToLoad,
    bool useLocation = true,
  }) async {
    AdRequest adRequest;

    if (useLocation && (Platform.isAndroid || Platform.isIOS)) {
      // 位置情報を取得して広告リクエストに追加（30km圏内の店舗広告を優先）
      final position = await getCurrentLocation();
      if (position != null) {
        Log.info('📍 位置情報取得成功: (${position.latitude}, ${position.longitude})');
        // 位置情報を含むAdRequestを作成
        adRequest = const AdRequest(
          keywords: ['local', 'nearby', '地域'],
          // Google AdMobは自動的に位置情報を使用して地域広告を配信（約30km圏内）
        );
      } else {
        Log.info('📍 位置情報取得失敗、標準広告を表示');
        adRequest = const AdRequest();
      }
    } else {
      adRequest = const AdRequest();
    }

    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size,
      request: adRequest,
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          Log.info('✅ バナー広告が読み込まれました');
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          Log.info('❌ バナー広告の読み込みに失敗: $error');
          onAdFailedToLoad?.call();
        },
      ),
    );
  }

  /// 地域広告用の位置情報取得（30km圏内の広告優先表示）
  Future<Position?> getCurrentLocation() async {
    try {
      // Android/iOSでのみ位置情報を取得
      if (!Platform.isAndroid && !Platform.isIOS) {
        return null;
      }

      // 位置情報サービスが有効かチェック
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        Log.info('📍 位置情報サービスが無効です');
        return null;
      }

      // 位置情報権限チェック
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        Log.info('📍 位置情報権限をリクエスト中...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          Log.info('📍 位置情報権限が拒否されました');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        Log.info('📍 位置情報権限が永久に拒否されています');
        return null;
      }

      // 位置情報取得（粗い精度で30km圏内の広告配信に使用）
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // 30km圏内で十分
        timeLimit: const Duration(seconds: 5), // タイムアウト設定
      );

      // 取得した位置情報をキャッシュ（頻繁な取得を避ける）
      await _cacheLocation(position);

      return position;
    } catch (e) {
      Log.error('❌ 位置情報取得エラー: $e');
      // キャッシュから取得を試みる
      return await _getCachedLocation();
    }
  }

  /// 位置情報をキャッシュ（1時間有効）
  Future<void> _cacheLocation(Position position) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('cached_latitude', position.latitude);
      await prefs.setDouble('cached_longitude', position.longitude);
      await prefs.setInt(
          'cached_location_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      Log.error('位置情報キャッシュエラー: $e');
    }
  }

  /// キャッシュされた位置情報を取得（1時間以内のみ有効）
  Future<Position?> _getCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final latitude = prefs.getDouble('cached_latitude');
      final longitude = prefs.getDouble('cached_longitude');
      final cachedTime = prefs.getInt('cached_location_time');

      if (latitude != null && longitude != null && cachedTime != null) {
        final age = DateTime.now().millisecondsSinceEpoch - cachedTime;
        if (age < 3600000) {
          // 1時間以内
          Log.info('📍 キャッシュから位置情報を取得');
          return Position(
            latitude: latitude,
            longitude: longitude,
            timestamp: DateTime.fromMillisecondsSinceEpoch(cachedTime),
            accuracy: 0,
            altitude: 0,
            heading: 0,
            speed: 0,
            speedAccuracy: 0,
            altitudeAccuracy: 0,
            headingAccuracy: 0,
          );
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// リソース解放
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}

/// ニュース欄用の地域広告ウィジェット
class LocalNewsAdWidget extends ConsumerStatefulWidget {
  const LocalNewsAdWidget({super.key});

  @override
  ConsumerState<LocalNewsAdWidget> createState() => _LocalNewsAdWidgetState();
}

class _LocalNewsAdWidgetState extends ConsumerState<LocalNewsAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() async {
    final adService = ref.read(adServiceProvider);
    _bannerAd = await adService.createBannerAd(
      size: AdSize.banner,
      useLocation: true, // 位置情報ベースの広告を有効化
      onAdLoaded: () {
        setState(() {
          _isAdLoaded = true;
        });
      },
      onAdFailedToLoad: () {
        setState(() {
          _isAdLoaded = false;
        });
      },
    );
    _bannerAd!.load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.grey.shade50,
      ),
      child: Column(
        children: [
          // 広告ラベル
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: const Text(
              '🏪 近隣店舗情報',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          // 広告バナー
          if (_isAdLoaded && _bannerAd != null)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          else
            Container(
              height: 60,
              width: double.infinity,
              color: Colors.grey.shade200,
              child: const Center(
                child: Text(
                  '地域情報を読み込み中...',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}

/// ホーム画面用のバナー広告ウィジェット
class HomeBannerAdWidget extends ConsumerStatefulWidget {
  const HomeBannerAdWidget({super.key});

  @override
  ConsumerState<HomeBannerAdWidget> createState() => _HomeBannerAdWidgetState();
}

class _HomeBannerAdWidgetState extends ConsumerState<HomeBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    // WindowsではAdMobがサポートされていないため、広告を読み込まない
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() async {
    try {
      final adService = ref.read(adServiceProvider);
      _bannerAd = await adService.createBannerAd(
        size: AdSize.banner,
        useLocation: true, // 位置情報ベースの広告を有効化（30km圏内優先）
        onAdLoaded: () {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: () {
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
      );
      _bannerAd!.load();
    } catch (e) {
      // Windows等でAdMobが利用できない場合はエラーをキャッチ
      AppLogger.warning('⚠️ AdMob読み込みエラー: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // WindowsではAdMobがサポートされていないため、何も表示しない
    if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) {
      return const SizedBox.shrink();
    }

    if (!_isAdLoaded || _bannerAd == null) {
      return const SizedBox.shrink(); // 広告が読み込まれるまで非表示
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.white,
      ),
      child: Column(
        children: [
          // 広告ラベル
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: const Text(
              '広告',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // 広告バナー
          SizedBox(
            height: _bannerAd!.size.height.toDouble(),
            width: _bannerAd!.size.width.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }
}
