package com.weatherapp.weather_app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class GolfWeatherWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int
    ) {
        val data = HomeWidgetPlugin.getData(context)

        val status     = data.getString("status", "NONE") ?: "NONE"
        val ddayLabel  = data.getString("dday_label", "") ?: ""
        val courseName = data.getString("course_name", "일정 없음") ?: "일정 없음"
        val message    = data.getString("status_message", "켜자마자 날씨") ?: "켜자마자 날씨"
        val temp       = data.getString("temp", "") ?: ""
        val rainProb   = data.getString("rain_prob", "") ?: ""
        val windSpeed  = data.getString("wind_speed", "") ?: ""
        val cancelMsg  = data.getString("cancel_message", "") ?: ""

        val views = RemoteViews(context.packageName, R.layout.golf_weather_widget)

        // 상태별 배경색
        val bgColor = when (status) {
            "GREEN"  -> 0xFF1B4332.toInt()
            "YELLOW" -> 0xFF3D2B00.toInt()
            "RED"    -> 0xFF3D0000.toInt()
            else     -> 0xFF0D1B2A.toInt()
        }
        views.setInt(R.id.widget_root, "setBackgroundColor", bgColor)

        // 상태 인디케이터 색
        val dotColor = when (status) {
            "GREEN"  -> 0xFF4CAF50.toInt()
            "YELLOW" -> 0xFFFFC107.toInt()
            "RED"    -> 0xFFF44336.toInt()
            else     -> 0xFF9E9E9E.toInt()
        }
        views.setInt(R.id.status_dot, "setBackgroundColor", dotColor)

        views.setTextViewText(R.id.tv_dday, ddayLabel)
        views.setTextViewText(R.id.tv_course_name, courseName)
        views.setTextViewText(R.id.tv_status_message, message)
        views.setTextViewText(R.id.tv_temp, temp)
        views.setTextViewText(R.id.tv_rain, "🌧 $rainProb")
        views.setTextViewText(R.id.tv_wind, "💨 $windSpeed")
        views.setTextViewText(R.id.tv_cancel, cancelMsg)

        appWidgetManager.updateAppWidget(widgetId, views)
    }
}
