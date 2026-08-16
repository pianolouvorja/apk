package com.louvorja.louvorja_piano_mobile

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val channelName = "app.louvorja/updater"
    private var multicastLock: android.net.wifi.WifiManager.MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installApk" -> {
                        val path = call.argument<String>("path")
                        if (path == null) {
                            result.error("NO_PATH", "caminho ausente", null)
                        } else {
                            installApk(File(path))
                            result.success(true)
                        }
                    }
                    // Android filtra multicast Wi-Fi para economizar bateria.
                    // SSDP só funciona de forma confiável com este lock ativo.
                    "acquireMulticastLock" -> {
                        val wifi = applicationContext.getSystemService(
                            android.content.Context.WIFI_SERVICE
                        ) as android.net.wifi.WifiManager
                        multicastLock = wifi.createMulticastLock("louvorja-ssdp")
                            .apply { setReferenceCounted(false); acquire() }
                        result.success(true)
                    }
                    "releaseMulticastLock" -> {
                        multicastLock?.let { if (it.isHeld) it.release() }
                        multicastLock = null
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    /// Instala via PackageInstaller.Session: os bytes entram direto na
    /// sessão do SISTEMA — sem FileProvider, sem URI content://, imune ao
    /// processo do app ser congelado pelo OneUI (bug OpenFilex 2026-08-16:
    /// instalador abria, "Atualizando...", e abortava silenciosamente).
    private fun installApk(file: File) {
        val installer = packageManager.packageInstaller
        val params = PackageInstaller.SessionParams(
            PackageInstaller.SessionParams.MODE_FULL_INSTALL
        )
        val sessionId = installer.createSession(params)
        val session = installer.openSession(sessionId)

        try {
            file.inputStream().use { input ->
                session.openWrite("apk", 0, file.length()).use { out ->
                    input.copyTo(out)
                    session.fsync(out)
                }
            }
        } catch (e: Exception) {
            session.abandon()
            return
        }

        // Intent de commit: o SISTEMA mostra a confirmação e instala.
        // Receiver ouvindo o resultado para limpar a sessão em falha.
        val intent = Intent(this, InstallResultReceiver::class.java)
        intent.action = "app.louvorja.INSTALL_RESULT"
        val pi = PendingIntent.getBroadcast(
            this, sessionId, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        session.commit(pi.intentSender)
        session.close()
    }
}

/// Recebe o resultado da sessão: em falha, abandona resíduo da sessão.
class InstallResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val status = intent.getIntExtra(
            PackageInstaller.EXTRA_STATUS,
            PackageInstaller.STATUS_FAILURE
        )
        if (status == PackageInstaller.STATUS_FAILURE) {
            // Sessão já encerrada pelo sistema; nada a limpar além de log.
            android.util.Log.w(
                "LouvorJaUpdater",
                "install falhou: " +
                    intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
            )
        }
    }
}
