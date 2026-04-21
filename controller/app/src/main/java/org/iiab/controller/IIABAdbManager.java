package org.iiab.controller;

import android.content.Context;
import android.os.Build;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyProperties;
import android.util.Log;

import androidx.annotation.NonNull;

import java.math.BigInteger;
import java.security.KeyPairGenerator;
import java.security.KeyStore;
import java.security.PrivateKey;
import java.security.cert.Certificate;

import javax.security.auth.x500.X500Principal;

import io.github.muntashirakon.adb.AbsAdbConnectionManager;

public class IIABAdbManager extends AbsAdbConnectionManager {

    private static final String TAG = "IIABAdbManager";
    private static final String KEY_ALIAS = "iiab_adb_key_v3";

    // --- SINGLETON PATTERN ---
    private static IIABAdbManager instance;

    private PrivateKey privateKey;
    private Certificate certificate;
    private final String deviceName;

    // Private constructor for singleton
    private IIABAdbManager(Context context) {
        this.deviceName = "IIAB-Controller (" + Build.MODEL + ")";

        try {
            KeyStore keyStore = KeyStore.getInstance("AndroidKeyStore");
            keyStore.load(null);

            if (!keyStore.containsAlias(KEY_ALIAS)) {
                Log.i(TAG, "Generating new RSA V3 key pair in AndroidKeyStore...");
                KeyPairGenerator kpg = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_RSA, "AndroidKeyStore");

                KeyGenParameterSpec spec = new KeyGenParameterSpec.Builder(
                        KEY_ALIAS,
                        KeyProperties.PURPOSE_SIGN | KeyProperties.PURPOSE_VERIFY |
                                KeyProperties.PURPOSE_ENCRYPT | KeyProperties.PURPOSE_DECRYPT)
                        .setDigests(KeyProperties.DIGEST_NONE, KeyProperties.DIGEST_SHA256, KeyProperties.DIGEST_SHA512)
                        .setSignaturePaddings(KeyProperties.SIGNATURE_PADDING_RSA_PKCS1)
                        .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE, KeyProperties.ENCRYPTION_PADDING_RSA_PKCS1)
                        .setRandomizedEncryptionRequired(false)
                        .setKeySize(2048)
                        .setCertificateSubject(new X500Principal("CN=" + this.deviceName))
                        .setCertificateSerialNumber(BigInteger.ONE)
                        .build();

                kpg.initialize(spec);
                kpg.generateKeyPair();
                Log.i(TAG, "V3 keys generated successfully. AndroidKeyStore tamed.");
            }

            this.privateKey = (PrivateKey) keyStore.getKey(KEY_ALIAS, null);
            this.certificate = keyStore.getCertificate(KEY_ALIAS);

        } catch (Exception e) {
            Log.e(TAG, "Critical error accessing AndroidKeyStore", e);
        }
    }

    // Global access method
    public static synchronized IIABAdbManager getInstance(Context context) {
        if (instance == null) {
            instance = new IIABAdbManager(context.getApplicationContext());
        }
        return instance;
    }

    @NonNull
    @Override
    protected PrivateKey getPrivateKey() {
        if (privateKey == null) throw new RuntimeException("PrivateKey is null.");
        return privateKey;
    }

    @NonNull
    @Override
    protected Certificate getCertificate() {
        if (certificate == null) throw new RuntimeException("Certificate is null.");
        return certificate;
    }

    @NonNull
    @Override
    protected String getDeviceName() {
        return deviceName;
    }

    public void startCpuMonitor(Context context) {
        new Thread(() -> {
            try {
                Log.i(TAG, "Starting persistent CPU Stream in Batch Mode...");
                io.github.muntashirakon.adb.AdbStream stream = this.openStream("shell:top -b -d 1");
                java.io.BufferedReader reader = new java.io.BufferedReader(new java.io.InputStreamReader(stream.openInputStream()));
                String line;

                while ((line = reader.readLine()) != null) {
                    String lowerLine = line.toLowerCase();
                    if (lowerLine.contains("%cpu") || lowerLine.contains("idle")) {
                        android.content.Intent intent = new android.content.Intent("org.iiab.controller.ADB_CPU_UPDATE");
                        // >>> CRITICAL: Prevent Android 14+ from blocking the Broadcast <<<
                        intent.setPackage(context.getPackageName());
                        intent.putExtra("cpu_line", line.trim());
                        context.sendBroadcast(intent);
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "CPU Stream closed due to disconnection.", e);
            }
        }).start();
    }
}