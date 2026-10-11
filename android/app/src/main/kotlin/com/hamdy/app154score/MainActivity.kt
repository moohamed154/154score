package com.hamdy.app154score

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import com.hamdy.app154score.liveactivity.LiveActivityPlugin
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var navigationChannel: MethodChannel? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val themeMode = prefs.getString("flutter.app_theme_mode", "system")
        if (themeMode == "dark") {
            window.decorView.setBackgroundColor(Color.parseColor("#0D1117"))
        } else if (themeMode == "light") {
            window.decorView.setBackgroundColor(Color.parseColor("#F8FAFC"))
        }
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        flutterEngine.plugins.add(LiveActivityPlugin())
        navigationChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.hamdy.app154score/navigation")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val matchId = intent?.getStringExtra("match_id")
        if (!matchId.isNullOrEmpty()) {
            navigationChannel?.invokeMethod("navigateToMatch", matchId)
        }
    }
}
