package com.fasttunnel.networktest

import android.content.Context
import android.graphics.Color
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.gms.ads.nativead.AdChoicesView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin
import io.flutter.plugins.googlemobileads.NativeAdFactory

class MainActivity : FlutterActivity() {
    private val nativeFactoryId = "fastTunnelNativeAd"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            nativeFactoryId,
            FastTunnelNativeAdFactory(this)
        )
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, nativeFactoryId)
        super.cleanUpFlutterEngine(flutterEngine)
    }
}

class FastTunnelNativeAdFactory(private val context: Context) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: Map<String, Any>?
    ): NativeAdView {
        val adView = NativeAdView(context)
        adView.setBackgroundColor(Color.TRANSPARENT)

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(28, 18, 28, 18)
        }

        val topRow = FrameLayout(context)
        val label = TextView(context).apply {
            text = "Advertisement"
            textSize = 11f
            setTextColor(Color.rgb(140, 155, 175))
        }
        topRow.addView(
            label,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.START
            )
        )
        val adChoices = AdChoicesView(context)
        topRow.addView(
            adChoices,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.END
            )
        )
        adView.adChoicesView = adChoices

        val headline = TextView(context).apply {
            text = nativeAd.headline
            textSize = 16f
            setTextColor(Color.WHITE)
            maxLines = 1
        }
        val body = TextView(context).apply {
            text = nativeAd.body ?: nativeAd.advertiser ?: ""
            textSize = 13f
            setTextColor(Color.rgb(190, 202, 218))
            maxLines = 2
            visibility = if (text.isNullOrBlank()) View.GONE else View.VISIBLE
        }
        val advertiser = TextView(context).apply {
            text = nativeAd.advertiser ?: ""
            textSize = 12f
            setTextColor(Color.rgb(140, 155, 175))
            maxLines = 1
            visibility = if (text.isNullOrBlank()) View.GONE else View.VISIBLE
        }

        container.addView(topRow)
        container.addView(headline)
        container.addView(body)
        container.addView(advertiser)
        adView.addView(container)

        adView.headlineView = headline
        adView.bodyView = body
        adView.advertiserView = advertiser
        adView.setNativeAd(nativeAd)
        return adView
    }
}
