package com.hamdy.app154score.liveactivity

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class StopTrackingReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_STOP_TRACKING = "com.hamdy.app154score.ACTION_STOP_TRACKING"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_STOP_TRACKING) {
            val matchId = intent.getStringExtra("match_id") ?: return
            LiveMatchNotificationManager.stopTracking(context, matchId)
            LiveActivityPlugin.notifyTrackingStopped(matchId)
        }
    }
}
