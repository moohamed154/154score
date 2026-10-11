package com.hamdy.app154score.liveactivity

import android.content.Context
import androidx.core.app.NotificationManagerCompat
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class LiveActivityPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL_NAME = "com.hamdy.app154score/live_activity"
        private var instance: LiveActivityPlugin? = null

        fun notifyTrackingStopped(matchId: String) {
            instance?.channel?.invokeMethod("onTrackingStopped", mapOf("matchId" to matchId))
        }
    }

    private var context: Context? = null
    private var channel: MethodChannel? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        instance = this
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler(this)
        LiveMatchNotificationManager.initChannel(binding.applicationContext)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null)
        channel = null
        context = null
        instance = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val ctx = context ?: run {
            result.error("NO_CONTEXT", "Application context is null", null)
            return
        }

        when (call.method) {
            "areActivitiesEnabled" -> {
                val enabled = NotificationManagerCompat.from(ctx).areNotificationsEnabled()
                result.success(enabled)
            }
            "startLiveActivity" -> {
                val args = call.arguments as? Map<String, Any> ?: emptyMap()
                val matchId = args["matchId"]?.toString()
                if (matchId.isNullOrEmpty()) {
                    result.error("INVALID_ARGUMENT", "matchId is required", null)
                    return
                }

                LiveMatchNotificationManager.showOrUpdateNotification(ctx, args)
                result.success(mapOf(
                    "activityId" to "android_$matchId",
                    "matchId" to matchId,
                    "pushToken" to ""
                ))
            }
            "updateLiveActivity" -> {
                val args = call.arguments as? Map<String, Any> ?: emptyMap()
                LiveMatchNotificationManager.showOrUpdateNotification(ctx, args)
                result.success(true)
            }
            "stopLiveActivity" -> {
                val args = call.arguments as? Map<String, Any> ?: emptyMap()
                val matchId = args["matchId"]?.toString() ?: ""
                if (matchId.isNotEmpty()) {
                    LiveMatchNotificationManager.stopTracking(ctx, matchId)
                }
                result.success(true)
            }
            "getActiveActivities" -> {
                val activeList = LiveMatchNotificationManager.activeTrackedMatches.keys().toList()
                result.success(activeList)
            }
            else -> {
                result.notImplemented()
            }
        }
    }
}
