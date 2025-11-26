package com.example.journal_mobile

import android.app.Application
import androidx.multidex.MultiDex

class JournalApp : Application() {
    override fun onCreate() {
        super.onCreate()
        MultiDex.install(this)
    }
}