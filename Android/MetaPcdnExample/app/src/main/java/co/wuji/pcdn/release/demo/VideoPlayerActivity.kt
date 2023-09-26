package co.wuji.pcdn.release.demo

import android.os.Bundle
import android.text.TextUtils
import android.util.Log
import android.widget.CompoundButton
import android.widget.CompoundButton.OnCheckedChangeListener
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import co.meta.pcdn.IPCDNManagerEventHandler
import co.meta.pcdn.IPCDNManagerEventHandler.DATA_SOURCE_TYPE
import co.meta.pcdn.MetaPCDNLogFilter
import co.meta.pcdn.MetaPcdnClient
import co.meta.pcdn.MetaPcdnClientConfig
import co.wuji.pcdn.release.demo.aliyunplayer.widget.AliyunRenderView
import co.wuji.pcdn.release.demo.databinding.ActivityVideoPlayerBinding
import com.aliyun.player.IPlayer
import com.aliyun.player.IPlayer.OnInfoListener
import com.aliyun.player.IPlayer.OnSeiDataListener
import com.aliyun.player.IPlayer.OnStateChangedListener
import com.aliyun.player.bean.InfoBean
import com.aliyun.player.source.UrlSource
import java.text.SimpleDateFormat
import java.util.*
import kotlin.random.Random


class SampleCounter {
    fun recvFirstFrame() {
        val currTs = System.currentTimeMillis()
        if (!is_recv_first) {
            recv_first_cost_ms = currTs - startTs
            is_recv_first = true;
        }
    }

    fun addSample(timeStamp: Long, tag : String) {
        val currTs = System.currentTimeMillis()

        while (activeTimes.size > 0 && (currTs - activeTimes[0] > kMaxMs)) {
            activeTimes.removeAt(0)
            frozenTimes.removeAt(0)
        }

        if (lastTimeStamp < 0) {
            lastTimeStamp = timeStamp;
        }

        if (timeStamp - lastTimeStamp > kMaxFreezeMs) {
            activeTimes.add(currTs)
            frozenTimes.add(timeStamp - lastTimeStamp)
            total_freeze_time_ms += (timeStamp - lastTimeStamp)
        }
        lastTimeStamp = timeStamp;

        if (currTs - 2000 > lastLogStats) {
            var frozenTotal = 0L;
            frozenTimes.forEach {
                frozenTotal += it;
            }
            var avg_freeze_rate =  (total_freeze_time_ms * 1.0 / (currTs - startTs) * 10000).toInt() * 1.0 / 100
            if (tag.equals("ALI ")) {
                Log.v("SampleCounter", "$tag 100s freeze rate: ${Rate()}, frozenTotal: ${frozenTotal}, avg_freeze_rate: ${avg_freeze_rate}, first_frame: ${recv_first_cost_ms}")
            } else {
                Log.w("SampleCounter", "$tag 100s freeze rate: ${Rate()}, frozenTotal: ${frozenTotal}, avg_freeze_rate: ${avg_freeze_rate}, first_frame: ${recv_first_cost_ms}")
            }
            lastLogStats = currTs
        }
    }

    fun Rate(): Float {
        if (frozenTimes.size <= 0) {
            return 0f
        }

        var frozenTotal = 0L;
        frozenTimes.forEach {
            frozenTotal += it;
        }

        return ((frozenTotal * 1f / kMaxMs * 10000).toInt() * 1f) / 100
    }

    fun SetStartTs(ts : Long) {
        startTs = ts
        is_recv_first = false
    }

    private var startTs = 0L
    public var recv_first_cost_ms = 0L
    private var is_recv_first = false

    private var lastLogStats = -1L
    private var total_freeze_time_ms = 0L
    private var total_active_time_ms = 0L

    private var lastTimeStamp = -1L
    private val frozenTimes = ArrayList<Long>()
    private val activeTimes = ArrayList<Long>()

    private val kMaxMs = 100 * 1000
    private val kMaxFreezeMs = 100


}

class VideoPlayerActivity : AppCompatActivity() {
    private val TAG = "VideoPlayerActivity"
    private var mCurrentUrl = ""
    private var mCurrentUrl2 = "" //第二个播放器的url
    private var mCurrentPlaying= "" //当前正在播放的url
    private var mServerType = 200

