package com.hamdy.app154score

import android.content.Context
import android.graphics.Color
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val themeMode = prefs.getString("flutter.app_theme_mode", "system")
        if (themeMode == "dark") {
            window.decorView.setBackgroundColor(Color.parseColor("#0D1117"))
        } else if (themeMode == "light") {
            window.decorView.setBackgroundColor(Color.parseColor("#F8FAFC"))
        }
        super.onCreate(savedInstanceState)
    }
}
