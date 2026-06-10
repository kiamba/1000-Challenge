import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  // ⚠️ GOOGLE TEST UNIT ID
  // Swap this with your real App Open Ad Unit ID when you are ready to publish!
  final String _adUnitId = 'ca-app-pub-4908089317133503/2785045626';

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _loadTime;

  /// Loads an App Open Ad if one isn't already cached
  void loadAd() {
    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpenAd loaded successfully.');
          _appOpenAd = ad;
          _loadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  /// Checks if a valid ad is cached and ready to show
  bool get isAdAvailable {
    if (_appOpenAd == null) return false;
    if (_loadTime == null) return false;
    
    // AdMob ads expire after 4 hours
    return DateTime.now().difference(_loadTime!).inHours < 4;
  }

  /// Shows the ad if available
  void showAdIfAvailable() {
    if (_isShowingAd) {
      debugPrint('An ad is already showing. Skipping.');
      return;
    }

    if (!isAdAvailable) {
      debugPrint('No valid App Open ad available. Loading a fresh one...');
      loadAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AppOpenAd failed to show: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // Preload the next one
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('AppOpenAd dismissed.');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd(); // Preload the next one
      },
    );

    _appOpenAd!.show();
  }
}