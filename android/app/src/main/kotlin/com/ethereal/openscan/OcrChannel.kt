package com.ethereal.openscan

import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import com.googlecode.tesseract.android.TessBaseAPI
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicReference

/**
 * Tesseract, bound directly to a method channel.
 *
 * The pub plugin that wraps this same native library (flutter_tesseract_ocr)
 * cannot be used: its Gradle script calls jcenter() and compileSdkVersion
 * from its own AGP 7 buildscript, so under this project's AGP 9 the plugin
 * project fails to evaluate before any of it runs. Binding the library here
 * is a few dozen lines and removes that whole class of breakage -- and lets
 * word boxes come back in one call with the text, which the plugin only
 * offered as hOCR to re-parse.
 */
class OcrChannel(messenger: io.flutter.plugin.common.BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.ethereal.openscan/ocr"

        /** Word boxes below this confidence are dropped. */
        private const val MIN_WORD_CONFIDENCE = 40f
    }

    private val channel = MethodChannel(messenger, CHANNEL).also {
        it.setMethodCallHandler(this)
    }

    /**
     * One page at a time, on one thread that is never the platform thread.
     *
     * Tesseract holds native state per instance, so concurrent recognition
     * would need an instance each -- and each instance loads its own copy of
     * the language model, which is the memory that actually matters on a
     * phone. Pages are queued instead.
     */
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /**
     * The running API handle, so [stop] can interrupt from the platform
     * thread while the executor thread is inside getUTF8Text().
     */
    private val running = AtomicReference<TessBaseAPI?>(null)

    /** Kept between pages: init() re-reads the language model from disk. */
    private var api: TessBaseAPI? = null
    private var initialisedFor: String? = null

    fun dispose() {
        executor.execute {
            api?.recycle()
            api = null
            initialisedFor = null
        }
        executor.shutdown()
        channel.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // Interrupts the page being recognized now. Deliberately handled
            // on the platform thread rather than queued behind the work it
            // is meant to cancel.
            "stop" -> {
                running.get()?.stop()
                result.success(null)
            }
            "recognize" -> {
                val imagePath = call.argument<String>("imagePath")
                val dataPath = call.argument<String>("dataPath")
                val language = call.argument<String>("language") ?: "eng"
                if (imagePath == null || dataPath == null) {
                    result.error("bad_args", "imagePath and dataPath required", null)
                    return
                }
                executor.execute { recognize(imagePath, dataPath, language, result) }
            }
            else -> result.notImplemented()
        }
    }

    private fun reply(result: MethodChannel.Result, body: () -> Unit) = main.post(body)

    private fun recognize(
        imagePath: String,
        dataPath: String,
        language: String,
        result: MethodChannel.Result,
    ) {
        val image = File(imagePath)
        if (!image.exists()) {
            reply(result) { result.error("no_image", "No such image: $imagePath", null) }
            return
        }

        val tess: TessBaseAPI
        try {
            tess = prepare(dataPath, language)
        } catch (e: Throwable) {
            reply(result) {
                result.error("init_failed", "Could not load '$language': ${e.message}", null)
            }
            return
        }

        try {
            running.set(tess)
            tess.setImage(image)

            // Pulled before the iterator: getUTF8Text() is what actually runs
            // recognition, and the iterator reads the layout it leaves behind.
            val text = tess.getUTF8Text() ?: ""
            val words = ArrayList<Map<String, Any>>()

            val iterator = tess.resultIterator
            if (iterator != null) {
                val level = TessBaseAPI.PageIteratorLevel.RIL_WORD
                iterator.begin()
                do {
                    val word = iterator.getUTF8Text(level)?.trim()
                    if (word.isNullOrEmpty()) continue
                    val confidence = iterator.confidence(level)
                    if (confidence < MIN_WORD_CONFIDENCE) continue
                    val box = iterator.getBoundingRect(level)
                    if (box == null || box.width() <= 0 || box.height() <= 0) continue
                    words.add(
                        mapOf(
                            "text" to word,
                            "confidence" to confidence.toDouble(),
                            "left" to box.left,
                            "top" to box.top,
                            "right" to box.right,
                            "bottom" to box.bottom,
                        )
                    )
                } while (iterator.next(level))
                iterator.delete()
            }

            // The page's own pixel size, so the Dart side can express every
            // box as a fraction of it and stay correct after the page is
            // re-encoded smaller on the way into a PDF.
            val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
            BitmapFactory.decodeFile(imagePath, bounds)

            val payload = mapOf(
                "text" to text,
                "words" to words,
                "width" to bounds.outWidth,
                "height" to bounds.outHeight,
                "language" to language,
            )
            reply(result) { result.success(payload) }
        } catch (e: Throwable) {
            reply(result) {
                result.error("recognize_failed", e.message ?: e.toString(), null)
            }
        } finally {
            running.set(null)
            // Frees the page's native image without dropping the loaded
            // language model, which is the expensive half.
            try {
                tess.clear()
            } catch (_: Throwable) {
            }
        }
    }

    /** The shared API handle, re-initialised only when the language changes. */
    private fun prepare(dataPath: String, language: String): TessBaseAPI {
        val existing = api
        if (existing != null && initialisedFor == language) return existing

        existing?.recycle()
        api = null
        initialisedFor = null

        val fresh = TessBaseAPI()
        // LSTM only. The legacy engine needs the larger traineddata files
        // this app does not ship, and silently recognizes nothing without
        // them.
        if (!fresh.init(dataPath, language, TessBaseAPI.OEM_LSTM_ONLY)) {
            fresh.recycle()
            throw IllegalStateException("tessdata for '$language' not found under $dataPath")
        }
        fresh.pageSegMode = TessBaseAPI.PageSegMode.PSM_AUTO_OSD
        api = fresh
        initialisedFor = language
        return fresh
    }
}
