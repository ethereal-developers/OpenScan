package com.ethereal.openscan;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterActivity {
    private OcrChannel ocrChannel;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        ocrChannel = new OcrChannel(flutterEngine.getDartExecutor().getBinaryMessenger());
    }

    @Override
    public void onDestroy() {
        if (ocrChannel != null) {
            ocrChannel.dispose();
            ocrChannel = null;
        }
        super.onDestroy();
    }
}
