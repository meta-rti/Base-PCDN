package co.wuji.pcdn.release.demo

import android.Manifest
import android.content.Intent
import android.os.Bundle
import android.text.TextUtils
import android.view.View
import android.widget.AdapterView
import android.widget.ArrayAdapter
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.app.ActivityCompat
import co.wuji.pcdn.release.demo.databinding.ActivityMainBinding
import co.wuji.pcdn.release.demo.utils.CommonUtils
import com.gyf.immersionbar.ImmersionBar

class MainActivity : AppCompatActivity() {
    private val TAG = "MainActivity"
    private val SPKEYURL = "video_url"
    private var mUrl = ""
    private val mUrlArray = arrayOf(
        "rtmp://221.13.203.66:31935/live/test_1080p_3m_baseline_25fps_150min",
        "rtmp://221.13.203.66:31935/live/test_360p_1m_baseline_25fps_150min"
    )

    private val PERMISSION_REQ_CODE = 10000
    private val PERMISSIONS = arrayOf(
        Manifest.permission.WRITE_EXTERNAL_STORAGE,
        Manifest.permission.READ_EXTERNAL_STORAGE
    )

    private lateinit var mMainBinding: ActivityMainBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 避免从桌面启动程序后，会重新实例化入口类的activity
        if (!this.isTaskRoot) { // 当前类不是该Task的根部，那么之前启动过
            val intent = intent
            if (intent != null) {
                val action = intent.action
                if (intent.hasCategory(Intent.CATEGORY_LAUNCHER) && Intent.ACTION_MAIN == action) { // 当前类是从桌面启动的
                    finish() // finish掉该类，直接打开该Task中现存的Activity
                    return
                }
            }
        }

        ImmersionBar.with(this)
            .transparentBar()
            .statusBarDarkFont(true)
            .init() //必须调用方可应用以上所配置的参数

        mMainBinding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(mMainBinding.root)

        requestPermission()
        initView()
    }

    private fun requestPermission() {
        ActivityCompat.requestPermissions(this, PERMISSIONS, PERMISSION_REQ_CODE)
    }


    private fun initView() {
        var spinnerAdapter = ArrayAdapter<String>(this,R.layout.item_spinner_dropdown,mUrlArray)
        spinnerAdapter.setDropDownViewResource(R.layout.item_spinner_dropdown)

        mMainBinding.spinnerUrl.adapter = spinnerAdapter
        mMainBinding.spinnerUrl.onItemSelectedListener =
            object : AdapterView.OnItemSelectedListener {
                override fun onItemSelected(
                    parent: AdapterView<*>?,
                    view: View?,
                    position: Int,
                    id: Long
                ) {

                    mUrl = mUrlArray[position]
                    mMainBinding.edtUrl.setText(mUrl)
                }

                override fun onNothingSelected(parent: AdapterView<*>?) {

                }
            }


        mMainBinding.btnPlay.setOnClickListener {
            mUrl = mMainBinding.edtUrl.text.toString()
            if (CommonUtils.fastClick(3000)) {
                return@setOnClickListener
            }

            if (TextUtils.isEmpty(mUrl)) {
                showToast("invalid url.")
                return@setOnClickListener
            }
            if (!mUrl.startsWith("rtmp")){
                showToast("invalid url.")
                return@setOnClickListener
            }

            startActivity(
                Intent(
                    this@MainActivity,
                    VideoPlayerActivity::class.java
                ).apply {
                    putExtra(SPKEYURL, mUrl)
                })
        }
    }

    private fun showToast(msg : String){
        Toast.makeText(this,msg,Toast.LENGTH_SHORT).show()
    }

}