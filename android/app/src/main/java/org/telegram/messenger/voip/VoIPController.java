package org.telegram.messenger.voip;

public class VoIPController {
    public static native void nativeInit();
    public static native long nativeCreate();
    public static native void nativeStart(long instance);
    public static native void nativeConnect(long instance);
    public static native void nativeSetProxy(long instance, String address, int port, String username, String password);
    public static native void nativeSetEncryptionKey(long instance, byte[] key, boolean isOutgoing);
    
    // Callbacks from C++
    public void onStateChanged(int state) {
        // C++ will call this method when state changes
    }
}
