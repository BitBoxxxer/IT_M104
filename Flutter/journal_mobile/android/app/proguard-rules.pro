# Сохраняем Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class * extends com.dexterous.flutterlocalnotifications.NotificationBroadcastReceiver {
    public <init>();
}
-keep class * extends com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver {
    public <init>();
}

# Gson (используется Flutter Local Notifications)
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod

# Сохраняем generic типы для Gson TypeToken
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken

# Сохраняем классы уведомлений
-keep class * extends androidx.core.app.NotificationCompat$Style { *; }
-keep class * extends androidx.core.app.NotificationCompat$WearableExtender { *; }