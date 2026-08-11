package com.newchat.nchat;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

// Future import for NTgCalls
// import io.github.pytgcalls.ntgcalls.NTgCalls;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.nchat/tgcalls";
    private Object ntgCallsInstance = null; // Placeholder for NTgCalls instance

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
            .setMethodCallHandler(
                (call, result) -> {
                    if (call.method.equals("initCall")) {
                        try {
                            Integer callIdInt = call.argument("callId");
                            long callId = (callIdInt != null) ? callIdInt.longValue() : 1L;
                            
                            java.util.List<String> endpointsList = call.argument("endpoints");
                            String[] endpoints = new String[0];
                            if (endpointsList != null) {
                                endpoints = endpointsList.toArray(new String[0]);
                            }
                            
                            byte[] encryptionKey = call.argument("encryptionKey");
                            if (encryptionKey == null) encryptionKey = new byte[0];

                            // Call the native C++ bridge!
                            VoIPController.nativeInit(getApplicationContext());
                            String response = VoIPController.nativeConnectP2P(callId, endpoints, encryptionKey);
                            
                            result.success(response);
                        } catch (Throwable e) {
                            result.success("ERROR_NATIVE: " + e.toString());
                        }
                    } else {
                        result.notImplemented();
                    }
                }
            );
    }
}

