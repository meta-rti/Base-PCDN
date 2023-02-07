package co.meta.pcdnexample.utils

import android.content.Context
import android.util.DisplayMetrics
import android.view.WindowManager
import co.meta.pcdnexample.BaseApplication

/**
 * @author chunping
 * @time 2023/2/7 11:51 AM
 * @describe describe
 */
object CommonUtils {
    var SCREEN_WIDTH = getWindowWidth(BaseApplication.INSTANCE)
    var SCREEN_HEIGHT = getWindowHeight(BaseApplication.INSTANCE)


    /**
     * 根据手机的分辨率从 dp 的单位 转成为 px(像素)
     */
    fun dip2px(dpValue: Float): Int {
        val scale = BaseApplication.INSTANCE.resources.displayMetrics.density
        return (dpValue * scale + 0.5f).toInt()
    }

    private fun getWindowWidth(context: Context): Int {
        val metric = DisplayMetrics()
        val mWindowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        mWindowManager.defaultDisplay.getMetrics(metric)
        return metric.widthPixels
    }


    private fun getWindowHeight(context: Context): Int {
        val metric = DisplayMetrics()
        val mWindowManager = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        mWindowManager.defaultDisplay.getMetrics(metric)
        return metric.heightPixels
    }

    private var mLastClickTime = 0L
    fun fastClick(duration: Long): Boolean {
        val currentTime = System.currentTimeMillis()
        return if (currentTime - mLastClickTime < duration) {
            true
        } else {
            mLastClickTime = currentTime
            false
        }
    }
}
