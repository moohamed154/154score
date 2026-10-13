package com.hamdy.app154score.liveactivity

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.PorterDuff
import android.graphics.PorterDuffXfermode
import android.graphics.Rect
import android.graphics.RectF
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
    // Upgraded to v3 to ensure high importance & lockscreen visibility on all devices
    private const val CHANNEL_ID = "live_match_tracking_channel_v3"
    private const val CHANNEL_NAME = "Live Match Lock Screen Scores"
    private const val CHANNEL_DESC = "Ongoing lock-screen football match live scores and minute updates"

    private val executor = Executors.newFixedThreadPool(2)
    private val bitmapCache = ConcurrentHashMap<String, Bitmap>()
    val activeTrackedMatches = ConcurrentHashMap<String, Map<String, Any>>()
    private val chronometerBaseCache = ConcurrentHashMap<String, Pair<Int, Long>>()

    fun initChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val existing = notificationManager.getNotificationChannel(CHANNEL_ID)
            if (existing == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    CHANNEL_NAME,
                    NotificationManager.IMPORTANCE_DEFAULT
                ).apply {
                    description = CHANNEL_DESC
                    setShowBadge(true)
                    lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
                    enableVibration(false)
                    setSound(null, null)
                }
                notificationManager.createNotificationChannel(channel)
            }
        }
    }

    fun showOrUpdateNotification(context: Context, data: Map<String, Any>) {
        initChannel(context)

        val matchId = data["matchId"]?.toString() ?: return
        activeTrackedMatches[matchId] = data

        val isArabic = data["isArabic"] == true || data["isArabic"]?.toString() == "true"
        val isLive = data["isLive"] == true || data["isLive"]?.toString() == "true"
        val isFinished = data["isFinished"] == true || data["isFinished"]?.toString() == "true"
        val isHalftime = data["isHalftime"] == true || data["isHalftime"]?.toString() == "true"
        val isUpcoming = !isLive && !isFinished

        val homeTeam = data["homeTeam"]?.toString() ?: if (isArabic) "المستضيف" else "Home"
        val awayTeam = data["awayTeam"]?.toString() ?: if (isArabic) "الضيف" else "Away"
        val homeScore = data["homeScore"]?.toString() ?: "0"
        val awayScore = data["awayScore"]?.toString() ?: "0"
        val leagueName = data["leagueName"]?.toString() ?: if (isArabic) "154 سبورت" else "154 SCORE"
        val minute = data["minute"]?.toString() ?: ""
        val clock = data["clock"]?.toString() ?: ""
        val status = data["status"]?.toString() ?: if (isArabic) "مباشر" else "LIVE"

        val hasPenalties = data["hasPenalties"] == true || data["hasPenalties"]?.toString() == "true"
        val penaltyHome = data["penaltyHome"]?.toString() ?: ""
        val penaltyAway = data["penaltyAway"]?.toString() ?: ""

        val homeLogoUrl = data["homeLogo"]?.toString() ?: ""
        val awayLogoUrl = data["awayLogo"]?.toString() ?: ""

        val statusText = when {
            isFinished -> if (isArabic) "انتهت" else "FT"
            isHalftime -> if (isArabic) "استراحة" else "HT"
            minute.isNotEmpty() -> "$minute'"
            isUpcoming -> if (isArabic) "لم تبدأ" else "Upcoming"
            else -> if (isArabic) status else "LIVE"
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

        // Collapsed RemoteViews
        val collapsedView = RemoteViews(context.packageName, R.layout.notification_live_match).apply {
            setTextViewText(R.id.tv_league_name, leagueName)
            setTextViewText(R.id.tv_status_badge, statusText)
            setTextViewText(R.id.tv_home_team, homeTeam)
            setTextViewText(R.id.tv_away_team, awayTeam)

            if (isUpcoming) {
                setViewVisibility(R.id.layout_collapsed_kickoff, View.VISIBLE)
                setViewVisibility(R.id.layout_collapsed_score, View.GONE)
                setTextViewText(R.id.tv_collapsed_clock, clock.ifEmpty { "--:--" })
            } else {
                setViewVisibility(R.id.layout_collapsed_kickoff, View.GONE)
                setViewVisibility(R.id.layout_collapsed_score, View.VISIBLE)
                setTextViewText(R.id.tv_home_score, homeScore)
                setTextViewText(R.id.tv_away_score, awayScore)
            }
        }

        // Expanded RemoteViews
        val expandedView = RemoteViews(context.packageName, R.layout.notification_live_match_expanded).apply {
            setTextViewText(R.id.tv_expanded_league_name, leagueName)
            setTextViewText(R.id.tv_expanded_status_badge, statusText)
            setTextViewText(R.id.tv_expanded_home_team, homeTeam)
            setTextViewText(R.id.tv_expanded_away_team, awayTeam)

            if (isUpcoming) {
                setViewVisibility(R.id.layout_expanded_kickoff, View.VISIBLE)
                setViewVisibility(R.id.layout_expanded_score, View.GONE)
                setTextViewText(R.id.tv_expanded_clock, clock.ifEmpty { "--:--" })
                setTextViewText(R.id.tv_expanded_kickoff_label, if (isArabic) "موعد الانطلاق" else "Kickoff Time")
            } else {
                setViewVisibility(R.id.layout_expanded_kickoff, View.GONE)
                setViewVisibility(R.id.layout_expanded_score, View.VISIBLE)
                setTextViewText(R.id.tv_expanded_home_score, homeScore)
                setTextViewText(R.id.tv_expanded_away_score, awayScore)
            }

            if (hasPenalties && penaltyHome.isNotEmpty()) {
                setViewVisibility(R.id.tv_expanded_penalties, View.VISIBLE)
                val penLabel = if (isArabic) "ركلات الترجيح" else "Penalties"
                setTextViewText(R.id.tv_expanded_penalties, "$penLabel: $penaltyHome - $penaltyAway")
            } else {
                setViewVisibility(R.id.tv_expanded_penalties, View.GONE)
            }

            // Footer localization
            val footerText = if (isArabic) {
                if (isLive) "154Score • تحديث فوري مباشر" else "154Score مباشر"
            } else {
                if (isLive) "154Score • Live Updates" else "154Score Live"
            }
            setTextViewText(R.id.tv_expanded_footer, footerText)
            setTextViewText(R.id.tv_expanded_details, if (isArabic) "اضغط للتفاصيل ↗" else "Details ↗")
        }

        val homeLogoBase64 = data["homeLogoBase64"]?.toString() ?: ""
        val awayLogoBase64 = data["awayLogoBase64"]?.toString() ?: ""

        // Prioritize instant Base64 club logos from Flutter
        if (homeLogoBase64.isNotEmpty()) {
            try {
                val bytes = android.util.Base64.decode(homeLogoBase64, android.util.Base64.DEFAULT)
                val bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                if (bmp != null) {
                    val circular = toCircularBitmap(bmp)
                    bitmapCache[homeLogoUrl.ifEmpty { "home_$matchId" }] = circular
                    collapsedView.setImageViewBitmap(R.id.iv_home_logo, circular)
                    expandedView.setImageViewBitmap(R.id.iv_expanded_home_logo, circular)
                }
            } catch (_: Exception) {}
        }
        if (awayLogoBase64.isNotEmpty()) {
            try {
                val bytes = android.util.Base64.decode(awayLogoBase64, android.util.Base64.DEFAULT)
                val bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.size)
                if (bmp != null) {
                    val circular = toCircularBitmap(bmp)
                    bitmapCache[awayLogoUrl.ifEmpty { "away_$matchId" }] = circular
                    collapsedView.setImageViewBitmap(R.id.iv_away_logo, circular)
                    expandedView.setImageViewBitmap(R.id.iv_expanded_away_logo, circular)
                }
            } catch (_: Exception) {}
        }

        // Live lock-screen minute Chronometer ticking
        val minuteDigits = minute.filter { it.isDigit() }
        val minuteNum = minuteDigits.toIntOrNull() ?: 0
        if (isLive && !isHalftime && !isFinished && minuteNum > 0) {
            val cachedBase = chronometerBaseCache[matchId]
            val baseTime = if (cachedBase != null && cachedBase.first == minuteNum) {
                cachedBase.second
            } else {
                val elapsedMillis = minuteNum * 60 * 1000L
                val computed = android.os.SystemClock.elapsedRealtime() - elapsedMillis
                chronometerBaseCache[matchId] = Pair(minuteNum, computed)
                computed
            }
            collapsedView.setViewVisibility(R.id.tv_status_badge, View.GONE)
            collapsedView.setViewVisibility(R.id.chronometer_status_badge, View.VISIBLE)
            collapsedView.setChronometer(R.id.chronometer_status_badge, baseTime, "%s'", true)

            expandedView.setViewVisibility(R.id.tv_expanded_status_badge, View.GONE)
            expandedView.setViewVisibility(R.id.chronometer_expanded_status_badge, View.VISIBLE)
            expandedView.setChronometer(R.id.chronometer_expanded_status_badge, baseTime, "%s'", true)
        } else {
            chronometerBaseCache.remove(matchId)
            collapsedView.setViewVisibility(R.id.chronometer_status_badge, View.GONE)
            collapsedView.setViewVisibility(R.id.tv_status_badge, View.VISIBLE)
            expandedView.setViewVisibility(R.id.chronometer_expanded_status_badge, View.GONE)
            expandedView.setViewVisibility(R.id.tv_expanded_status_badge, View.VISIBLE)
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
            .setStyle(NotificationCompat.DecoratedCustomViewStyle())
            .setCustomContentView(collapsedView)
            .setCustomBigContentView(expandedView)
            .setContentIntent(pendingContentIntent)
            .setOngoing(!isFinished)
            .setAutoCancel(isFinished)
            .setOnlyAlertOnce(true)
            .setShowWhen(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_STATUS)

        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        try {
            notificationManager.notify(matchId.hashCode(), builder.build())
        } catch (e: Exception) {
            android.util.Log.e("LiveMatchNotification", "Error showing custom RemoteViews notification: ${e.message}", e)
            try {
                val fallbackBuilder = NotificationCompat.Builder(context, CHANNEL_ID)
                    .setSmallIcon(R.mipmap.ic_launcher)
                    .setContentTitle("$homeTeam vs $awayTeam")
                    .setContentText("$homeScore - $awayScore | $statusText")
                    .setContentIntent(pendingContentIntent)
                    .setOngoing(!isFinished)
                    .setShowWhen(false)
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                notificationManager.notify(matchId.hashCode(), fallbackBuilder.build())
            } catch (_: Exception) {}
        }

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
        chronometerBaseCache.remove(matchId)
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.cancel(matchId.hashCode())
        LiveMatchWidgetProvider.clearWidget(context)
    }

    private fun fetchBitmapAsync(urlString: String, onLoaded: (Bitmap?) -> Unit) {
        executor.execute {
            try {
                val url = URL(urlString)
                val connection = url.openConnection() as HttpURLConnection
                connection.connectTimeout = 5000
                connection.readTimeout = 5000
                connection.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android) 154Score/1.0")
                connection.doInput = true
                connection.connect()
                val input: InputStream = connection.inputStream
                val originalBitmap = BitmapFactory.decodeStream(input)
                val circular = originalBitmap?.let { toCircularBitmap(it) }
                onLoaded(circular ?: originalBitmap)
            } catch (_: Exception) {
                onLoaded(null)
            }
        }
    }

    private fun toCircularBitmap(bitmap: Bitmap): Bitmap {
        val size = Math.min(bitmap.width, bitmap.height)
        val output = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(output)
        val paint = Paint().apply {
            isAntiAlias = true
            isFilterBitmap = true
        }
        val rect = Rect(0, 0, size, size)
        val rectF = RectF(rect)
        canvas.drawOval(rectF, paint)
        paint.xfermode = PorterDuffXfermode(PorterDuff.Mode.SRC_IN)
        val srcRect = Rect(
            (bitmap.width - size) / 2,
            (bitmap.height - size) / 2,
            (bitmap.width + size) / 2,
            (bitmap.height + size) / 2
        )
        canvas.drawBitmap(bitmap, srcRect, rect, paint)
        return output
    }
}
