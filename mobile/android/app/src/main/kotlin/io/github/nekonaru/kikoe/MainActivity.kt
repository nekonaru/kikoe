package io.github.nekonaru.kikoe

import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.nio.ByteBuffer
import java.nio.ByteOrder

class MainActivity : FlutterActivity() {
    private val channelName = "kikoe/decode"
    private val filesChannelName = "kikoe/files"
    private val decodeExecutor = java.util.concurrent.Executors.newSingleThreadExecutor()
    private val handler = android.os.Handler(android.os.Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method == "decode") {
                    val path = call.argument<String>("path")
                    if (path.isNullOrEmpty()) {
                        result.error("invalid_argument", "missing media path", null)
                        return@setMethodCallHandler
                    }
                    // Decode off the main thread so a long media file cannot
                    // stall the UI or trip the ANR watchdog.
                    decodeExecutor.execute {
                        try {
                            val pcm = decodeToFloat32Mono16k(path)
                            handler.post { result.success(pcm) }
                        } catch (e: Exception) {
                            handler.post {
                                result.error("decode_failed", e.message ?: "failed to decode media", null)
                            }
                        }
                    }
                } else {
                    result.notImplemented()
                }
            }
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, filesChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveToDownloads" -> {
                        val name = call.argument<String>("name")
                        val content = call.argument<String>("content")
                        if (name.isNullOrEmpty() || content == null) {
                            result.error("invalid_argument", "missing name or content", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(saveToDownloads(name, content))
                        } catch (e: Exception) {
                            result.error("save_failed", e.message ?: "could not save file", null)
                        }
                    }
                    "legacyStoragePermissionState" -> {
                        // 0 = not needed (API 29+), 1 = granted, 2 = denied.
                        if (android.os.Build.VERSION.SDK_INT >= 29) {
                            result.success(0)
                        } else if (checkSelfPermission(android.Manifest.permission.WRITE_EXTERNAL_STORAGE) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                            result.success(1)
                        } else {
                            result.success(2)
                        }
                    }
                    "requestLegacyStoragePermission" -> {
                        if (android.os.Build.VERSION.SDK_INT < 29) {
                            requestPermissions(
                                arrayOf(android.Manifest.permission.WRITE_EXTERNAL_STORAGE),
                                LEGACY_STORAGE_PERMISSION_CODE
                            )
                        }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        decodeExecutor.shutdownNow()
        super.onDestroy()
    }

    companion object {
        private const val LEGACY_STORAGE_PERMISSION_CODE = 4321
    }

    // Saves a transcript into Downloads/kikoe. On Android 10+ this goes
    // through the MediaStore so no storage permission is needed. On Android
    // 9 and below it writes directly and needs WRITE_EXTERNAL_STORAGE.
    // Returns a user-readable location string.
    private fun saveToDownloads(name: String, content: String): String {
        if (android.os.Build.VERSION.SDK_INT >= 29) {
            val values = android.content.ContentValues().apply {
                put(android.provider.MediaStore.Downloads.DISPLAY_NAME, name)
                put(android.provider.MediaStore.Downloads.RELATIVE_PATH, "Download/kikoe")
                put(android.provider.MediaStore.Downloads.MIME_TYPE, mimeFor(name))
                put(android.provider.MediaStore.Downloads.IS_PENDING, 1)
            }
            val collection = android.provider.MediaStore.Downloads.EXTERNAL_CONTENT_URI
            val uri = contentResolver.insert(collection, values)
                ?: throw IllegalStateException("MediaStore did not accept the file")
            try {
                contentResolver.openOutputStream(uri)?.use { stream ->
                    stream.write(content.toByteArray(Charsets.UTF_8))
                } ?: throw IllegalStateException("could not open output stream")
            } catch (e: Exception) {
                contentResolver.delete(uri, null, null)
                throw e
            }
            val done = android.content.ContentValues().apply {
                put(android.provider.MediaStore.Downloads.IS_PENDING, 0)
            }
            contentResolver.update(uri, done, null, null)
            return "Downloads/kikoe/$name"
        }

        @Suppress("DEPRECATION")
        val dir = java.io.File(
            android.os.Environment.getExternalStoragePublicDirectory(android.os.Environment.DIRECTORY_DOWNLOADS),
            "kikoe"
        )
        dir.mkdirs()
        val file = java.io.File(dir, name)
        file.writeText(content, Charsets.UTF_8)
        return file.absolutePath
    }

    private fun mimeFor(name: String): String = when {
        name.endsWith(".srt", ignoreCase = true) -> "application/x-subrip"
        name.endsWith(".vtt", ignoreCase = true) -> "text/vtt"
        name.endsWith(".txt", ignoreCase = true) -> "text/plain"
        name.endsWith(".json", ignoreCase = true) -> "application/json"
        else -> "text/plain"
    }

    // Decodes any media the platform supports to mono 16 kHz float32 PCM,
    // interleaved as little-endian bytes. Accepts plain file paths and
    // content:// or file:// URIs (both produced by SAF pickers and share
    // intents).
    private fun decodeToFloat32Mono16k(path: String): ByteArray {
        val extractor = MediaExtractor()
        // When the media is a content:// or file:// URI, MediaExtractor needs
        // a seekable FileDescriptor that stays open for the whole decode.
        var pfd: android.os.ParcelFileDescriptor? = null
        try {
            if (path.startsWith("content://") || path.startsWith("file://")) {
                val uri = android.net.Uri.parse(path)
                pfd = contentResolver.openFileDescriptor(uri, "r")
                    ?: throw IllegalArgumentException("cannot open media uri")
                extractor.setDataSource(pfd.fileDescriptor)
            } else {
                extractor.setDataSource(path)
            }
        } catch (e: Exception) {
            pfd?.close()
            extractor.release()
            throw e
        }

        var audioTrack = -1
        var format: MediaFormat? = null
        for (i in 0 until extractor.trackCount) {
            val f = extractor.getTrackFormat(i)
            val mime = f.getString(MediaFormat.KEY_MIME) ?: ""
            if (mime.startsWith("audio/")) {
                audioTrack = i
                format = f
                break
            }
        }
        if (audioTrack < 0 || format == null) {
            extractor.release()
            pfd?.close()
            throw IllegalArgumentException("no audio track found")
        }
        extractor.selectTrack(audioTrack)

        val mime = format.getString(MediaFormat.KEY_MIME)!!
        val sampleRate = format.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        val channels = maxOf(1, format.getInteger(MediaFormat.KEY_CHANNEL_COUNT))

        val decoder = MediaCodec.createDecoderByType(mime)
        decoder.configure(format, null, null, 0)
        decoder.start()

        val pcmBytes = ByteArrayOutputStream(1 shl 20)
        val info = MediaCodec.BufferInfo()
        var sawInputEOS = false
        var sawOutputEOS = false

        while (!sawOutputEOS) {
            if (!sawInputEOS) {
                val inIndex = decoder.dequeueInputBuffer(10_000)
                if (inIndex >= 0) {
                    val input = decoder.getInputBuffer(inIndex)!!
                    val bytesRead = extractor.readSampleData(input, 0)
                    if (bytesRead < 0) {
                        decoder.queueInputBuffer(
                            inIndex, 0, 0, 0,
                            MediaCodec.BUFFER_FLAG_END_OF_STREAM
                        )
                        sawInputEOS = true
                    } else {
                        decoder.queueInputBuffer(inIndex, 0, bytesRead, extractor.sampleTime, 0)
                        extractor.advance()
                    }
                }
            }

            val outIndex = decoder.dequeueOutputBuffer(info, 10_000)
            if (outIndex >= 0) {
                val output = decoder.getOutputBuffer(outIndex)!!
                output.position(info.offset)
                output.limit(info.offset + info.size)
                val chunk = ByteArray(info.size)
                output.get(chunk)
                pcmBytes.write(chunk)
                decoder.releaseOutputBuffer(outIndex, false)
                if (info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0) {
                    sawOutputEOS = true
                }
            }
        }

        decoder.stop()
        decoder.release()
        extractor.release()
        pfd?.close()

        val raw = pcmBytes.toByteArray()
        val shorts = ByteBuffer.wrap(raw).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
        val totalShorts = shorts.remaining()
        val frames = totalShorts / channels
        if (frames == 0) throw IllegalArgumentException("decoded audio is empty")

        // Downmix to mono (average channels) and resample to 16 kHz with
        // linear interpolation. MediaCodec hands us 16-bit little-endian PCM.
        val ratio = sampleRate.toDouble() / 16000.0
        val outFrames = (frames / ratio).toInt().coerceAtLeast(1)
        val out = ByteBuffer.allocate(outFrames * 4).order(ByteOrder.LITTLE_ENDIAN)

        var srcCursor = 0.0
        for (i in 0 until outFrames) {
            val srcIndex = srcCursor.toInt()
            val frac = (srcCursor - srcIndex).toFloat()

            fun frameValue(frameIndex: Int): Float {
                if (frameIndex >= frames) return 0f
                var acc = 0.0
                val base = frameIndex * channels
                for (c in 0 until channels) {
                    acc += shorts.get(base + c).toFloat() / 32768.0f
                }
                return (acc / channels).toFloat()
            }

            val a = frameValue(srcIndex)
            val b = frameValue(if (srcIndex + 1 < frames) srcIndex + 1 else srcIndex)
            out.putFloat(a + (b - a) * frac)
            srcCursor += ratio
        }

        return out.array()
    }
}