    private var mPlayerState = 0
    private var mPlayer2State = 0
    private var mBoxIp =""
    private var mVid =""
    private var mToken = ""
    private var mUrlExpireTimeSec = 20 //url有效期,建议大于10秒

    private lateinit var mAliyunPlayerBinding: ActivityVideoPlayerBinding

    var player1SampleCounter : SampleCounter = SampleCounter()
    var player2SampleCounter : SampleCounter = SampleCounter()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        mAliyunPlayerBinding = ActivityVideoPlayerBinding.inflate(layoutInflater)
        setContentView(mAliyunPlayerBinding.root)
        initPlayerConfig()
        initView()

        var metaPcdnClientConfig= MetaPcdnClientConfig()
        metaPcdnClientConfig.mContext = BaseApplication.INSTANCE
        metaPcdnClientConfig.mCId = "00000000000000000000000000000001"
        MetaPcdnClient.getInstance().create(metaPcdnClientConfig)
        initPcdnLog()
        mAliyunPlayerBinding.tvVersion.text = "version: ${MetaPcdnClient.getInstance().sdkVersion}"
    }

    private fun initPcdnLog() {
        val format = SimpleDateFormat("yyyy-MM-dd_HH_mm_ss")
        val logName = "${format.format(Date(System.currentTimeMillis()))}-pcdn.log"
        val logfile = "${BaseApplication.INSTANCE.externalCacheDir?.absolutePath}/log/$logName"
        MetaPcdnClient.getInstance().setLogFilter(MetaPCDNLogFilter.LOG_FILTER_INFO)
        MetaPcdnClient.getInstance().setLogFile(logfile,600*1024)
    }


    private fun initView() {
        mCurrentUrl = intent.getStringExtra("video_url")
        if (TextUtils.isEmpty(mCurrentUrl)) {
            mCurrentUrl = "rtmp://221.13.203.66:31935/live/test_1080p_3m_baseline_25fps_150min"
        }
        mCurrentUrl2 = mCurrentUrl

        mAliyunPlayerBinding.checkboxSync.setOnCheckedChangeListener(object :
            OnCheckedChangeListener {
            override fun onCheckedChanged(p0: CompoundButton, checked: Boolean) {
                //暂时当一个主动开关 播放过程中选中时 判断如果上边在播放而下边暂停的话 开始播放下面的
                //取消选中时如果下边的正在播放则停止
                if (checked){
                    if (mPlayerState==3 && mPlayer2State!=3){
                        startPlay2(mCurrentUrl2)
                    }
                }else{
                    if (mPlayerState==3 && mPlayer2State==3){
                        mAliyunPlayerBinding.aliPlayer2.stop()
                    }
                }
            }
        })

        mAliyunPlayerBinding.tvUrl.setText(mCurrentUrl)
        mAliyunPlayerBinding.btnPlay.setOnClickListener {
            var code = -22

            code = MetaPcdnClient.getInstance().setParameters("{\"server_url_type\":$mServerType}")
            code = MetaPcdnClient.getInstance().setParameters("{\"enable_time_stretch\":false}")
            var curr_ts = System.currentTimeMillis()
            if (!TextUtils.isEmpty(mCurrentPlaying)){
                mAliyunPlayerBinding.aliPlayer.stop()
                MetaPcdnClient.getInstance().destroyLocalStreamUrl(mCurrentPlaying)
                Log.d(TAG, "createLocalStreamUrl  destroyLocalStreamUrl cost : ${System.currentTimeMillis() - curr_ts}")
            }
            //当不是动态url的时候，vid就直接使用url
            mVid = mCurrentUrl
            val result = MetaPcdnClient.getInstance().createLocalStreamUrl(mCurrentUrl,mVid,mToken)
            Log.d(TAG, "createLocalStreamUrl  createLocalStreamUrl cost : ${System.currentTimeMillis() - curr_ts}")

//            MetaPcdnClient.getInstance().updateRemoteStreamUrl(result, mCurrentUrl, mUrlExpireTimeSec)
            if (!TextUtils.isEmpty(result)) {
                curr_ts = System.currentTimeMillis()
                player1SampleCounter.SetStartTs(curr_ts)
                startPlay(result)
                if (mAliyunPlayerBinding.checkboxSync.isChecked){
                    curr_ts = System.currentTimeMillis()
                    player2SampleCounter.SetStartTs(curr_ts)
                    startPlay2(mCurrentUrl2)
                }
                mCurrentPlaying = result
            }
            Log.d(TAG, "createLocalStreamUrl  output : $result , code = $code")
        }

        MetaPcdnClient.getInstance().setPCDNManagerHandler(object : IPCDNManagerEventHandler {
            override fun OnWarning(remote_stream_url: String?,output_local_url: String,vid: String, warn: Int, msg: String?) {
                Log.d(TAG, "OnWarning: url = $remote_stream_url ,output_local_url = $output_local_url, vid= $vid,  warn = $warn , msg = $msg")
            }

            override fun OnError(remote_stream_url: String?,output_local_url: String,vid: String, err: Int, msg: String?) {
                Log.d(TAG, "OnError: url = $remote_stream_url ,output_local_url = $output_local_url, vid= $vid,  err = $err , msg = $msg")
            }

            override fun OnDataSource(remote_stream_url: String, output_local_url: String,vid: String,type: DATA_SOURCE_TYPE,box_ip : String) {
                Log.d(TAG, "OnDataSource: url = $remote_stream_url , output_local_url = $output_local_url, vid= $vid,  type = $type")
                runOnUiThread {
                    if (remote_stream_url.equals(mCurrentUrl)) {
                        mAliyunPlayerBinding.tvTips1.text =
                            if (type == DATA_SOURCE_TYPE.DATA_SOURCE_CDN) "SOURCE : CDN" else if (type == DATA_SOURCE_TYPE.DATA_SOURCE_RTC) "SOURCE : RTC" else "UNKNOWN"

                        mBoxIp = box_ip
                        getVideoInfo()
                    }
                }

            }

            override fun OnTokenWillExpire(
                remote_stream_url: String,
                output_local_url: String,
                vid: String,
                token: String
            ) {
                Log.d(TAG, "OnTokenWillExpire: url = $remote_stream_url ,output_local_url = $output_local_url, vid= $vid, token = $token")
            }

            override fun OnTokenExpired(
                remote_stream_url: String,
                output_local_url: String,
                vid: String,
                errorcode: Int
            ) {
                Log.d(TAG, "OnTokenExpired: url = $remote_stream_url ,output_local_url = $output_local_url, vid= $vid, errorcode = $errorcode")
            }

            override fun OnRemoteStreamUrlExpired(
                remote_stream_url: String,
                output_local_url: String,
                vid: String
            ) {
                Log.e(TAG, "OnRemoteStreamUrlExpired: url = $remote_stream_url ,output_local_url = $output_local_url, vid= $vid")
//                if (mCurrentPlaying == output_local_url) {
//                    val new_remote_stream_url = mCurrentUrl + Math.abs(Random(System.currentTimeMillis()).nextInt()).toString();
//                    MetaPcdnClient.getInstance().updateRemoteStreamUrl(output_local_url, new_remote_stream_url, mUrlExpireTimeSec)
//                    Log.d(TAG, "update OnRemoteStreamUrlWillExpire: url = $new_remote_stream_url ,output_local_url = $output_local_url, vid= $vid")
//                }
            }
        })

    }

    /**
     * 获取实时渲染帧率、音视频码率、网络下行码率
     */
    private fun getVideoInfo(){
        mAliyunPlayerBinding.aliPlayer.aliPlayer?.run {
            //获取当前渲染的帧率，数据类型为Float。
            val renderFPS = getOption(IPlayer.Option.RenderFPS)
            //获取当前播放的视频码率，数据类型为Float，单位为bps。
            val videoBitrate = getOption(IPlayer.Option.VideoBitrate).toString().toFloat()
            //获取当前播放的音频码率，数据类型为Float，单位为bps。
            val audioBitrate = getOption(IPlayer.Option.AudioBitrate).toString().toFloat()
            //获取当前的网络下行码率，数据类型为Float，单位为bps。
            val downloadBitrate = getOption(IPlayer.Option.DownloadBitrate).toString().toFloat()

            mAliyunPlayerBinding.tvInfo.text = "帧率: $renderFPS\n视频码率: ${String.format("%.2f", videoBitrate/1024)} kbs\n音频码率: ${String.format("%.2f", audioBitrate/1024)} kbs\n网络下行码率: ${String.format("%.2f", downloadBitrate/1024)} kbs\n首帧时间: ${player1SampleCounter.recv_first_cost_ms} ms\n盒子地址: $mBoxIp"
        }

        mAliyunPlayerBinding.aliPlayer2.aliPlayer?.run {
            //获取当前渲染的帧率，数据类型为Float。
            val renderFPS = getOption(IPlayer.Option.RenderFPS)
            //获取当前播放的视频码率，数据类型为Float，单位为bps。
            val videoBitrate = getOption(IPlayer.Option.VideoBitrate).toString().toFloat()
            //获取当前播放的音频码率，数据类型为Float，单位为bps。
            val audioBitrate = getOption(IPlayer.Option.AudioBitrate).toString().toFloat()
            //获取当前的网络下行码率，数据类型为Float，单位为bps。
            val downloadBitrate = getOption(IPlayer.Option.DownloadBitrate).toString().toFloat()

            mAliyunPlayerBinding.tvInfo2.text = "帧率: $renderFPS\n视频码率: ${String.format("%.2f", videoBitrate/1024)} kbs\n音频码率: ${String.format("%.2f", audioBitrate/1024)} kbs\n网络下行码率: ${String.format("%.2f", downloadBitrate/1024)} kbs\n首帧时间: ${player2SampleCounter.recv_first_cost_ms} ms"
        }
    }

    //播放器配置
    private fun initPlayerConfig(){
        mAliyunPlayerBinding.aliPlayer.setTraceID("RTC")
        mAliyunPlayerBinding.aliPlayer.setOnVideoRenderedListener { pts, timestamp ->
            //Log.w(TAG, " PCDN setOnVideoRenderedListener: pts = $pts , timestamp = $timestamp")
            player1SampleCounter.addSample(timestamp / 1000, "PCDN")
        }

        mAliyunPlayerBinding.aliPlayer.setOnRenderingStartListener {
            //首帧时间
            player1SampleCounter.recvFirstFrame()
        }

        mAliyunPlayerBinding.aliPlayer2.setOnVideoRenderedListener { pts, timestamp ->
            //Log.d(TAG, " 2aliPlayer2 setOnVideoRenderedListener: pts = $pts , timestamp = $timestamp")
            player2SampleCounter.addSample(timestamp / 1000, "ALI ")
        }

        mAliyunPlayerBinding.aliPlayer2.setOnRenderingStartListener {
            //首帧时间
            player2SampleCounter.recvFirstFrame()
        }

        mAliyunPlayerBinding.aliPlayer.playerConfig =  mAliyunPlayerBinding.aliPlayer.playerConfig.apply {
            mNetworkRetryCount = 10
            mNetworkTimeout = 60*1000

            //最大延迟。注意：直播有效。当延时比较大时，播放器sdk内部会追帧等，保证播放器的延时在这个范围内。
            mMaxDelayTime = 3000;
// 最大缓冲区时长。单位ms。播放器每次最多加载这么长时间的缓冲数据。

            mMaxBufferDuration = 50000;
//高缓冲时长。单位ms。当网络不好导致加载数据时，如果加载的缓冲时长到达这个值，结束加载状态。
            mHighBufferDuration = 3000;

// 起播缓冲区时长。单位ms。这个时间设置越短，起播越快。也可能会导致播放之后很快就会进入加载状态。
            mStartBufferDuration = 500;

//往前缓存的最大时长。单位ms。默认为0。
            mMaxBackwardBufferDurationMs = 0;
            mEnableSEI = true
            mClearFrameWhenStop =false
        }


        mAliyunPlayerBinding.aliPlayer2.setTraceID("CDN")
        mAliyunPlayerBinding.aliPlayer2.playerConfig =  mAliyunPlayerBinding.aliPlayer2.playerConfig.apply {
            mNetworkRetryCount = 10
            mNetworkTimeout = 60*1000

            //最大延迟。注意：直播有效。当延时比较大时，播放器sdk内部会追帧等，保证播放器的延时在这个范围内。
            mMaxDelayTime = 3000;
// 最大缓冲区时长。单位ms。播放器每次最多加载这么长时间的缓冲数据。

            mMaxBufferDuration = 50000;
//高缓冲时长。单位ms。当网络不好导致加载数据时，如果加载的缓冲时长到达这个值，结束加载状态。

            mHighBufferDuration = 3000;
// 起播缓冲区时长。单位ms。这个时间设置越短，起播越快。也可能会导致播放之后很快就会进入加载状态。
            mStartBufferDuration = 500;

//往前缓存的最大时长。单位ms。默认为0。
            mMaxBackwardBufferDurationMs = 0;
            mEnableSEI = true
            mClearFrameWhenStop =false
        }

        mAliyunPlayerBinding.aliPlayer.run {
            setSurfaceType(AliyunRenderView.SurfaceType.SURFACE_VIEW)
            setOnInfoListener(object : OnInfoListener {
                override fun onInfo(info: InfoBean) {
                    Log.d(TAG, "onInfo1: code = ${info.code} , extraMsg = ${info.extraMsg}")
                }
            })

            setOnStateChangedListener(object : OnStateChangedListener {
                override fun onStateChanged(state: Int) {
                    /**
                     * int idle = 0
                     * int initalized = 1
                     * int prepared = 2
                     * int started = 3
                     * int paused = 4
                     * int stopped = 5
                     * int completion = 6
                     * int error = 7
                     */
                    mPlayerState = state
                    Log.d(TAG, "player1 onStateChanged: $state")
                    if (state==7){
                        showLongToast("player1 error  state = $state")
                    }
                }
            })

            setOnSeiDataListener(object : OnSeiDataListener {
                override fun onSeiData(type: Int, data: ByteArray) {
                    Log.d(TAG, "onSeiData: type = $type , data = ${String(data)}")
                }
            })
        }

        mAliyunPlayerBinding.aliPlayer2.run {
            setSurfaceType(AliyunRenderView.SurfaceType.SURFACE_VIEW)
            setOnInfoListener(object : OnInfoListener {
                override fun onInfo(info: InfoBean) {
                    Log.d(TAG, "onInfo2: code = ${info.code} , extraMsg = ${info.extraMsg}")
                }
            })

            setOnStateChangedListener(object : OnStateChangedListener {
                override fun onStateChanged(state: Int) {
                    /**
                     * int idle = 0
                     * int initalized = 1
                     * int prepared = 2
                     * int started = 3
                     * int paused = 4
                     * int stopped = 5
                     * int completion = 6
                     * int error = 7
                     */
                    Log.d(TAG, "player2 onStateChanged : $state")
                    mPlayer2State = state
                    if (state==7){
                        showLongToast("player2 error  state = $state")
                    }
                }
            })

            setOnSeiDataListener(object : OnSeiDataListener {
                override fun onSeiData(type: Int, data: ByteArray) {
                    Log.d(TAG, "onSeiData: default type = $type , data = ${String(data)}")
                }
            })
        }
    }

    //上面的播放器
    private fun startPlay(url : String){
        val urlSource = UrlSource()
        urlSource.uri = url

        mAliyunPlayerBinding.aliPlayer.run {
            stop()
            setAutoPlay(true)
            setDataSource(urlSource)
            prepare()
            start()
        }

    }

    //下面的播放器
    private fun startPlay2(url : String){
        val urlSource = UrlSource()
        urlSource.uri = url

        mAliyunPlayerBinding.aliPlayer2.run {
            stop()
            setAutoPlay(true)
            setDataSource(urlSource)
            prepare()
            start()
        }

    }

    private fun showLongToast(msg : String){
        Toast.makeText(this,msg,Toast.LENGTH_LONG).show()
    }


    override fun onResume() {
        super.onResume()
        mAliyunPlayerBinding.aliPlayer?.start()
        mAliyunPlayerBinding.aliPlayer2?.start()
    }

    override fun onStop() {
        super.onStop()
        mAliyunPlayerBinding.aliPlayer?.pause()
        mAliyunPlayerBinding.aliPlayer2?.pause()
    }

    override fun onDestroy() {
        super.onDestroy()
        mAliyunPlayerBinding.aliPlayer?.release()
        mAliyunPlayerBinding.aliPlayer2?.release()
        MetaPcdnClient.getInstance().destroyLocalStreamUrl(mCurrentPlaying)
    }
}