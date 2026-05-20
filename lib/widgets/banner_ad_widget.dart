import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// デバッグ時はGoogleのテスト広告IDを使用（不正クリック防止）
const _androidBannerUnitId = kDebugMode
    ? 'ca-app-pub-3940256099942544/6300978111'  // テスト用
    : 'ca-app-pub-9410375406721754/3939549504'; // 本番

// iOSのバナーユニットIDはAdMobでiOSアプリ登録後に差し替える
const _iosBannerUnitId = kDebugMode
    ? 'ca-app-pub-3940256099942544/2934735716'  // テスト用
    : 'ca-app-pub-9410375406721754/3939549504'; // TODO: iOS用ユニットIDに差し替え

String get _bannerUnitId =>
    defaultTargetPlatform == TargetPlatform.iOS ? _iosBannerUnitId : _androidBannerUnitId;

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final ad = BannerAd(
      adUnitId: _bannerUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _loaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _ad = null;
        },
      ),
    );
    ad.load();
    _ad = ad;
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
