package co.wuji.pcdn.release.demo

import android.app.Application

/**
 * @author chunping
 * @time 2023/2/7 11:46 AM
 * @describe describe
 */
class BaseApplication : Application(){


    companion object {
        lateinit var INSTANCE: BaseApplication
    }

    override fun onCreate() {
        super.onCreate()
        INSTANCE=this
    }

}
