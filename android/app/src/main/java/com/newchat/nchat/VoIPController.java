package com.newchat.nchat;

import android.content.Context;

public class VoIPController {
    
    // Load the custom JNI library built by CMake
    static {
        System.loadLibrary("custom_tgcalls");
    }

    // Native method to initialize the WebRTC context and tgcalls engine
    public static native void nativeInit(Context context);

    // Native method to pass Telegram Relay Endpoints and encryption key directly to the official tgcalls engine
    public static native String nativeConnectP2P(long callId, String[] endpoints, byte[] encryptionKey);

    // Native method to start screen sharing via MediaProjection
    public static native void nativeStartScreenShare(Object mediaProjection);

    // Native method to clean up resources
    public static native void nativeDestroy();
}
