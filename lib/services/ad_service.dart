import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// 広告IDを環境別に取得
  String get _bannerAdUnitId {
    if (F.appFlavor == Flavor.prod) {
      // 本番環境では実際の広告IDを使用
      return 'ca-app-pub-YOUR_ACTUAL_ID/banner';
    } else {
      // 開発環境ではテスト用IDを使用
      return 'ca-app-pub-3940256099942544/6300978111';
    }
  }

  String get _interstitialAdUnitId {
    if (F.appFlavor == Flavor.prod) {
      return 'ca-app-pub-YOUR_ACTUAL_ID/interstitial';
    } else {
      return 'ca-app-pub-3940256099942544/1033173712';
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
          print('InterstitialAd failed to load: $error');
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
    final dailyCount = lastAdDay == today 
        ? (prefs.getInt(_dailyAdCountKey) ?? 0) 
        : 0;
    
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

  /// バナー広告作成（ニュース欄用）
  BannerAd createBannerAd({
    required AdSize size,
    VoidCallback? onAdLoaded,
    VoidCallback? onAdFailedToLoad,
  }) {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          print('バナー広告が読み込まれました');
          onAdLoaded?.call();
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          print('バナー広告の読み込みに失敗: $error');
          onAdFailedToLoad?.call();
        },
      ),
    );
  }

  /// 地域広告用の位置情報取得
  Future<Position?> getCurrentLocation() async {
    try {
      // 位置情報権限チェック
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      // 位置情報取得
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low, // 粗い精度で十分
      );
    } catch (e) {
      print('位置情報取得エラー: $e');
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

  void _loadBannerAd() {
    final adService = ref.read(adServiceProvider);
    _bannerAd = adService.createBannerAd(
      size: AdSize.banner,
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