package com.hamdy.app154score.liveactivity

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import com.hamdy.app154score.MainActivity
import com.hamdy.app154score.R
import java.io.InputStream
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

object LiveMatchNotificationManager {
    private const val CHANNEL_ID = "live_match_tracking_channel_v1"
    private const val CHANNEL_NAME = "Live Match Lock Screen Scores"
    private const val CHANNEL_DESC = "Ongoing lock-screen football match live scores and minute updates"

    private val executor = Executors.newFixedThreadPool(2)
    private val bitmapCache = ConcurrentHashMap<String, Bitmap>()
    val activeTrackedMatches = ConcurrentHashMap<String, Map<String, Any>>()

    fun initChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val existing = notificationManager.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description = CHANNEL_DESC
                    setShowBadge(false)
                    lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                }
                notificationManager.createNotificationChannel(channel)
            }
        }
    }

    fun showOrUpdateNotification(context: Context, data: Map<String, Any>) {
        initChannel(context)

        val matchId = data["matchId"]?.toString() ?: return
        activeTrackedMatches[matchId] = data

        val homeTeam = data["homeTeam"]?.toString() ?: "Home"
        val awayTeam = data["awayTeam"]?.toString() ?: "Away"
        val homeScore = data["homeScore"]?.toString() ?: "0"
        val awayScore = data["awayScore"]?.toString() ?: "0"
        val leagueName = data["leagueName"]?.toString() ?: "154 SCORE"
        val minute = data["minute"]?.toString() ?: ""
        val status = data["status"]?.toString() ?: "مباشر"
        val isFinished = data["isFinished"] == true || data["isFinished"]?.toString() == "true"
        val isHalftime = data["isHalftime"] == true || data["isHalftime"]?.toString() == "true"
        val hasPenalties = data["hasPenalties"] == true || data["hasPenalties"]?.toString() == "true"
        val penaltyHome = data["penaltyHome"]?.toString() ?: ""
        val penaltyAway = data["penaltyAway"]?.toString() ?: ""

        val homeLogoUrl = data["homeLogo"]?.toString() ?: ""
        val awayLogoUrl = data["awayLogo"]?.toString() ?: ""

        val statusText = when {
            isFinished -> "انتهت"
            isHalftime -> "استراحة"
            minute.isNotEmpty() -> "$minute'"
            else -> status
        }

        // Tap-through Intent to open Match Details
        val contentIntent = Intent(context, MainActivity::class.java).apply {
            action = "OPEN_MATCH_DETAILS"
            putExtra("match_id", matchId)
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingContentIntent = PendingIntent.getActivity(
            context,
            matchId.hashCode(),
            contentIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        // Stop Tracking Intent
        val stopIntent = Intent(context, StopTrackingReceiver::class.java).apply {
            action = StopTrackingReceiver.ACTION_STOP_TRACKING
            putExtra("match_id", matchId)
        }
        val pendingStopIntent = PendingIntent.getBroadcast(
            context,
            matchId.hashCode() + 1000,
            stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        // Collapsed RemoteViews
        val collapsedView = RemoteViews(context.packageName, R.layout.notification_live_match).apply {
            setTextViewText(R.id.tv_league_name, leagueName)
            setTextViewText(R.id.tv_status_badge, statusText)
            setTextViewText(R.id.tv_home_team, homeTeam)
            setTextViewText(R.id.tv_away_team, awayTeam)
            setTextViewText(R.id.tv_home_score, homeScore)
            setTextViewText(R.id.tv_away_score, awayScore)
        }

        // Expanded RemoteViews
        val expandedView = RemoteViews(context.packageName, R.layout.notification_live_match_expanded).apply {
            setTextViewText(R.id.tv_expanded_league_name, leagueName)
            setTextViewText(R.id.tv_expanded_status_badge, statusText)
            setTextViewText(R.id.tv_expanded_home_team, homeTeam)
            setTextViewText(R.id.tv_expanded_away_team, awayTeam)
            setTextViewText(R.id.tv_expanded_home_score, homeScore)
            setTextViewText(R.id.tv_expanded_away_score, awayScore)
            setOnClickPendingIntent(R.id.btn_stop_tracking, pendingStopIntent)

            if (hasPenalties && penaltyHome.isNotEmpty()) {
                setViewVisibility(R.id.tv_expanded_penalties, View.VISIBLE)
                setTextViewText(R.id.tv_expanded_penalties, "ركلات الترجيح: $penaltyHome - $penaltyAway")
            } else {
                setViewVisibility(R.id.tv_expanded_penalties, View.GONE)
            }
        }

        // Load cached logos immediately if available
        bitmapCache[homeLogoUrl]?.let {
            collapsedView.setImageViewBitmap(R.id.iv_home_logo, it)
            expandedView.setImageViewBitmap(R.id.iv_expanded_home_logo, it)
        }
        bitmapCache[awayLogoUrl]?.let {
            collapsedView.setImageViewBitmap(R.id.iv_away_logo, it)
            expandedView.setImageViewBitmap(R.id.iv_expanded_away_logo, it)
        }

        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setCustomContentView(collapsedView)
            .setCustomBigContentView(expandedView)
            .setContentIntent(pendingContentIntent)
            .setOngoing(!isFinished)
            .setAutoCancel(isFinished)
            .setOnlyAlertOnce(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(matchId.hashCode(), builder.build())

        // Update home screen widget
        LiveMatchWidgetProvider.updateAllWidgets(context, data)

        // Async download images in background if not cached yet
        if (homeLogoUrl.isNotEmpty() && !bitmapCache.containsKey(homeLogoUrl)) {
            fetchBitmapAsync(homeLogoUrl) { bmp ->
                if (bmp != null) {
                    bitmapCache[homeLogoUrl] = bmp
                    showOrUpdateNotification(context, data)
                }
            }
        }
        if (awayLogoUrl.isNotEmpty() && !bitmapCache.containsKey(awayLogoUrl)) {
            fetchBitmapAsync(awayLogoUrl) { bmp ->
                if (bmp != null) {
                    bitmapCache[awayLogoUrl] = bmp
                    showOrUpdateNotification(context, data)
                }
            }
        }
    }

    fun stopTracking(context: Context, matchId: String) {
        activeTrackedMatches.remove(matchId)
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(matchId.hashCode())
        LiveMatchWidgetProvider.clearWidget(context)
    }

    private fun fetchBitmapAsync(urlString: String, onLoaded: (Bitmap?) -> Unit) {
        executor.execute {
            try {
                val url = URL(urlString)
                val connection = url.openConnection() as HttpURLConnection
                connection.connectTimeout = 4000
                connection.readTimeout = 4000
                connection.doInput = true
                connection.connect()
                val input: InputStream = connection.inputStream
                val bitmap = BitmapFactory.decodeStream(input)
                onLoaded(bitmap)
            } catch (_: Exception) {
                onLoaded(null)
            }
        }
    }
}
