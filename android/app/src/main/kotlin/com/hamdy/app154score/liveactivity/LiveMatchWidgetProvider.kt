package com.hamdy.app154score.liveactivity

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.widget.RemoteViews
import com.hamdy.app154score.MainActivity
import com.hamdy.app154score.R

class LiveMatchWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        val lastData = LiveMatchNotificationManager.activeTrackedMatches.values.firstOrNull()
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId, lastData)
        }
    }

    companion object {
        fun updateAllWidgets(context: Context, data: Map<String, Any>) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, LiveMatchWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId, data)
            }
        }

        fun clearWidget(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, LiveMatchWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId, null)
            }
        }

        private fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            data: Map<String, Any>?
        ) {
            val views = RemoteViews(context.packageName, R.layout.widget_live_match)

            if (data != null) {
                val matchId = data["matchId"]?.toString() ?: ""
                val homeTeam = data["homeTeam"]?.toString() ?: "Home"
                val awayTeam = data["awayTeam"]?.toString() ?: "Away"
                val homeScore = data["homeScore"]?.toString() ?: "0"
                val awayScore = data["awayScore"]?.toString() ?: "0"
                val leagueName = data["leagueName"]?.toString() ?: "154 SCORE"
                val minute = data["minute"]?.toString() ?: ""
                val status = data["status"]?.toString() ?: "مباشر"

                views.setTextViewText(R.id.widget_league, leagueName)
                views.setTextViewText(R.id.widget_status, if (minute.isNotEmpty()) "$minute'" else status)
                views.setTextViewText(R.id.widget_home_team, homeTeam)
                views.setTextViewText(R.id.widget_away_team, awayTeam)
                views.setTextViewText(R.id.widget_score, "$homeScore - $awayScore")

                val intent = Intent(context, MainActivity::class.java).apply {
                    action = "OPEN_MATCH_DETAILS"
                    putExtra("match_id", matchId)
                    flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val pendingIntent = PendingIntent.getActivity(
                    context,
                    appWidgetId,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
                )
                views.setOnClickPendingIntent(R.id.widget_container, pendingIntent)
            } else {
                views.setTextViewText(R.id.widget_league, "154 SCORE")
                views.setTextViewText(R.id.widget_status, "لا توجد مباريات جارية")
                views.setTextViewText(R.id.widget_score, "-")
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
