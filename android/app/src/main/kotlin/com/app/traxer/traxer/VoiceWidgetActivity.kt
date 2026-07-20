package com.app.traxer.traxer

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs.BackgroundMode

/**
 * A transparent, no-history Activity that immediately opens the Flutter
 * voice-expense overlay screen (route: /voice-widget).
 *
 * It is launched by [VoiceWidget]. The Flutter side finishes it via
 * SystemNavigator.pop() once the overlay is dismissed.
 */
class VoiceWidgetActivity : FlutterActivity() {

    override fun getInitialRoute(): String = "/voice-widget"

    // The manifest theme (@style/TransparentVoiceTheme) makes the WINDOW
    // translucent, but FlutterActivity still renders an opaque surface unless
    // the background mode is transparent too (render + transparency modes are
    // derived from it) — without this the "overlay" is a black screen instead
    // of showing the home screen behind it.
    override fun getBackgroundMode(): BackgroundMode = BackgroundMode.transparent

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
