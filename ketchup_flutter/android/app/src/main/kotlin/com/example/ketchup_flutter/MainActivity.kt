package com.example.ketchup_flutter

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Android 15+ edge-to-edge 기본 동작에 맞춰 시스템 바 인셋 처리를 활성화합니다.
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
