package com.calllog.call_log_viewer

import android.os.Bundle
import android.view.View
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import android.graphics.Color
import androidx.core.view.WindowCompat

class MainActivity: FlutterActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        // 在super.onCreate之前设置，确保生效
        setupEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
    
    private fun setupEdgeToEdge() {
        // 设置边到边显示
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        window.apply {
            // 清除半透明标志
            clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)
            clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_NAVIGATION)
            
            // 添加绘制系统栏背景的标志
            addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
            
            // 设置完全透明
            statusBarColor = Color.TRANSPARENT
            navigationBarColor = Color.TRANSPARENT
        }
        
        // 设置系统UI可见性标志 - 让内容延伸到系统栏区域
        @Suppress("DEPRECATION")
        window.decorView.systemUiVisibility = (
            View.SYSTEM_UI_FLAG_LAYOUT_STABLE
            or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        )
        
        // 使用WindowInsetsController控制系统栏图标颜色
        val windowInsetsController = WindowCompat.getInsetsController(window, window.decorView)
        windowInsetsController?.apply {
            // 深色背景用浅色图标
            isAppearanceLightStatusBars = false
            // 浅色导航栏用深色图标
            isAppearanceLightNavigationBars = true
        }
    }
}


