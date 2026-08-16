package com.louvorja.louvorja_piano_mobile

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageInstaller
import android.os.Build
import android.provider.Settings
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
                            Thread { installApk(File(path), result) }.start()
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
    /// sessão do SISTEMA — sem FileProvider, sem URI content://.
    ///
    /// Fluxo correto (bug 0.1.16→0.1.17 não instalava, 2026-08-16):
    /// 1. Sem permissão de fonte desconhecida → abre Settings e devolve
    ///    'needs_permission' (antes: falhava em silêncio).
    /// 2. commit() com STATUS_PENDING_USER_ACTION → o RECEIVER dá
    ///    startActivity no EXTRA_INTENT (diálogo "Instalar?"). Antes o
    ///    receiver não existia no manifest e ignorava esse status — o
    ///    diálogo nunca abria e a sessão morria.
    private fun installApk(file: File, result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    android.net.Uri.parse("package:$packageName")
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            )
            mainHandler().post { result.success("needs_permission") }
            return
        }

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
            mainHandler().post { result.error("WRITE_FAIL", e.message, null) }
            return
        }

        // Intent de commit: receiver REGISTRADO NO MANIFEST recebe o
        // resultado — inclusive PENDING_USER_ACTION, que exige
        // startActivity(EXTRA_INTENT) para o diálogo do sistema abrir.
        val intent = Intent(this, InstallResultReceiver::class.java)
        intent.action = "app.louvorja.INSTALL_RESULT"
        val pi = PendingIntent.getBroadcast(
            this, sessionId, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        session.commit(pi.intentSender)
        session.close()
        mainHandler().post { result.success("delivered") }
    }

    private fun mainHandler() = android.os.Handler(android.os.Looper.getMainLooper())
}

/// Recebe o resultado da sessão PackageInstaller.
///
/// STATUS_PENDING_USER_ACTION: o sistema empacotou o diálogo de
/// confirmação em EXTRA_INTENT — SOMOS nós que devemos iniciá-lo.
/// STATUS_SUCCESS: instalou (a activity será recriada com a nova versão).
/// STATUS_FAILURE*: loga o motivo real (EXTRA_STATUS_MESSAGE).
class InstallResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val status = intent.getIntExtra(
            PackageInstaller.EXTRA_STATUS,
            PackageInstaller.STATUS_FAILURE
        )
        when (status) {
            PackageInstaller.STATUS_PENDING_USER_ACTION -> {
                val dialog = intent.getParcelableExtra<Intent>(Intent.EXTRA_INTENT)
                if (dialog != null) {
                    dialog.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(dialog)
                }
            }
            PackageInstaller.STATUS_SUCCESS ->
                android.util.Log.i("LouvorJaUpdater", "install OK")
            else ->
                android.util.Log.w(
                    "LouvorJaUpdater",
                    "install falhou: " +
                        intent.getStringExtra(PackageInstaller.EXTRA_STATUS_MESSAGE)
                )
        }
    }
}
