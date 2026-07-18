package com.golfwindy.app

import android.Manifest
import android.content.ContentUris
import android.content.pm.PackageManager
import android.os.Build
import android.provider.CalendarContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val calendarChannelName = "golf_windy/calendar"
    private val calendarPermissionRequestCode = 4107
    private var pendingCalendarResult: MethodChannel.Result? = null
    private var pendingCalendarRange: Pair<Long, Long>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, calendarChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "findGolfEvents" -> {
                        val startMillis = call.argument<Number>("startMillis")?.toLong()
                        val endMillis = call.argument<Number>("endMillis")?.toLong()
                        if (startMillis == null || endMillis == null) {
                            result.error(
                                "invalid_args",
                                "캘린더 조회 기간이 전달되지 않았습니다.",
                                null
                            )
                            return@setMethodCallHandler
                        }

                        findCalendarEvents(startMillis, endMillis, result)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun findCalendarEvents(
        startMillis: Long,
        endMillis: Long,
        result: MethodChannel.Result
    ) {
        if (!hasCalendarPermission()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                pendingCalendarResult = result
                pendingCalendarRange = startMillis to endMillis
                requestPermissions(
                    arrayOf(Manifest.permission.READ_CALENDAR),
                    calendarPermissionRequestCode
                )
            } else {
                result.success(mapOf("permissionGranted" to false, "events" to emptyList<Map<String, Any?>>()))
            }
            return
        }

        result.success(
            mapOf(
                "permissionGranted" to true,
                "events" to readCalendarEvents(startMillis, endMillis)
            )
        )
    }

    private fun hasCalendarPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
            checkSelfPermission(Manifest.permission.READ_CALENDAR) == PackageManager.PERMISSION_GRANTED
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != calendarPermissionRequestCode) return

        val result = pendingCalendarResult ?: return
        val range = pendingCalendarRange
        pendingCalendarResult = null
        pendingCalendarRange = null

        val granted = grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED
        if (!granted || range == null) {
            result.success(mapOf("permissionGranted" to false, "events" to emptyList<Map<String, Any?>>()))
            return
        }

        result.success(
            mapOf(
                "permissionGranted" to true,
                "events" to readCalendarEvents(range.first, range.second)
            )
        )
    }

    private fun readCalendarEvents(startMillis: Long, endMillis: Long): List<Map<String, Any?>> {
        val builder = CalendarContract.Instances.CONTENT_URI.buildUpon()
        ContentUris.appendId(builder, startMillis)
        ContentUris.appendId(builder, endMillis)

        val projection = arrayOf(
            CalendarContract.Instances.EVENT_ID,
            CalendarContract.Instances.TITLE,
            CalendarContract.Instances.EVENT_LOCATION,
            CalendarContract.Instances.DESCRIPTION,
            CalendarContract.Instances.BEGIN,
            CalendarContract.Instances.END,
            CalendarContract.Instances.ALL_DAY
        )

        val events = mutableListOf<Map<String, Any?>>()
        contentResolver.query(
            builder.build(),
            projection,
            null,
            null,
            "${CalendarContract.Instances.BEGIN} ASC"
        )?.use { cursor ->
            val eventIdIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_ID)
            val titleIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.TITLE)
            val locationIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.EVENT_LOCATION)
            val descriptionIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.DESCRIPTION)
            val beginIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.BEGIN)
            val endIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.END)
            val allDayIndex = cursor.getColumnIndexOrThrow(CalendarContract.Instances.ALL_DAY)

            while (cursor.moveToNext() && events.size < 200) {
                events.add(
                    mapOf(
                        "id" to cursor.getLong(eventIdIndex).toString(),
                        "title" to cursor.getString(titleIndex).orEmpty(),
                        "location" to cursor.getString(locationIndex).orEmpty(),
                        "description" to cursor.getString(descriptionIndex).orEmpty(),
                        "startMillis" to cursor.getLong(beginIndex),
                        "endMillis" to cursor.getLong(endIndex),
                        "allDay" to (cursor.getInt(allDayIndex) == 1)
                    )
                )
            }
        }

        return events
    }
}
